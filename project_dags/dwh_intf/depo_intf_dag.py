#----------------------------------------------------------------------
# DAG Name      : depo_intf_dag
# Mô tả         : Interface tiền gửi L1 (DWH-102): EOD T24 LD + file MA map category
#                 -> dwh_intf.depo_intf. Model và test lấy từ dbt project dbt/dwh_project của
#                 Airflow local, dựng từ cases/02_deposit của bộ tài liệu dự án.
#                 Biến pre_last_wk_day (ngày làm việc trước, dùng cho nhánh tất toán) do task
#                 get_tbls_data_date tính từ lịch dwh_ctrl.t24_holiday__fu và đẩy qua XCom.
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

from utils.check_data_holiday import get_pre_last_working_day, get_tables_data_date, is_holiday
from utils.insert_log_dag import log_insert_dag
from utils.utils import (P_MAX_ACTIVE_RUN, P_RETRIES, P_TIMEOUT, SQL_CHECK_EOD_LOG, _success_criteria,
                         get_execution_config, get_profile_config, get_project_config, on_failure_callback)

DAG_ID = 'depo_intf_dag'
BUSINESS_DATE = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}'
DBT_VARS = ('{"business_date": "' + BUSINESS_DATE + '", "run_id": "{{ dag.dag_id }}_{{ run_id }}", '
            '"pre_last_wk_day": "{{ ti.xcom_pull(key=\'depo_intf_dag_pre_last_wk_day\', task_ids=\'get_tbls_data_date\') }}", '
            '"tbls_data_date": {{ ti.xcom_pull(key=\'depo_intf_dag_tbls_data_date\', task_ids=\'get_tbls_data_date\') }} }')

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
  description='DWH-102: EOD T24 LD + file MA map category -> dwh_intf.depo_intf',
  tags=["cbd", "depo_intf", "bu_intf", "daily"]
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
    ti.xcom_push(key='depo_intf_dag_tbls_data_date', value=tbls_data_date)
    ti.xcom_push(key='depo_intf_dag_pre_last_wk_day', value=get_pre_last_working_day(logical_date))

  get_tbls_data_date_task = PythonOperator(
    task_id="get_tbls_data_date",
    python_callable=push_xcom_tbls_data_date,
    op_kwargs={'dag_id': '{{ dag.dag_id }}', 'logical_date': BUSINESS_DATE},
    trigger_rule='all_done',
  )

  # Chờ hai bảng T24 LD (src_stm = 't24_ld')
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

  # Chờ bảng LD và file MA map category (src_stm = 'ar_x_cl_pst')
  waiting_for_ar_x_cl_pst = SqlSensor(
    task_id="waiting_for_ar_x_cl_pst",
    conn_id="postgres-dwh-ctrl",
    sql=SQL_CHECK_EOD_LOG,
    params={"prefix": "_ar_x_cl_pst"},
    success=_success_criteria,
    fail_on_empty=False,
    poke_interval=30,
    mode="reschedule",
    timeout=P_TIMEOUT,
  )

  # stg_ar_depo_t24_ld_prfl__snp: thuộc tính hợp đồng LD
  transform_depo_intf_t24_ld = DbtTaskGroup(
    group_id="transform_depo_intf_t24_ld",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:transform_depo_intf_t24_ld"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # stg_ar_x_cl_pst_t24_depo_t24_ld__snp: hợp đồng LD nào là tiền gửi
  transform_depo_intf_ar_x_cl_pst = DbtTaskGroup(
    group_id="transform_depo_intf_ar_x_cl_pst",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:transform_depo_intf_ar_x_cl_pst"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # depo_intf: ghép hai staging (tag depo_intf_all)
  transform_depo_intf = DbtTaskGroup(
    group_id="transform_depo_intf",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:depo_intf_all"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # Generic test của depo_intf (tag depo_intf_test); cách chọn test giải thích ở branch_intf_dag
  depo_intf_test = DbtTaskGroup(
    group_id="depo_intf_test",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=get_execution_config(test_indirect_selection=TestIndirectSelection.CAUTIOUS),
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:depo_intf_test+1,resource_type:test"],
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
  start_task >> flow_ctrl >> get_tbls_data_date_task >> [waiting_for_t24_ld, waiting_for_ar_x_cl_pst]
  waiting_for_t24_ld >> transform_depo_intf_t24_ld >> transform_depo_intf
  waiting_for_ar_x_cl_pst >> transform_depo_intf_ar_x_cl_pst >> transform_depo_intf
  transform_depo_intf >> depo_intf_test >> log_insert_task >> pipeline_success
  ########## End setup task dependencies ##########
