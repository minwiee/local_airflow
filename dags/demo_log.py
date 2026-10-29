"""Hàm ghi dwh_ctrl.log_etl_table dùng chung cho các DAG demo (chỉ chạy local).

Mỗi DAG demo đi đúng vòng đời dòng log cấp DAG như trên SIT và production:
  - task đầu ghi processing (status_flag 0), như master_trigger_dag ghi trước khi trigger;
  - task cuối log_insert_task (trigger_rule all_done) ghi success (1) nếu mọi task khác success, ngược lại failed (3).
mark_fail_running_dag chỉ dừng những DAG đang có dòng processing.
"""
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.state import TaskInstanceState

CONN_ID = "postgres-dwh-ctrl"
DATA_DATE = "{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}"


def write_processing_log(dag_id, data_date, **kwargs):
    sql_query = """
        insert into dwh_ctrl.log_etl_table as t
            (data_date, project_name, job_name, start_time, end_time, status_name, status_flag)
        values (%s::date, 'dwh', %s, current_timestamp, null, 'processing', 0)
        on conflict (data_date, job_name, project_name)
        do update set start_time = excluded.start_time, end_time = null,
                      status_name = excluded.status_name, status_flag = excluded.status_flag
    """
    PostgresHook(postgres_conn_id=CONN_ID).run(sql_query, parameters=(data_date, dag_id))
    print(f"Ghi log processing: job_name={dag_id}, data_date={data_date}")


def write_result_log(dag_id, data_date, dag_run, **kwargs):
    others = [ti for ti in dag_run.get_task_instances() if ti.task_id != 'log_insert_task']
    ok = all(ti.state == TaskInstanceState.SUCCESS for ti in others)
    status_name, status_flag = ('success', 1) if ok else ('failed', 3)
    sql_query = """
        update dwh_ctrl.log_etl_table
           set status_name = %s, status_flag = %s, end_time = current_timestamp
         where data_date = %s::date and project_name = 'dwh' and job_name = %s
    """
    PostgresHook(postgres_conn_id=CONN_ID).run(sql_query, parameters=(status_name, status_flag, data_date, dag_id))
    print(f"Ghi log {status_name}: job_name={dag_id}, data_date={data_date}")
