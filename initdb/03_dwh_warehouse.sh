#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Kho dữ liệu local: database dwh, nạp từ bộ tài liệu dự án
# ---------------------------------------------------------------------------
# Chạy một lần khi container postgres khởi tạo volume lần đầu (sau 01, 02 tạo log_db).
# Bộ tài liệu dự án (thư mục dwh_onboarding/training/ của kho mã nguồn) mount chỉ đọc tại /kit.
# Script chạy đúng các file mà local_pg/run_all.ps1 của bộ tài liệu chạy để dựng bảng và dữ liệu:
#   1. common/sql/*.sql theo tên: schema, bảng dwh_ctrl của kho (luồng QA), hàm run_qa_automation,
#      hàm dùng chung public.months_between, public.last_day.
#   2. Hai bảng mà generic test của dbt đọc qua macro futils_test_should_run
#      (dwh_ref.test_case_config, raw_eod.t24_holiday__snp), để trống: test luôn bật.
#   3. Từng case theo tên thư mục: sql/01_create_tables.sql, 02_load_test_data.sql (dữ liệu test
#      của cả hai ngày 2026-09-29, 2026-09-30), *_register_qa_scripts.sql, *_load_expected.sql.
#      Không chạy 03_run_*, 04_run_* (luồng dev: ở đây dbt chạy model qua DAG) và *_check_expected.sql
#      (câu so sánh, chạy bằng tools/dwh_kit.py check sau khi DAG chạy).
# Case 02_deposit và 03_loan dùng chung ba bảng nguồn (hai bảng T24 LD, file map category): case nạp
# sau là 03_loan nên các bảng này chứa dữ liệu của 03_loan, giống trạng thái sau run_all.ps1.
# Muốn chạy depo_intf_dag thì nạp lại case 02: xem README, mục "Nạp lại dữ liệu test của một case".
#
# Database dwh đặt timezone UTC: dbt_date.convert_timezone trên PostgreSQL coi giờ của phiên là UTC
# rồi đổi sang Asia/Ho_Chi_Minh (cột ppn_date của interface L1).
# ---------------------------------------------------------------------------

dwh_warehouse_init() {
    local kit=/kit
    local psql_base=(psql -v ON_ERROR_STOP=1 --no-psqlrc -q --username "$POSTGRES_USER")
    run_psql() { "${psql_base[@]}" "$@" || { echo "dwh: lỗi khi chạy psql $*" >&2; return 1; }; }
    if [ ! -d "$kit/cases" ] || [ ! -d "$kit/common/sql" ]; then
        echo "dwh: không thấy bộ tài liệu tại $kit (docker-compose.yaml mount ../training)" >&2
        return 1
    fi

    echo "== dwh: tạo database"
    run_psql --dbname postgres -c "create database dwh encoding 'UTF8' template template0" || return 1
    run_psql --dbname postgres -c "alter database dwh set timezone to 'UTC'" || return 1

    export PGOPTIONS='--client-min-messages=warning'
    echo "== dwh: common/sql"
    local f
    for f in "$kit"/common/sql/*.sql; do
        echo "   $(basename "$f")"
        run_psql --dbname dwh -f "$f" || return 1
    done

    echo "== dwh: bảng cấu hình generic test của dbt (trống)"
    run_psql --dbname dwh <<'SQL' || return 1
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
SQL

    local case_dir pattern
    for case_dir in "$kit"/cases/*/; do
        [ -f "${case_dir}case.json" ] || continue
        echo "== dwh: case $(basename "$case_dir")"
        for pattern in '01_create_tables' '02_load_test_data' '*_register_qa_scripts' '*_load_expected'; do
            for f in "${case_dir}"sql/$pattern.sql; do
                [ -f "$f" ] || continue
                echo "   $(basename "$f")"
                run_psql --dbname dwh -f "$f" || return 1
            done
        done
    done
    unset PGOPTIONS
    echo "== dwh: xong"
}

# Lỗi ở bất kỳ file nào thì dừng khởi tạo: container postgres báo lỗi thay vì chạy với kho thiếu dữ liệu
dwh_warehouse_init || exit 1
