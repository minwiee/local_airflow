#---------------------------------------------------------------------------------------
# DAG Name      : master_trigger_dag (bản cho Airflow local)
# Mô tả         : 2 phút/lần chọn job có "enable" = 99, có cờ cho business date và chưa có
#                 log 0 hoặc 1, ghi log processing rồi trigger DAG của job đó. Cùng logic với
#                 dags/integration/master_trigger_dag.py của kho mã nguồn (Git).
#---------------------------------------------------------------------------------------

from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import datetime
import pendulum
from airflow.models import DagRun
from airflow.models.dagrun import DagRun
from airflow.utils.state import State
from airflow.utils.session import provide_session
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python_operator import PythonOperator
from airflow.models.xcom_arg import XComArg
from airflow.models import DagRun, TaskInstance
from airflow.utils.state import State
from airflow.utils.session import create_session
from airflow.models import Variable
# Hàm trả về danh sách DAG con kèm thông tin cần truyền
@provide_session
def is_dag_running(dag_id, session=None):
    return session.query(DagRun).filter(
        DagRun.dag_id == dag_id,
        DagRun.state == State.RUNNING
    ).count() > 0

def get_dag_ready(**kwargs):
    child_dags = []
    child_dags_run = []
    var_sesion = Variable.get("dag-process-count")
    try:
        sql_query = '''
            with dag_ready as (
                    select distinct e.job_name,to_char(e.business_date,'YYYY-MM-DD') business_date from (
                        select a.job_name,b.business_date,d.count_process, row_number() over(partition by 1 order by COALESCE(a.priority,0) desc)   rn
                        from
                        dwh_ctrl.cstb_job_run_list a
                        join (select distinct job_name,business_date from dwh_ctrl.cstb_etl_gen_flag) b on a.job_name = b.job_name and b.business_date in ( select max(mth_day_no) from dwh_ctrl.t24_holiday__fu thf where airflow_business_date_flag='Y')
                        left join dwh_ctrl.log_etl_table c on b.job_name = c.job_name and b.business_date = c.data_date and c.status_flag in (0,1)
                        left join (
                        select d.data_date,count(*) as count_process
                        from dwh_ctrl.log_etl_table d
                        where  status_flag = 0 and job_name ~ '_dag'
                        and not exists(
                        select 1 from dwh_ctrl.task_instance ti where dag_id=d.job_name
                        and (state='running' or state ='up_for_reschedule')
                        and "operator" in ('SqlSensor','ExternalTaskSensor')
                        and substring(substring(run_id from '^(?:[^_]+__)([^_]+)') from '[^T]+') = to_char(d.data_date,'YYYY-MM-DD')
                        )
                        group by d.data_date
                        ) d on b.business_date = d.data_date
                         left join
                        (
                            select job_name,data_date from dwh_ctrl.log_etl_table_history
                            where data_date in ( select max(mth_day_no) from dwh_ctrl.t24_holiday__fu thf where airflow_business_date_flag='Y') and status_name = 'failed' and CHECKED is null
                            group by job_name ,data_date
                            having count(*) >= 5
                        ) d_his  ON a.job_name = d_his.job_name
                        where a.job_name ~'_dag'
                        and c.job_name is null and d_his.job_name is null
                        and "enable"= 99
                        ) e
                        where (e.rn <= cast(%s as int)-COALESCE(e.count_process,0))

        )
        , updateed AS (
        INSERT INTO dwh_ctrl.LOG_ETL_TABLE (DATA_DATE, PROJECT_NAME, JOB_NAME, START_TIME, END_TIME, STATUS_NAME, STATUS_FLAG, TOTAL_ROW)
        SELECT business_date::date,'dwh' PROJECT, JOB_NAME, current_timestamp, NULL,'processing', 0, null
        FROM dag_ready
        ON CONFLICT (JOB_NAME, DATA_DATE, project_name)
        DO UPDATE SET status_flag = 0, STATUS_NAME = 'processing', START_TIME = current_timestamp, END_TIME = null, total_row = null
        RETURNING *
        )
        select a.job_name, a.business_date from dag_ready a
        '''
        postgres_hook = PostgresHook(postgres_conn_id='postgres-dwh-ctrl')
        connection = postgres_hook.get_conn()
        cursor = connection.cursor()
        cursor.execute(sql_query,(var_sesion,))
        results = cursor.fetchall()
        connection.commit()
        for row in results:
            master_run_id = 'manual__' + str(row[1]) + 'T00:00:00+07:00'
            trigger_dag_id = row[0]
            business_date = str(row[1])
            master_execution_date = str(pendulum.parse(business_date, tz="Asia/Ho_Chi_Minh"))
            r = {"trigger_dag_id": trigger_dag_id, "conf": {"business_date": business_date,"master_run_id": master_run_id, "master_execution_date": master_execution_date}}
            child_dags.append(r)
    except Exception as e:
        raise Exception("Error: Something happen when execute SELECT sql, please check!")

    for child in child_dags:
      if is_dag_running(child["trigger_dag_id"]):
          with create_session() as session:
            dag_run = session.query(DagRun).filter(
                DagRun.dag_id == child["trigger_dag_id"],
                DagRun.run_id == child["conf"]["master_run_id"]
            ).first()

            if dag_run:
                failed_tasks = session.query(TaskInstance).filter(
                    TaskInstance.dag_id == child["trigger_dag_id"],
                    TaskInstance.run_id == child["conf"]["master_run_id"],
                    TaskInstance.state == State.FAILED
                ).all()

                for ti in failed_tasks:
                    print(f"Clearing failed task: {ti.task_id}")
                    ti.set_state(None, session=session)

                session.commit()
            else:
                print(f"No dag_run found for run_id={child["conf"]["master_run_id"]}")
      else:
          child_dags_run.append(child)
          print(f"debug - dag cần được chạy: {child["trigger_dag_id"]}")
    return child_dags_run
# Hàm callback: khi call/trigger DAG con bị lỗi -> update trạng thái job về 'up_to_retry'
def mark_dag_up_for_retry_callback(context):
    task = context.get("task")
    trigger_dag_id = getattr(task, "trigger_dag_id", None)
    conf = getattr(task, "conf", {}) or {}
    business_date = conf.get("business_date")

    if not trigger_dag_id or not business_date:
        print(f"mark_dag_up_for_retry_callback: thiếu thông tin job (dag_id={trigger_dag_id}, business_date={business_date}), bỏ qua update.")
        return

    update_sql = '''
        UPDATE dwh_ctrl.LOG_ETL_TABLE
        SET STATUS_NAME = 'up_to_retry',
            END_TIME = current_timestamp,
            status_flag = 5
        WHERE JOB_NAME = %s
          AND DATA_DATE = %s::date
          AND PROJECT_NAME = 'dwh'

    '''
    postgres_hook = PostgresHook(postgres_conn_id='postgres-dwh-ctrl')
    connection = postgres_hook.get_conn()
    try:
        cursor = connection.cursor()
        cursor.execute(update_sql, (trigger_dag_id, business_date))
        connection.commit()
        print(f"Đã update job '{trigger_dag_id}' (business_date={business_date}) về 'up_to_retry' do call DAG lỗi.")
    except Exception as e:
        connection.rollback()
        print(f"Lỗi khi update trạng thái up_to_retry cho job '{trigger_dag_id}': {e}")
        raise
    finally:
        connection.close()
# Hàm tạo run_id theo định dạng yêu cầu
def generate_run_id(business_date):
    business_date_dt = pendulum.parse(business_date, tz="Asia/Ho_Chi_Minh")
    # Đặt thời gian về 00:00:00
    run_time = business_date_dt.start_of('day')
    return "manual__" + run_time.strftime('%Y-%m-%dT%H:%M:%S+07:00')
# Cấu hình DAG
with DAG('master_trigger_dag',
    start_date=datetime(2024, 1, 1),
    schedule_interval="*/2 * * * *",
    catchup=False,
    tags=["master dag"],

) as dag:

    get_dags_task = PythonOperator(
        task_id='get_dags_ready',
        python_callable=get_dag_ready,
        provide_context=True,
    )

    # Dùng dynamic task mapping để gọi nhiều DAG con
    trigger_dags = TriggerDagRunOperator.partial(
        task_id="master_trigger_dag",
        trigger_run_id="{{ task.conf['master_run_id'] }}",
        reset_dag_run=True,
        map_index_template="{{ task.trigger_dag_id }}",
        execution_date="{{ task.conf['master_execution_date'] }}",
        on_failure_callback=mark_dag_up_for_retry_callback
    ).expand_kwargs(
         XComArg(get_dags_task)
    )

    get_dags_task >> trigger_dags
