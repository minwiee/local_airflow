#----------------------------------------------------------------------
# DAG Name      : bi_lend_repay_info_intf__fa_dag
# Mô tả         : Interface layer 2 thông tin trả nợ vay của khối BI (DWH-103):
#                 dwh_intf.repay_acty_intf + dwh_intf.loan_contract_intf -> bi_intf.bi_lend_repay_info_intf__fa.
#                 Chạy sau khi loan_contract_intf_dag và repay_acty_intf_dag ghi log success cho cùng
#                 business date (repay_acty_intf_dag ngoài phạm vi, log success nạp sẵn).
# Created by    : ducnm
# Created date  : 2026-10-23
#----------------------------------------------------------------------
# Modified management
# Date        User          Description
# 2026-10-23  ducnm         Tạo DAG theo khuôn DAG layer 2 của dự án (Airflow local)
#----------------------------------------------------------------------
from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator, ShortCircuitOperator
from airflow.sensors.sql import SqlSensor
from airflow.utils.task_group import TaskGroup
from cosmos import DbtTaskGroup, LoadMode, RenderConfig
from cosmos.constants import TestBehavior, TestIndirectSelection

from utils.check_data_holiday import get_tables_data_date, is_holiday
from utils.insert_log_dag import log_insert_dag
from utils.utils import (P_MAX_ACTIVE_RUN, P_RETRIES, P_TIMEOUT, SQL_CHECK_EOD_LOG, _success_criteria,
                         get_execution_config, get_profile_config, get_project_config, on_failure_callback)

DAG_ID = 'bi_lend_repay_info_intf__fa_dag'
BUSINESS_DATE = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}'
DBT_VARS = ('{"business_date": "' + BUSINESS_DATE + '", "run_id": "{{ dag.dag_id }}_{{ run_id }}", '
            '"tbls_data_date": {{ ti.xcom_pull(key=\'bi_lend_repay_info_intf__fa_dag_tbls_data_date\', task_ids=\'get_tbls_data_date\') }} }')

default_args = {
  'owner': 'ducnm',
  'retry_delay': timedelta(seconds=30),
  'retries': P_RETRIES
}

with DAG(DAG_ID,
  start_date=pendulum.datetime(2026, 1, 1, tz="Asia/Ho_Chi_Minh"),
  schedule_interval=None,
  default_args=default_args,
  concurrency=10,
  max_active_runs=P_MAX_ACTIVE_RUN,
  on_failure_callback=on_failure_callback,
  catchup=False,
  description='DWH-103 layer 2: repay_acty_intf + loan_contract_intf -> bi_intf.bi_lend_repay_info_intf__fa',
  tags=["bi", "bi_lend_repay_info_intf__fa", "bu_intf_layer_2", "daily"]
) as dag:

  ########## dbt Config ##########
  project_config = get_project_config()
  profile_config = get_profile_config("postgres-bi-prd-db")
  execution_config = get_execution_config()
  ########## End dbt Config ##########

  start_task = EmptyOperator(
    task_id='start_task'
  )

  with TaskGroup(group_id='flow_ctrl') as flow_ctrl:
    check_holiday = ShortCircuitOperator(
      task_id='check_holiday',
      python_callable=is_holiday,
      op_kwargs={"data_date": BUSINESS_DATE}
    )

  def push_xcom_tbls_data_date(ti, dag_id, logical_date):
    tbls_data_date = get_tables_data_date(dag_id, logical_date)
    ti.xcom_push(key='bi_lend_repay_info_intf__fa_dag_tbls_data_date', value=tbls_data_date)

  get_tbls_data_date_task = PythonOperator(
    task_id="get_tbls_data_date",
    python_callable=push_xcom_tbls_data_date,
    op_kwargs={'dag_id': '{{ dag.dag_id }}', 'logical_date': BUSINESS_DATE},
    trigger_rule='all_done',
  )

  # Chờ loan_contract_intf_dag và repay_acty_intf_dag success (src_stm = 'all', prefix "_")
  waiting_for_all = SqlSensor(
    task_id="waiting_for_all",
    conn_id="postgres-dwh-ctrl",
    sql=SQL_CHECK_EOD_LOG,
    params={"prefix": "_"},
    success=_success_criteria,
    fail_on_empty=False,
    poke_interval=30,
    mode="reschedule",
    timeout=P_TIMEOUT,
  )

  bi_lend_repay_info_intf__fa = DbtTaskGroup(
    group_id="bi_lend_repay_info_intf__fa",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:bi_lend_repay_info_intf__fa"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # Generic test của bi_lend_repay_info_intf__fa; cách chọn test giải thích ở branch_intf_dag
  bi_lend_repay_info_intf__fa_test = DbtTaskGroup(
    group_id="bi_lend_repay_info_intf__fa_test",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=get_execution_config(test_indirect_selection=TestIndirectSelection.CAUTIOUS),
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:bi_lend_repay_info_intf__fa+1,resource_type:test"],
      test_behavior=TestBehavior.AFTER_ALL,
    ),
    operator_args={
      "vars": '{"business_date": "' + BUSINESS_DATE + '", "run_id": "{{ dag.dag_id }}_{{ run_id }}"}'
    }
  )

  log_insert_task = PythonOperator(
    task_id="log_insert_task",
    python_callable=log_insert_dag,
    op_args=['{{ dag.dag_id }}', BUSINESS_DATE],
    trigger_rule='all_done',
    retries=10,
    retry_delay=timedelta(seconds=10),
  )

  pipeline_success = EmptyOperator(
    task_id='pipeline_success'
  )

  ########## Start setup task dependencies ##########
  start_task >> flow_ctrl >> get_tbls_data_date_task >> waiting_for_all >> bi_lend_repay_info_intf__fa
  bi_lend_repay_info_intf__fa >> bi_lend_repay_info_intf__fa_test >> log_insert_task >> pipeline_success
  ########## End setup task dependencies ##########
