#----------------------------------------------------------------------
# Module        : insert_log_dag (bản cho Airflow local)
# Mô tả         : Hàm log_insert_dag của task log_insert_task cuối DAG interface, theo
#                 dags/utils/insert_log_dag.py và sql/INSERT_LOG_DAG.sql của kho mã nguồn (Git):
#                 - bỏ qua SqlSensor, EmptyOperator (DummyOperator) và task chưa chạy;
#                 - có task failed hoặc upstream_failed thì ghi failed (3), ngược lại success (1);
#                 - start_time là giờ bắt đầu sớm nhất của các task đã chạy, end_time là giờ ghi log;
#                 - ghi vào dwh_ctrl.log_etl_table (project_name = 'dwh') qua connection postgres-dwh-ctrl;
#                 - ghi failed xong thì raise lỗi, nên log_insert_task failed (sau 10 lần thử lại)
#                   và pipeline_success ở upstream_failed.
#                 Khác bản production: đọc trạng thái task từ DagRun đang chạy thay vì DagBag.
#----------------------------------------------------------------------
import pendulum
from airflow.providers.postgres.hooks.postgres import PostgresHook

CTRL_CONN_ID = "postgres-dwh-ctrl"
LOCAL_TZ = "Asia/Ho_Chi_Minh"
SKIP_OPERATORS = ("SqlSensor", "EmptyOperator", "DummyOperator")

SQL_INSERT_LOG_DAG = """
    insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, start_time, end_time, status_name, status_flag)
    values (%s, 'dwh', %s, %s, %s, %s, %s)
    on conflict (data_date, job_name, project_name)
    do update set
        status_flag = excluded.status_flag,
        status_name = excluded.status_name,
        start_time  = excluded.start_time,
        end_time    = excluded.end_time
"""


def _to_local(dt):
    return pendulum.instance(dt).in_timezone(LOCAL_TZ).naive() if dt else None


def log_insert_dag(dag_id, business_date, **kwargs):
    dag_run = kwargs["dag_run"]
    current_task_id = kwargs["ti"].task_id
    end_time = pendulum.now(LOCAL_TZ).naive()
    min_start_date = None
    status, status_flag = "success", 1
    failed_tasks = []
    for ti in dag_run.get_task_instances():
        if ti.task_id == current_task_id or ti.operator in SKIP_OPERATORS:
            continue
        if ti.start_date is not None:
            start = _to_local(ti.start_date)
            if min_start_date is None or start < min_start_date:
                min_start_date = start
        if ti.state in ("failed", "upstream_failed"):
            status, status_flag = "failed", 3
            failed_tasks.append(f"{ti.task_id}: {ti.state}")

    PostgresHook(postgres_conn_id=CTRL_CONN_ID).run(
        SQL_INSERT_LOG_DAG,
        parameters=(business_date, dag_id, min_start_date, end_time, status, status_flag),
    )
    print(f"Ghi log {status} ({status_flag}): job_name={dag_id}, data_date={business_date}, "
          f"start_time={min_start_date}, end_time={end_time}")
    if status == "failed":
        raise ValueError(f"job failed: {', '.join(failed_tasks)}")
