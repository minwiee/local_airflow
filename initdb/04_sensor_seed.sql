-- ---------------------------------------------------------------------------
-- Cấu hình chờ nguồn của 8 DAG interface và log nguồn đã về cho hai ngày test
-- ---------------------------------------------------------------------------
-- Chạy một lần khi container postgres khởi tạo volume lần đầu, trên log_db (database điều khiển
-- mà connection postgres-dwh-ctrl trỏ tới). Nhờ các dòng dưới đây, DE trigger một DAG interface
-- cho 2026-09-29 hoặc 2026-09-30 là sensor qua ngay và DAG chạy tới cuối.
--   1. dwh_ctrl.cstb_etl_waiting: DAG nào chờ bảng hoặc job nào. src_stm khớp prefix của sensor
--      (waiting_for_t24 có prefix "_t24" ứng với src_stm = 't24'; prefix "_" ứng với 'all').
--      Cấu hình của branch_intf_dag và bi_branch_info_intf__mnp_dag lấy theo
--      cases/01_branch/ctrl/dependency_and_sensor.sql của bộ tài liệu; các DAG khác theo cùng cách.
--   2. dwh_ctrl.log_etl_table: dòng success của bảng nguồn và của các DAG ngoài phạm vi (bảng của
--      chúng nạp sẵn từ bộ dữ liệu test) cho cả hai ngày. Dòng của DAG interface L1 không nạp sẵn:
--      log_insert_task của DAG L1 ghi, rồi sensor của DAG layer 2 mới qua.
--   3. dwh_ctrl.t24_holiday__fu: lịch 26-30/09/2026 để tính ngày làm việc trước (pre_last_wk_day
--      của depo_intf_dag). airflow_business_date_flag để 'N' nên master_trigger_dag không chọn các
--      ngày này nếu không có lệnh của README.
-- Bài tập: xóa một dòng nguồn ở mục 2 rồi trigger DAG, sensor nằm ở up_for_reschedule (README).
-- ---------------------------------------------------------------------------
\connect log_db

insert into dwh_ctrl.cstb_etl_waiting
    (project, src_stm, job_name, job_waiting, project_waiting, status, schedule, priority) values
    -- branch_intf_dag: sensor waiting_for_t24
    ('dwh', 't24', 'branch_intf_dag', 'stg_raw_t24_bank_company__mnp',             'dwh', 'A', 'd', 1),
    ('dwh', 't24', 'branch_intf_dag', 'stg_raw_t24_bank_company_details__mnp',     'dwh', 'A', 'd', 1),
    ('dwh', 't24', 'branch_intf_dag', 'stg_raw_t24_bank_province_details__mnp',    'dwh', 'A', 'd', 1),
    ('dwh', 't24', 'branch_intf_dag', 'eod|aws_bankwide|t24_company__s2',          'eod', 'A', 'd', 1),
    -- depo_intf_dag: sensor waiting_for_t24_ld (hai bảng T24 LD), waiting_for_ar_x_cl_pst (bảng LD và file map category)
    ('dwh', 't24_ld', 'depo_intf_dag', 'eod|aws_bankwide|t24_ld_loans_and_depo__mnp',         'eod', 'A', 'd', 1),
    ('dwh', 't24_ld', 'depo_intf_dag', 'eod|aws_bankwide|t24_ld_loans_and_depo_details__mnp', 'eod', 'A', 'd', 1),
    ('dwh', 'ar_x_cl_pst', 'depo_intf_dag', 'eod|aws_bankwide|t24_ld_loans_and_depo__mnp',    'eod', 'A', 'd', 1),
    ('dwh', 'ar_x_cl_pst', 'depo_intf_dag', 'csv_ma_map_cgy_ar_tp__mnp',                      'dwh', 'A', 'd', 1),
    -- loan_contract_intf_dag: sensor waiting_for_t24_ld (bảng LD, file map category), waiting_for_bal_sheet (số dư GL)
    ('dwh', 't24_ld', 'loan_contract_intf_dag', 'eod|aws_bankwide|t24_ld_loans_and_depo__mnp',         'eod', 'A', 'd', 1),
    ('dwh', 't24_ld', 'loan_contract_intf_dag', 'eod|aws_bankwide|t24_ld_loans_and_depo_details__mnp', 'eod', 'A', 'd', 1),
    ('dwh', 't24_ld', 'loan_contract_intf_dag', 'csv_ma_map_cgy_ar_tp__mnp',                           'dwh', 'A', 'd', 1),
    ('dwh', 'bal_sheet', 'loan_contract_intf_dag', 'bal_sheet_detail_intf_dag',                        'dwh', 'A', 'd', 1),
    -- card_intf_dag: sensor waiting_for_way4
    ('dwh', 'way4', 'card_intf_dag', 'eod|aws_bankwide|way4_acnt_contract__mnp', 'eod', 'A', 'd', 1),
    ('dwh', 'way4', 'card_intf_dag', 'eod|aws_bankwide|way4_appl_product__mnp',  'eod', 'A', 'd', 1),
    ('dwh', 'way4', 'card_intf_dag', 'eod|aws_bankwide|way4_appl_pr_group__s2',  'eod', 'A', 'd', 1),
    ('dwh', 'way4', 'card_intf_dag', 'eod|aws_bankwide|way4_contr_status__mnp',  'eod', 'A', 'd', 1),
    -- DAG layer 2: sensor waiting_for_all (prefix "_") chờ DAG L1 và DAG khác mà model đọc bằng ref()
    ('dwh', 'all', 'bi_branch_info_intf__mnp_dag',    'branch_intf_dag',        'dwh', 'A', 'd', 1),
    ('dwh', 'all', 'bi_depo_info_intf__mnp_dag',      'depo_intf_dag',          'dwh', 'A', 'd', 1),
    ('dwh', 'all', 'bi_lend_repay_info_intf__fa_dag', 'loan_contract_intf_dag', 'dwh', 'A', 'd', 1),
    ('dwh', 'all', 'bi_lend_repay_info_intf__fa_dag', 'repay_acty_intf_dag',    'dwh', 'A', 'd', 1),
    ('dwh', 'all', 'bi_card_info_intf__mnp_dag',      'card_intf_dag',          'dwh', 'A', 'd', 1),
    ('dwh', 'all', 'bi_card_info_intf__mnp_dag',      'prd_intf_dag',           'dwh', 'A', 'd', 1);

-- Nguồn đã về (success) cho cả hai ngày test: mọi job_waiting ở trên, trừ DAG interface L1
insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, start_time, end_time, status_name, status_flag)
select d.data_date, w.project_waiting, w.job_waiting,
       d.data_date + time '22:30', d.data_date + time '23:00', 'success', 1
from (select distinct job_waiting, project_waiting
      from dwh_ctrl.cstb_etl_waiting
      where job_waiting not in ('branch_intf_dag', 'depo_intf_dag', 'loan_contract_intf_dag', 'card_intf_dag')) w
cross join (values (date '2026-09-29'), (date '2026-09-30')) d(data_date)
on conflict (data_date, job_name, project_name) do nothing;

-- Lịch T24 của tuần test: 26, 27 là ngày nghỉ (H), 28-30 là ngày làm việc (W)
insert into dwh_ctrl.t24_holiday__fu (mth_day_no, is_holiday, airflow_business_date_flag) values
    ('2026-09-26', 'H', 'N'),
    ('2026-09-27', 'H', 'N'),
    ('2026-09-28', 'W', 'N'),
    ('2026-09-29', 'W', 'N'),
    ('2026-09-30', 'W', 'N')
on conflict (mth_day_no) do nothing;
