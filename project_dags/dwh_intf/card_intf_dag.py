#----------------------------------------------------------------------
# DAG Name      : card_intf_dag
# Mô tả         : Interface thẻ L1 (DWH-104): EOD Way4 -> dwh_intf.card_intf.
#                 Model và test lấy từ dbt project dbt/dwh_project của Airflow local,
#                 dựng từ cases/04_card của bộ tài liệu dự án.
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

DAG_ID = 'card_intf_dag'
BUSINESS_DATE = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}'

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
  description='DWH-104: EOD Way4 -> dwh_intf.card_intf',
  tags=["cbd", "card_intf", "bu_intf", "daily"]
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
    ti.xcom_push(key='card_intf_dag_tbls_data_date', value=tbls_data_date)

  get_tbls_data_date_task = PythonOperator(
    task_id="get_tbls_data_date",
    python_callable=push_xcom_tbls_data_date,
    op_kwargs={'dag_id': '{{ dag.dag_id }}', 'logical_date': BUSINESS_DATE},
    trigger_rule='all_done',
  )

  # Chờ 4 bảng Way4 (src_stm = 'way4')
  waiting_for_way4 = SqlSensor(
    task_id="waiting_for_way4",
    conn_id="postgres-dwh-ctrl",
    sql=SQL_CHECK_EOD_LOG,
    params={"prefix": "_way4"},
    success=_success_criteria,
    fail_on_empty=False,
    poke_interval=30,
    mode="reschedule",
    timeout=P_TIMEOUT,
  )

  # stg_card_intf_way4__snp, card_intf (tag card_intf)
  card_intf_src_way4 = DbtTaskGroup(
    group_id="card_intf_src_way4",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:card_intf"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={
      "vars": '{"business_date": "' + BUSINESS_DATE + '", "run_id": "{{ dag.dag_id }}_{{ run_id }}", '
              '"tbls_data_date": {{ ti.xcom_pull(key=\'card_intf_dag_tbls_data_date\', task_ids=\'get_tbls_data_date\') }} }'
    }
  )

  # Generic test của card_intf; cách chọn test giải thích ở branch_intf_dag
  card_intf_test = DbtTaskGroup(
    group_id="card_intf_test",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=get_execution_config(test_indirect_selection=TestIndirectSelection.CAUTIOUS),
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:card_intf+1,resource_type:test"],
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
  start_task >> flow_ctrl >> get_tbls_data_date_task >> waiting_for_way4 >> card_intf_src_way4 >> card_intf_test
  card_intf_test >> log_insert_task >> pipeline_success
  ########## End setup task dependencies ##########
