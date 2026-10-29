#---------------------------------------------------------------------------------
# DAG demo (chỉ chạy local): chờ nguồn bằng SqlSensor rồi chạy dbt run, dbt test theo task group.
#   start_log_task -> waiting_for_t24_ld (SqlSensor, mode reschedule) -> dbt_run -> dbt_test -> log_insert_task
# Sensor chờ dòng success của nguồn 'demo_t24_ld' (project eod) trong log_etl_table, tối đa P_TIMEOUT (24 giờ) như DAG gốc.
# Không nạp dòng đó thì DAG nằm chờ ở sensor (trạng thái up_for_reschedule / running),
# dùng để thử mark_fail_running_dag với sensor. Nạp dòng đó thì DAG chạy tiếp như bình thường:
#   insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, status_name, status_flag)
#   values (current_date, 'eod', 'demo_t24_ld', 'success', 1);
#---------------------------------------------------------------------------------
import time
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.sensors.sql import SqlSensor
from airflow.utils.task_group import TaskGroup
from airflow.utils.trigger_rule import TriggerRule

from utils.utils import P_MAX_ACTIVE_RUN, P_RETRIES, P_TIMEOUT
from demo.demo_log import CONN_ID, DATA_DATE, write_processing_log, write_result_log

DAG_ID = 'demo_depo_intf_dag'


def build_depo_intf(**kwargs):
    print("Ghép nhánh hợp đồng còn hiệu lực và nhánh tất toán trong ngày")
    time.sleep(240)


with DAG(DAG_ID,
    start_date=pendulum.datetime(2023, 1, 1, tz="Asia/Ho_Chi_Minh"),
    schedule_interval=None,
    max_active_runs=P_MAX_ACTIVE_RUN,
    catchup=False,
    default_args={'owner': 'demo', 'retry_delay': timedelta(seconds=30), 'retries': P_RETRIES},
    description='Demo: SqlSensor chờ nguồn, task group dbt run và dbt test',
    tags=["demo"],
) as dag:

    start_log_task = PythonOperator(
        task_id='start_log_task',
        python_callable=write_processing_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
    )

    waiting_for_t24_ld = SqlSensor(
        task_id='waiting_for_t24_ld',
        conn_id=CONN_ID,
        sql=f"""
            select count(*) from dwh_ctrl.log_etl_table
            where data_date = '{DATA_DATE}'::date and project_name = 'eod'
              and job_name = 'demo_t24_ld' and status_flag = 1
        """,
        mode='reschedule',
        poke_interval=30,
        timeout=P_TIMEOUT,
    )

    with TaskGroup('dbt_run') as dbt_run:
        stg_depo_task = BashOperator(
            task_id='stg_ar_x_cl_pst_t24_depo_task',
            bash_command='echo "dbt run staging tiền gửi ngày {{ ds }}"; sleep 180; echo "Xong"',
        )
        depo_intf_task = PythonOperator(
            task_id='depo_intf_task',
            python_callable=build_depo_intf,
        )
        stg_depo_task >> depo_intf_task

    with TaskGroup('dbt_test') as dbt_test:
        for test_name in ['unique_value', 'count_gte_zero']:
            BashOperator(
                task_id=f'{test_name}_task',
                bash_command=f'echo "dbt test {test_name}"; sleep 60; echo pass',
            )

    log_insert_task = PythonOperator(
        task_id='log_insert_task',
        python_callable=write_result_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
        trigger_rule=TriggerRule.ALL_DONE,
        retries=10,
        retry_delay=timedelta(seconds=10),
    )

    start_log_task >> waiting_for_t24_ld >> dbt_run >> dbt_test >> log_insert_task
