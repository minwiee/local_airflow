#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Kho dữ liệu local: database dwh, nạp từ thư mục warehouse/ của local_airflow
# ---------------------------------------------------------------------------
# Chạy một lần khi container postgres khởi tạo volume lần đầu (sau 01, 02 tạo log_db).
# Thư mục warehouse/ (cạnh docker-compose.yaml) mount chỉ đọc tại /warehouse. Nó chứa DDL và dữ liệu
# test chép nguyên từ bộ tài liệu dự án bằng tools/build_warehouse.py (xem warehouse/README.md), nên
# khởi tạo không cần gì ngoài thư mục local_airflow. Thứ tự giống local_pg/run_all.ps1 của bộ tài liệu:
#   1. warehouse/ddl/*.sql theo tên: 00..03 chép từ common/sql của bộ tài liệu (schema, bảng dwh_ctrl
#      của kho cho luồng QA, hàm run_qa_automation, hàm dùng chung public.months_between,
#      public.last_day); 04_dbt_test_config.sql viết tay: hai bảng mà generic test của dbt đọc qua
#      macro futils_test_should_run (dwh_ref.test_case_config, raw_eod.t24_holiday__snp), để trống:
#      test luôn bật.
#   2. Từng thư mục trong warehouse/cases/ có case.json, theo tên thư mục: ddl/01_create_tables.sql,
#      data/02_load_test_data.sql (dữ liệu test của cả hai ngày 2026-09-29, 2026-09-30),
#      qa/*_register_qa_scripts.sql, qa/*_load_expected.sql.
#      Không có 03_run_*, 04_run_* của bộ tài liệu (luồng dev: ở đây dbt chạy model qua DAG) và
#      *_check_expected.sql (câu so sánh, thay bằng tools/dwh_kit.py check sau khi DAG chạy).
# Case 02_deposit và 03_loan dùng chung ba bảng nguồn (hai bảng T24 LD, file map category): case nạp
# sau là 03_loan nên các bảng này chứa dữ liệu của 03_loan, giống trạng thái sau run_all.ps1.
# Muốn chạy depo_intf_dag thì nạp lại case 02: xem README, mục "Nạp lại dữ liệu test của một case".
#
# Database dwh đặt timezone UTC: dbt_date.convert_timezone trên PostgreSQL coi giờ của phiên là UTC
# rồi đổi sang Asia/Ho_Chi_Minh (cột ppn_date của interface L1).
# ---------------------------------------------------------------------------

dwh_warehouse_init() {
    local wh=/warehouse
    local psql_base=(psql -v ON_ERROR_STOP=1 --no-psqlrc -q --username "$POSTGRES_USER")
    run_psql() { "${psql_base[@]}" "$@" || { echo "dwh: lỗi khi chạy psql $*" >&2; return 1; }; }
    if [ ! -d "$wh/ddl" ] || [ ! -d "$wh/cases" ]; then
        echo "dwh: không thấy thư mục warehouse tại $wh (docker-compose.yaml mount ./warehouse)" >&2
        return 1
    fi

    echo "== dwh: tạo database"
    run_psql --dbname postgres -c "create database dwh encoding 'UTF8' template template0" || return 1
    run_psql --dbname postgres -c "alter database dwh set timezone to 'UTC'" || return 1

    export PGOPTIONS='--client-min-messages=warning'
    echo "== dwh: ddl"
    local f
    for f in "$wh"/ddl/*.sql; do
        if [ ! -f "$f" ]; then
            echo "dwh: không có file .sql nào trong $wh/ddl" >&2
            return 1
        fi
        echo "   $(basename "$f")"
        run_psql --dbname dwh -f "$f" || return 1
    done

    local case_dir n_cases=0
    for case_dir in "$wh"/cases/*/; do
        [ -f "${case_dir}case.json" ] || continue
        echo "== dwh: case $(basename "$case_dir")"
        # Glob của qa/ không khớp file nào thì giữ nguyên mẫu, bị báo thiếu file ở dưới
        for f in "${case_dir}ddl/01_create_tables.sql" "${case_dir}data/02_load_test_data.sql" \
                 "${case_dir}"qa/*_register_qa_scripts.sql "${case_dir}"qa/*_load_expected.sql; do
            if [ ! -f "$f" ]; then
                echo "dwh: thiếu file $f" >&2
                return 1
            fi
            echo "   ${f#"$case_dir"}"
            run_psql --dbname dwh -f "$f" || return 1
        done
        n_cases=$((n_cases + 1))
    done
    if [ "$n_cases" -eq 0 ]; then
        echo "dwh: không có case nào (thư mục có case.json) trong $wh/cases" >&2
        return 1
    fi
    unset PGOPTIONS
    echo "== dwh: xong, $n_cases case"
}

# Lỗi ở bất kỳ file nào thì dừng khởi tạo: container postgres báo lỗi thay vì chạy với kho thiếu dữ liệu
dwh_warehouse_init || exit 1
