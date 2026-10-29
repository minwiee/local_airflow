#---------------------------------------------------------------------------------
# DAG demo (chỉ chạy local): dựng interface chi nhánh qua 2 task group nguồn, ghép, rồi test.
#   start_log_task -> [src_t24, src_way4] -> merge_branch_task -> test -> log_insert_task
# Mỗi task chỉ in ra hành động và chờ vài phút, tổng khoảng 20 phút,
# đủ lâu để bật mark_fail_running_dag khi DAG đang chạy giữa chừng.
#---------------------------------------------------------------------------------
import time
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
from airflow.utils.trigger_rule import TriggerRule

from utils.utils import P_MAX_ACTIVE_RUN, P_RETRIES
from demo.demo_log import DATA_DATE, write_processing_log, write_result_log

DAG_ID = 'demo_branch_intf_dag'


def read_company_details(**kwargs):
    rows = [{"branch_code": f"VN00{i:05d}", "m": m} for i in range(1, 51) for m in (1, 2)]
    print(f"Đọc {len(rows)} dòng tên của 50 đơn vị")
    time.sleep(240)
    return len(rows)


def merge_branch(ti, **kwargs):
    n_rows = ti.xcom_pull(task_ids='src_t24.read_company_details_task') or 0
    print(f"Ghép {n_rows} dòng tên thành {n_rows // 2} chi nhánh, thêm dòng mặc định ZZZZZZZZZ")
    time.sleep(300)


def run_test(test_name, **kwargs):
    print(f"Chạy test {test_name} cho branch_intf")
    time.sleep(120)
    print(f"{test_name}: pass")


with DAG(DAG_ID,
    start_date=pendulum.datetime(2023, 1, 1, tz="Asia/Ho_Chi_Minh"),
    schedule_interval=None,
    max_active_runs=P_MAX_ACTIVE_RUN,
    catchup=False,
    default_args={'owner': 'demo', 'retry_delay': timedelta(seconds=30), 'retries': P_RETRIES},
    description='Demo: task group nguồn T24, Way4, ghép và test',
    tags=["demo"],
) as dag:

    start_log_task = PythonOperator(
        task_id='start_log_task',
        python_callable=write_processing_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
    )

    with TaskGroup('src_t24') as src_t24:
        read_company_task = BashOperator(
            task_id='read_company_task',
            bash_command='echo "Đọc bảng COMPANY ngày {{ ds }}"; for i in $(seq 1 18); do echo "batch $i/18"; sleep 10; done',
        )
        read_company_details_task = PythonOperator(
            task_id='read_company_details_task',
            python_callable=read_company_details,
        )
        read_company_task >> read_company_details_task

    with TaskGroup('src_way4') as src_way4:
        read_way4_branch_task = BashOperator(
            task_id='read_way4_branch_task',
            bash_command='echo "Đọc chi nhánh Way4 ngày {{ ds }}"; sleep 360; echo "Xong"',
        )

    merge_branch_task = PythonOperator(
        task_id='merge_branch_task',
        python_callable=merge_branch,
    )

    with TaskGroup('test') as test:
        for test_name in ['count_test', 'duplicate_test', 'detail_test']:
            PythonOperator(
                task_id=f'{test_name}_task',
                python_callable=run_test,
                op_kwargs={'test_name': test_name},
            )

    log_insert_task = PythonOperator(
        task_id='log_insert_task',
        python_callable=write_result_log,
        op_kwargs={'dag_id': DAG_ID, 'data_date': DATA_DATE},
        trigger_rule=TriggerRule.ALL_DONE,
        retries=10,
        retry_delay=timedelta(seconds=10),
    )

    start_log_task >> [src_t24, src_way4] >> merge_branch_task >> test >> log_insert_task
