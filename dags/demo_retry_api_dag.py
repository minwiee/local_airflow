#---------------------------------------------------------------------------------
# DAG demo (chỉ chạy local): gọi API nguồn luôn lỗi, task tự retry theo cấu hình của DAG gốc
# (P_RETRIES = 6 lần, mỗi lần cách 30 giây), nên khoảng 3 phút sau khi trigger task mới failed hẳn.
#   start_log_task -> call_source_api_task (up_for_retry) -> log_insert_task
# Dùng để thử mark_fail_running_dag với task đang chờ retry: task phải chuyển failed
# và không retry thêm lần nào.
#---------------------------------------------------------------------------------
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule

from utils.utils import P_MAX_ACTIVE_RUN, P_RETRIES
from demo.demo_log import DATA_DATE, write_processing_log, write_result_log

DAG_ID = 'demo_retry_api_dag'


def call_source_api(ti, **kwargs):
    print(f"Gọi API báo nguồn sẵn sàng, lần thử {ti.try_number}")
    raise ConnectionError("API nguồn chưa phản hồi")


with DAG(DAG_ID,
    start_date=pendulum.datetime(2023, 1, 1, tz="Asia/Ho_Chi_Minh"),
    schedule_interval=None,
    max_active_runs=P_MAX_ACTIVE_RUN,
    catchup=False,
    default_args={'owner': 'demo', 'retry_delay': timedelta(seconds=30), 'retries': P_RETRIES},
    description='Demo: task lỗi và tự retry',
    tags=["demo"],
) as dag:

    start_log_task = PythonOperator(
        task_id='start_log_task',
        python_callable=write_processing_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
    )

    call_source_api_task = PythonOperator(
        task_id='call_source_api_task',
        python_callable=call_source_api,
    )

    log_insert_task = PythonOperator(
        task_id='log_insert_task',
        python_callable=write_result_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
        trigger_rule=TriggerRule.ALL_DONE,
        retries=10,
        retry_delay=timedelta(seconds=10),
    )

    start_log_task >> call_source_api_task >> log_insert_task
