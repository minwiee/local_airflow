#----------------------------------------------------------------------
# DAG Name      : loan_contract_intf_dag
# Mô tả         : Interface hợp đồng vay L1 (DWH-103): EOD T24 LD + file MA map category +
#                 số dư GL (dwh_ref.tfm_re_crf_sbv__mnp của bal_sheet_detail_intf_dag)
#                 -> dwh_intf.loan_contract_intf. Model và test lấy từ dbt project dbt/dwh_project
#                 của Airflow local, dựng từ cases/03_loan của bộ tài liệu dự án.
# Created by    : ducnm
# Created date  : 2026-10-23
#----------------------------------------------------------------------
# Modified management
# Date        User          Description
# 2026-10-23  ducnm         Tạo DAG theo khuôn DAG interface của dự án (Airflow local)
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

DAG_ID = 'loan_contract_intf_dag'
BUSINESS_DATE = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}'
DBT_VARS = ('{"business_date": "' + BUSINESS_DATE + '", "run_id": "{{ dag.dag_id }}_{{ run_id }}", '
            '"tbls_data_date": {{ ti.xcom_pull(key=\'loan_contract_intf_dag_tbls_data_date\', task_ids=\'get_tbls_data_date\') }} }')

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
  description='DWH-103: EOD T24 LD + map category + số dư GL -> dwh_intf.loan_contract_intf',
  tags=["cbd", "loan_contract_intf", "bu_intf", "daily"]
) as dag:

  ########## dbt Config ##########
  project_config = get_project_config()
  profile_config = get_profile_config("postgres-dwh-prd-db")
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
    ti.xcom_push(key='loan_contract_intf_dag_tbls_data_date', value=tbls_data_date)

  get_tbls_data_date_task = PythonOperator(
    task_id="get_tbls_data_date",
    python_callable=push_xcom_tbls_data_date,
    op_kwargs={'dag_id': '{{ dag.dag_id }}', 'logical_date': BUSINESS_DATE},
    trigger_rule='all_done',
  )

  # Chờ hai bảng T24 LD và file MA map category (src_stm = 't24_ld')
  waiting_for_t24_ld = SqlSensor(
    task_id="waiting_for_t24_ld",
    conn_id="postgres-dwh-ctrl",
    sql=SQL_CHECK_EOD_LOG,
    params={"prefix": "_t24_ld"},
    success=_success_criteria,
    fail_on_empty=False,
    poke_interval=30,
    mode="reschedule",
    timeout=P_TIMEOUT,
  )

  # Chờ bal_sheet_detail_intf_dag dựng số dư GL dwh_ref.tfm_re_crf_sbv__mnp (src_stm = 'bal_sheet')
  waiting_for_bal_sheet = SqlSensor(
    task_id="waiting_for_bal_sheet",
    conn_id="postgres-dwh-ctrl",
    sql=SQL_CHECK_EOD_LOG,
    params={"prefix": "_bal_sheet"},
    success=_success_criteria,
    fail_on_empty=False,
    poke_interval=30,
    mode="reschedule",
    timeout=P_TIMEOUT,
  )

  # stg_ar_x_cl_pst_t24_loan__snp: tập hợp đồng vay (tag src_ld_for_loan_contract_intf)
  loan_contract_intf_src_ld = DbtTaskGroup(
    group_id="loan_contract_intf_src_ld",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:src_ld_for_loan_contract_intf"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # loan_contract_intf: model mang cả hai tag loan_contract_intf và intf (staging mang tag stag)
  loan_contract_intf = DbtTaskGroup(
    group_id="loan_contract_intf",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:loan_contract_intf,tag:intf"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # Generic test của loan_contract_intf; cách chọn test giải thích ở branch_intf_dag
  loan_contract_intf_test = DbtTaskGroup(
    group_id="loan_contract_intf_test",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=get_execution_config(test_indirect_selection=TestIndirectSelection.CAUTIOUS),
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:loan_contract_intf+1,resource_type:test"],
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
  start_task >> flow_ctrl >> get_tbls_data_date_task >> [waiting_for_t24_ld, waiting_for_bal_sheet]
  [waiting_for_t24_ld, waiting_for_bal_sheet] >> loan_contract_intf_src_ld >> loan_contract_intf
  waiting_for_t24_ld >> loan_contract_intf
  loan_contract_intf >> loan_contract_intf_test >> log_insert_task >> pipeline_success
  ########## End setup task dependencies ##########
