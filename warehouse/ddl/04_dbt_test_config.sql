-- ---------------------------------------------------------------------------
-- DWH - bảng cấu hình mà generic test của dbt đọc (Airflow local)
-- ---------------------------------------------------------------------------
-- File viết tay, không chép từ bộ tài liệu: tools/build_warehouse.py không ghi đè, không xóa file này.
-- Macro futils_test_should_run của generic test (count_gte_zero, unique, not_null) đọc hai bảng dưới
-- đây qua hai nguồn mà tools/build_dbt_project.py khai thêm trong models/sources.yml. Ở dbt project
-- trung tâm hai nguồn này đã có; bộ tài liệu không mang theo nên Airflow local tự tạo.
-- Hai bảng để trống: mọi test đều bật, không có ngày nghỉ.
-- initdb/03_dwh_warehouse.sh chạy file này sau 00..03 (schema dwh_ref, raw_eod tạo ở 00_schemas.sql).
-- ---------------------------------------------------------------------------
create table if not exists dwh_ref.test_case_config (
    model_name        varchar(256),
    test_type         varchar(64),     -- count_gte_zero | unique | not_null
    is_enable         boolean,
    is_enable_holiday boolean,
    is_active         boolean
);
create table if not exists raw_eod.t24_holiday__snp (
    mth_day_no   date,
    holiday_code varchar(32),          -- VN00... theo đơn vị
    is_holiday   varchar(1),           -- H = ngày nghỉ, W = ngày làm việc
    tf_partition_date date
);
