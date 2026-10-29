#---------------------------------------------------------------------------------
# DAG demo (chỉ chạy local): xử lý thẻ theo 8 phân vùng bằng dynamic task mapping.
#   start_log_task -> list_partitions_task -> process_partition_task[0..7] -> log_insert_task
# Mỗi lần chỉ chạy 3 phân vùng, mỗi phân vùng 5 phút: khi bật mark_fail_running_dag sẽ có
# map_index đang running và map_index chưa chạy, cả hai đều phải chuyển failed.
#---------------------------------------------------------------------------------
import time
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.decorators import task
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule

from utils.utils import P_MAX_ACTIVE_RUN, P_RETRIES
from demo.demo_log import DATA_DATE, write_processing_log, write_result_log

DAG_ID = 'demo_card_intf_dag'


with DAG(DAG_ID,
    start_date=pendulum.datetime(2023, 1, 1, tz="Asia/Ho_Chi_Minh"),
    schedule_interval=None,
    max_active_runs=P_MAX_ACTIVE_RUN,
    catchup=False,
    default_args={'owner': 'demo', 'retry_delay': timedelta(seconds=30), 'retries': P_RETRIES},
    description='Demo: dynamic task mapping 8 phân vùng thẻ',
    tags=["demo"],
) as dag:

    start_log_task = PythonOperator(
        task_id='start_log_task',
        python_callable=write_processing_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
    )

    @task(task_id='list_partitions_task')
    def list_partitions():
        partitions = [f"BIN_GROUP_{i:02d}" for i in range(1, 9)]
        print(f"Chia thẻ thành {len(partitions)} phân vùng")
        return partitions

    @task(task_id='process_partition_task', max_active_tis_per_dagrun=3)
    def process_partition(partition):
        print(f"Tính trạng thái thẻ cho {partition}")
        time.sleep(300)
        return partition

    log_insert_task = PythonOperator(
        task_id='log_insert_task',
        python_callable=write_result_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
        trigger_rule=TriggerRule.ALL_DONE,
        retries=10,
        retry_delay=timedelta(seconds=10),
    )

    partitions = list_partitions()
    start_log_task >> partitions
    process_partition.expand(partition=partitions) >> log_insert_task
