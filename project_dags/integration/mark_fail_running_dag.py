#---------------------------------------------------------------------------------
# DAG Name      : mark_fail_running_dag (bản cho Airflow local)
# Mô tả         : Đọc log_etl_table lấy các DAG đang processing, mark fail DagRun và task
#                 chưa kết thúc, rồi ghi log failed. Cùng logic với
#                 dags/integration/mark_fail_running_dag.py của kho mã nguồn (Git).
#---------------------------------------------------------------------------------

from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.models import DagRun
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.session import provide_session
from airflow.utils.state import DagRunState, State, TaskInstanceState
from utils.utils import on_failure_callback

LOCAL_TZ = "Asia/Ho_Chi_Minh"

default_args = {
  'owner': 'dwh',
  'retries': 2,
  'retry_delay': timedelta(seconds=30),
}


def get_dag_running(dag, **kwargs):
    """Đọc log_etl_table lấy các DAG đang chạy (status_flag = 0, job_name là dag_id), bỏ qua chính DAG này."""
    sql_query = """
        select job_name, to_char(data_date, 'YYYY-MM-DD') as data_date
        from dwh_ctrl.log_etl_table
        where project_name = 'dwh'
          and status_flag = 0
          and job_name ~ '_dag'
          and job_name <> %s
        order by data_date, job_name
    """
    postgres_hook = PostgresHook(postgres_conn_id='postgres-dwh-ctrl')
    results = postgres_hook.get_records(sql_query, parameters=(dag.dag_id,))
    dag_running = [{"job_name": row[0], "data_date": row[1]} for row in results]
    print(f"debug - có {len(dag_running)} DAG đang chạy: {dag_running}")
    return dag_running


@provide_session
def mark_fail_dag_run(dag_id, data_date, note, session=None):
    """Mark fail DagRun đang chạy (running/queued) của dag_id ứng với data_date và mọi task chưa kết thúc.

    DagRun ứng với data_date là DagRun có logical_date (giờ Asia/Ho_Chi_Minh) thuộc ngày data_date,
    khớp cách các DAG lấy business_date: {{ dag_run.logical_date.astimezone(dag.timezone) | ds }}.
    Task đã kết thúc (success, skipped, failed, upstream_failed) giữ nguyên trạng thái.
    DagRun và từng task bị mark fail được ghi Note (hiện trên tab Grid) để phân biệt với DAG tự lỗi.
    """
    day_start = pendulum.parse(data_date, tz=LOCAL_TZ)
    dag_runs = (
        session.query(DagRun)
        .filter(
            DagRun.dag_id == dag_id,
            DagRun.state.in_([DagRunState.RUNNING, DagRunState.QUEUED]),
            DagRun.execution_date >= day_start,
            DagRun.execution_date < day_start.add(days=1),
        )
        .with_for_update(of=DagRun)
        .all()
    )
    if not dag_runs:
        print(f"Không tìm thấy DagRun đang chạy cho dag_id={dag_id}, data_date={data_date}")
        return

    for dag_run in dag_runs:
        print(f"Mark fail dag_id={dag_id}, run_id={dag_run.run_id}")
        for task_instance in dag_run.get_task_instances(state=State.unfinished, session=session):
            print(f"  {task_instance.task_id} (map_index={task_instance.map_index}): {task_instance.state} -> failed")
            task_instance.set_state(TaskInstanceState.FAILED, session=session)
            task_instance.note = note
        dag_run.note = note
        dag_run.set_state(DagRunState.FAILED)
    session.commit()


def mark_fail_dag(ti, **kwargs):
    note = f"Mark fail bởi mark_fail_running_dag lúc {pendulum.now(LOCAL_TZ):%Y-%m-%d %H:%M:%S} (run {ti.run_id})"
    for row in ti.xcom_pull(task_ids='get_dag_running_task') or []:
        mark_fail_dag_run(row["job_name"], row["data_date"], note)


def insert_log_fail(ti, **kwargs):
    """Insert log failed vào log_etl_table cho các DAG đã mark fail.

    Chỉ ghi đè bản ghi còn processing (status_flag = 0): DAG nào kịp kết thúc và tự ghi log
    trong lúc chạy các bước trước thì giữ nguyên log của DAG đó.
    """
    sql_query = """
        insert into dwh_ctrl.log_etl_table as t
            (data_date, project_name, job_name, start_time, end_time, status_name, status_flag)
        values (%s::date, 'dwh', %s, current_timestamp, current_timestamp, 'failed', 3)
        on conflict (data_date, job_name, project_name)
        do update set
            status_flag = excluded.status_flag,
            status_name = excluded.status_name,
            end_time    = excluded.end_time
        where t.status_flag = 0
    """
    postgres_hook = PostgresHook(postgres_conn_id='postgres-dwh-ctrl')
    connection = postgres_hook.get_conn()
    cursor = connection.cursor()
    try:
        for row in ti.xcom_pull(task_ids='get_dag_running_task') or []:
            cursor.execute(sql_query, (row["data_date"], row["job_name"]))
            if cursor.rowcount:
                print(f"Đã insert log failed: job_name={row['job_name']}, data_date={row['data_date']}")
            else:
                print(f"Bỏ qua job_name={row['job_name']}, data_date={row['data_date']}: log không còn ở trạng thái processing")
        connection.commit()
    except Exception as e:
        connection.rollback()
        raise e
    finally:
        cursor.close()
        connection.close()


with DAG('mark_fail_running_dag',
  start_date = pendulum.datetime(2023, 1, 1, tz=LOCAL_TZ),
  schedule_interval=None,
  default_args = default_args,
  max_active_runs=1,
  on_failure_callback=on_failure_callback,
  catchup=False,
  description='Đọc log_etl_table lấy các DAG đang chạy -> mark fail toàn bộ task và DAG -> insert log failed',
  tags=["log_etl_table", "mark_fail"],
) as dag:

    get_dag_running_task = PythonOperator(
        task_id='get_dag_running_task',
        python_callable=get_dag_running,
    )

    mark_fail_dag_task = PythonOperator(
        task_id='mark_fail_dag_task',
        python_callable=mark_fail_dag,
    )

    insert_log_fail_task = PythonOperator(
        task_id='insert_log_fail_task',
        python_callable=insert_log_fail,
    )

    get_dag_running_task >> mark_fail_dag_task >> insert_log_fail_task
