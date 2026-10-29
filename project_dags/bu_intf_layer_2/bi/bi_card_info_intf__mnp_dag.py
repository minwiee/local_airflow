#----------------------------------------------------------------------
# DAG Name      : bi_card_info_intf__mnp_dag
# Mô tả         : Interface layer 2 thẻ của khối BI (DWH-104): dwh_intf.card_intf + dwh_intf.prd_intf
#                 -> bi_stag.stg_bi_card__snp, bi_stag.stg_bi_card_info__snp -> bi_ref.tfm_bi_card_info__mnp
#                 -> bi_intf.bi_card_info_intf__mnp. Chạy sau khi card_intf_dag và prd_intf_dag ghi log
#                 success cho cùng business date (prd_intf_dag ngoài phạm vi, log success nạp sẵn).
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

DAG_ID = 'bi_card_info_intf__mnp_dag'
BUSINESS_DATE = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}'
DBT_VARS = ('{"business_date": "' + BUSINESS_DATE + '", "run_id": "{{ dag.dag_id }}_{{ run_id }}", '
            '"tbls_data_date": {{ ti.xcom_pull(key=\'bi_card_info_intf__mnp_dag_tbls_data_date\', task_ids=\'get_tbls_data_date\') }} }')

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
  description='DWH-104 layer 2: card_intf + prd_intf -> bi_intf.bi_card_info_intf__mnp',
  tags=["bi", "bi_card_info_intf__mnp", "bu_intf_layer_2", "daily"]
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
    ti.xcom_push(key='bi_card_info_intf__mnp_dag_tbls_data_date', value=tbls_data_date)

  get_tbls_data_date_task = PythonOperator(
    task_id="get_tbls_data_date",
    python_callable=push_xcom_tbls_data_date,
    op_kwargs={'dag_id': '{{ dag.dag_id }}', 'logical_date': BUSINESS_DATE},
    trigger_rule='all_done',
  )

  # Chờ card_intf_dag và prd_intf_dag success (src_stm = 'all', prefix "_")
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

  # stg_bi_card__snp, stg_bi_card_info__snp, tfm_bi_card_info__mnp (tag tfm_bi_card_info__mnp)
  tfm_bi_card_info__mnp = DbtTaskGroup(
    group_id="tfm_bi_card_info__mnp",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:tfm_bi_card_info__mnp"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  bi_card_info_intf__mnp = DbtTaskGroup(
    group_id="bi_card_info_intf__mnp",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:bi_card_info_intf__mnp"],
      test_behavior=TestBehavior.NONE,
    ),
    operator_args={"vars": DBT_VARS}
  )

  # Generic test của hai staging, tfm_bi_card_info__mnp và bi_card_info_intf__mnp; cách chọn test giải thích ở branch_intf_dag
  bi_card_info_intf__mnp_test = DbtTaskGroup(
    group_id="bi_card_info_intf__mnp_test",
    project_config=project_config,
    profile_config=profile_config,
    execution_config=get_execution_config(test_indirect_selection=TestIndirectSelection.CAUTIOUS),
    render_config=RenderConfig(
      load_method=LoadMode.DBT_MANIFEST,
      select=["tag:tfm_bi_card_info__mnp+1,resource_type:test", "tag:bi_card_info_intf__mnp+1,resource_type:test"],
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
  start_task >> flow_ctrl >> get_tbls_data_date_task >> waiting_for_all >> tfm_bi_card_info__mnp >> bi_card_info_intf__mnp
  bi_card_info_intf__mnp >> bi_card_info_intf__mnp_test >> log_insert_task >> pipeline_success
  ########## End setup task dependencies ##########
