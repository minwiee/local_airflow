-- Chạy một lần khi container postgres khởi tạo volume lần đầu.
-- Tạo database log_db với schema dwh_ctrl và bảng log_etl_table, giống Postgres điều khiển
-- mà mark_fail_running_dag đọc và ghi qua connection postgres-dwh-ctrl.
create database log_db;

\connect log_db

create schema if not exists dwh_ctrl;

create table if not exists dwh_ctrl.log_etl_table (
    data_date         date         not null,
    project_name      varchar(64)  not null,   -- dwh: DAG/bảng trong DWH; eod: bảng nguồn
    job_name          varchar(256) not null,   -- <dag_id> hoặc tên bảng
    start_time        timestamp,
    end_time          timestamp,
    status_name       varchar(32),             -- processing | success | failed | up_to_retry
    status_flag       smallint,                -- 0 | 1 | 3 | 5
    total_row         bigint,
    bypass_flag       smallint,
    source_success_at timestamp,
    constraint log_etl_table_uk unique (data_date, job_name, project_name)
);
