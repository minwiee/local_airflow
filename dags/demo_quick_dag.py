#---------------------------------------------------------------------------------
# DAG demo (chỉ chạy local): chạy xong trong khoảng 1 phút và ghi log success.
#   start_log_task -> extract_task -> load_task -> log_insert_task
# Dùng để kiểm tra mark_fail_running_dag không đụng tới DAG đã success.
#---------------------------------------------------------------------------------
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule

from utils.utils import P_MAX_ACTIVE_RUN, P_RETRIES
from demo.demo_log import DATA_DATE, write_processing_log, write_result_log

DAG_ID = 'demo_quick_dag'


with DAG(DAG_ID,
    start_date=pendulum.datetime(2023, 1, 1, tz="Asia/Ho_Chi_Minh"),
    schedule_interval=None,
    max_active_runs=P_MAX_ACTIVE_RUN,
    catchup=False,
    default_args={'owner': 'demo', 'retry_delay': timedelta(seconds=30), 'retries': P_RETRIES},
    description='Demo: DAG chạy nhanh, kết thúc success',
    tags=["demo"],
) as dag:

    start_log_task = PythonOperator(
        task_id='start_log_task',
        python_callable=write_processing_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
    )

    extract_task = BashOperator(task_id='extract_task', bash_command='echo "Đọc nguồn"; sleep 10')
    load_task = BashOperator(task_id='load_task', bash_command='echo "Ghi bảng đích"; sleep 10')

    log_insert_task = PythonOperator(
        task_id='log_insert_task',
        python_callable=write_result_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
        trigger_rule=TriggerRule.ALL_DONE,
        retries=10,
        retry_delay=timedelta(seconds=10),
    )

    start_log_task >> extract_task >> load_task >> log_insert_task
