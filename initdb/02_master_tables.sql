-- Các bảng điều khiển mà master_trigger_dag và câu sensor SQL_CHECK_EOD_LOG đọc, để thử
-- mark_fail_running_dag khi có master DAG chạy cùng. Chỉ tạo đủ cột mà các câu SQL đó dùng tới.
\connect log_db

-- Danh sách job được master tự trigger ("enable" = 99)
create table if not exists dwh_ctrl.cstb_job_run_list (
    project   varchar(64),
    job_name  varchar(256) not null,
    priority  integer,
    "enable"  integer,
    holiday   integer
);

-- Bảng hoặc job mà một job phải chờ; sensor so src_stm với prefix ('all' ứng với '_')
-- Cột giống dwh_ctrl.cstb_etl_waiting của bộ tài liệu (training/common/sql/01_ctrl_tables.sql)
create table if not exists dwh_ctrl.cstb_etl_waiting (
    project         varchar(64),
    src_stm         varchar(64),               -- nhóm sensor trong DAG; all = cả DAG
    job_name        varchar(256) not null,     -- DAG phải chờ
    job_waiting     varchar(256) not null,     -- thứ phải xong trước (bảng nguồn hoặc DAG khác)
    project_waiting varchar(64),               -- eod | dwh
    status          varchar(8),                -- A = đang hiệu lực
    schedule        varchar(32),               -- d = hằng ngày
    priority        integer
);

-- Cờ "đủ phụ thuộc, sẵn sàng chạy" của job theo business date
create table if not exists dwh_ctrl.cstb_etl_gen_flag (
    project       varchar(64),
    job_name      varchar(256) not null,
    src_stm       varchar(64),
    ppn_dt        timestamp,
    business_date date
);

-- Lịch T24; business date hiện tại = max(mth_day_no) có airflow_business_date_flag = 'Y'
create table if not exists dwh_ctrl.t24_holiday__fu (
    mth_day_no                 date primary key,
    is_holiday                 varchar(1),
    airflow_business_date_flag varchar(1)
);

-- Lịch sử trạng thái; master ngừng trigger lại job có từ 5 dòng failed (checked trống) trong ngày
create table if not exists dwh_ctrl.log_etl_table_history (
    data_date    date,
    project_name varchar(64),
    job_name     varchar(256),
    status_name  varchar(32),
    status_flag  smallint,
    start_time   timestamp,
    end_time     timestamp,
    checked      varchar(16)
);

-- Bản sao task_instance mà master dùng để không đếm DAG đang chờ sensor; để trống ở local
create table if not exists dwh_ctrl.task_instance (
    dag_id     varchar(250),
    task_id    varchar(250),
    run_id     varchar(250),
    state      varchar(20),
    "operator" varchar(1000),
    updated_at timestamptz
);
