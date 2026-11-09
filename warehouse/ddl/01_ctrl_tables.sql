-- ---------------------------------------------------------------------------
-- DWH - bảng điều khiển, log và bảng của luồng QA automation (môi trường dev)
-- ---------------------------------------------------------------------------
-- Chỉ khai báo các cột mà luồng điều phối và luồng QA của các interface này
-- đọc hoặc ghi. Ở production các bảng nằm trên Postgres log_db.
-- ---------------------------------------------------------------------------
set client_encoding to 'UTF8';

-- Nhật ký trạng thái job: 1 dòng cho mỗi (data_date, job_name, project_name)
create table if not exists dwh_ctrl.log_etl_table (
    data_date         date         not null,
    project_name      varchar(64)  not null,   -- dwh: DAG/bảng trong DWH; eod: bảng nguồn
    job_name          varchar(256) not null,   -- <dag_id> hoặc tên bảng nguồn
    start_time        timestamp,
    end_time          timestamp,
    status_name       varchar(32),             -- processing | success | failed | up_to_retry
    status_flag       smallint,                -- 0 | 1 | 3 | 5
    total_row         bigint,
    bypass_flag       smallint,
    source_success_at timestamp,
    constraint log_etl_table_uk unique (data_date, job_name, project_name)
);

-- Danh sách job được tự trigger
create table if not exists dwh_ctrl.cstb_job_run_list (
    project   varchar(64),
    job_name  varchar(256) not null,
    priority  integer,
    "enable"  integer,                         -- 99 = master_trigger_dag tự trigger
    holiday   integer                          -- 1 = nguồn không sinh vào ngày nghỉ
);

-- Cấu hình phụ thuộc: job_name chỉ chạy khi mọi job_waiting đã success
create table if not exists dwh_ctrl.cstb_etl_waiting (
    project          varchar(64),
    src_stm          varchar(64),              -- nhóm sensor trong DAG; all = cả DAG
    job_name         varchar(256) not null,    -- DAG phải chờ
    job_waiting      varchar(256) not null,    -- thứ phải xong trước
    project_waiting  varchar(64),              -- eod | ext_sensor | dwh
    status           varchar(8),               -- A = đang hiệu lực
    schedule         varchar(16),              -- d = hằng ngày
    priority         integer
);

-- Kịch bản test của QA (QA upload file MA csv_ma_automation_script, hệ thống nạp vào dwh_ref)
create table if not exists dwh_ref.csv_ma_automation_script__mnp (
    connection_id     varchar(128),
    connection_type   varchar(32),
    testcase_id       varchar(128) not null,
    qa_pic            varchar(64),
    intf_name         varchar(128),            -- tên interface; DAG kiểm tra log của <intf_name>_dag
    jira_number       varchar(64),
    column_check      varchar(512),
    rule_overview     varchar(2048),
    test_summary      varchar(2048),
    pre_condition     varchar(2048),
    expected_result   varchar(2048),
    testscript        text,                    -- câu SQL trả về cột test_result = pass | fail
    business_date     date,                    -- để trống = T-1 hoặc cuối kỳ theo dwh_frequency
    dwh_frequency     varchar(32),
    active_rule       varchar(8),              -- 1 = chạy 1 lần/ngày; 2 = chạy lại khi script đổi
    priority          integer,
    tf_etl_at         timestamp,
    tf_partition_date date
);

-- Kết quả chạy test của QA
create table if not exists dwh_intf.qa_automation_result_intf (
    business_date     date,
    start_time        timestamp,
    end_time          timestamp,
    testcase_id       varchar(128),
    qa_pic            varchar(64),
    intf_name         varchar(128),
    jira_number       varchar(64),
    column_check      varchar(512),
    rule_overview     varchar(2048),
    test_summary      varchar(2048),
    pre_condition     varchar(2048),
    expected_result   varchar(2048),
    testscript        text,
    test_result       varchar(32),             -- pass | fail | sql error
    connection_id     varchar(128),
    failure_reason    varchar(2048),
    tf_partition_date date
);
