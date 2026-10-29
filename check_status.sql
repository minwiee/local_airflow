-- Xem nhanh kết quả chạy trên Airflow local: DagRun, task theo trạng thái, bảng log_etl_table,
-- số dòng của các bảng đích trong kho dwh.
-- Chạy qua check_status.ps1, hoặc:
--   docker compose cp check_status.sql postgres:/tmp/check_status.sql
--   docker compose exec -T postgres psql -U airflow -d airflow -f /tmp/check_status.sql

\echo '=== 1. DagRun gần nhất (success / failed / running / queued) ==='
select dag_id, run_id, state,
       to_char(execution_date at time zone 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI') as logical_date_vn,
       to_char(start_date at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI:SS') as start_vn,
       to_char(end_date at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI:SS') as end_vn
from dag_run
order by start_date desc nulls first
limit 20;

\echo '=== 2. Task của các DagRun trên, gom theo trạng thái ==='
select ti.dag_id, ti.run_id, coalesce(ti.state, 'none') as state, count(*) as tasks,
       string_agg(ti.task_id || case when ti.map_index >= 0 then '[' || ti.map_index || ']' else '' end,
                  ', ' order by ti.task_id, ti.map_index) as task_ids
from task_instance ti
join (select dag_id, run_id from dag_run order by start_date desc nulls first limit 20) r
  on r.dag_id = ti.dag_id and r.run_id = ti.run_id
group by ti.dag_id, ti.run_id, ti.state
order by ti.dag_id, ti.run_id, ti.state;

\connect log_db
\echo '=== 3. dwh_ctrl.log_etl_table của DAG (0 processing, 1 success, 3 failed; bỏ dòng nguồn nạp sẵn) ==='
select data_date, project_name, job_name, status_flag, status_name,
       start_time::time(0) as start_time, end_time::time(0) as end_time
from dwh_ctrl.log_etl_table
where job_name ~ '_dag'
  and job_name not in ('bal_sheet_detail_intf_dag', 'repay_acty_intf_dag', 'prd_intf_dag')
order by data_date desc, project_name, job_name;

\echo '=== 3b. Dòng còn lại của log_etl_table (bảng nguồn, DAG ngoài phạm vi, dòng thêm tay), đếm theo trạng thái ==='
select data_date, project_name, status_flag, status_name, count(*) as rows_count
from dwh_ctrl.log_etl_table
where not (job_name ~ '_dag'
           and job_name not in ('bal_sheet_detail_intf_dag', 'repay_acty_intf_dag', 'prd_intf_dag'))
group by data_date, project_name, status_flag, status_name
order by data_date desc, project_name, status_flag;

\connect dwh
\echo '=== 4. Kho dwh: số dòng của bảng đích theo ngày test ==='
select t.table_name,
       count(*) filter (where t.d = date '2026-09-29') as "2026-09-29",
       count(*) filter (where t.d = date '2026-09-30') as "2026-09-30"
from (
    select 'dwh_intf.branch_intf' as table_name, business_date as d from dwh_intf.branch_intf
    union all select 'dwh_intf.depo_intf', business_date from dwh_intf.depo_intf
    union all select 'dwh_intf.loan_contract_intf', business_date from dwh_intf.loan_contract_intf
    union all select 'dwh_intf.card_intf', business_date from dwh_intf.card_intf
    union all select 'bi_intf.bi_branch_info_intf__mnp', tf_partition_date from bi_intf.bi_branch_info_intf__mnp
    union all select 'bi_intf.bi_depo_info_intf__mnp', tf_partition_date from bi_intf.bi_depo_info_intf__mnp
    union all select 'bi_intf.bi_lend_repay_info_intf__fa', tf_partition_date from bi_intf.bi_lend_repay_info_intf__fa
    union all select 'bi_intf.bi_card_info_intf__mnp', tf_partition_date from bi_intf.bi_card_info_intf__mnp
) t
group by t.table_name
order by t.table_name;
