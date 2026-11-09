#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# DWH - nạp lại dữ liệu test và so kết quả DAG với bộ tài liệu dự án (Airflow local)
# ---------------------------------------------------------------------------
# Chạy trong container airflow (cần psycopg2 của image Airflow); thư mục warehouse/ của local_airflow
# (DDL, dữ liệu test, kết quả mong đợi và test QA chép nguyên từ bộ tài liệu dự án bằng
# tools/build_warehouse.py) mount chỉ đọc tại /opt/airflow/warehouse, thư mục tools/ mount tại
# /opt/airflow/tools. Biến DWH_WAREHOUSE_DIR đổi được thư mục này (tên cũ DWH_KIT_DIR vẫn dùng được).
#
#   docker compose exec airflow python /opt/airflow/tools/dwh_kit.py load 02_deposit
#       Dựng lại bảng và dữ liệu test của case trong database dwh (cases/<case>/ddl/01_create_tables.sql,
#       data/02_load_test_data.sql), rồi xóa log của các DAG của case cho các ngày test trong log_db
#       (dwh_ctrl.log_etl_table) để DAG layer 2 lại chờ DAG L1. Dùng khi chuyển giữa case 02 và 03
#       (dùng chung bảng nguồn T24 LD) hoặc muốn chạy lại case từ đầu.
#
#   docker compose exec airflow python /opt/airflow/tools/dwh_kit.py check [case ...]
#       Sau khi trigger DAG cho các ngày test, với từng case:
#       1. chép log của các DAG của case từ log_db sang dwh_ctrl.log_etl_table của database dwh
#          (hàm QA dwh_ctrl.run_qa_automation đọc log ở đó để biết interface đã chạy xong);
#       2. nạp lại test QA và kết quả mong đợi (cases/<case>/qa/*_register_qa_scripts.sql,
#          qa/*_load_expected.sql);
#       3. so bảng đích với kết quả mong đợi (cases/<case>/data/expected/*.csv) theo từng ngày, giống
#          sql/*_check_expected.sql của bộ tài liệu nhưng không so cột tf_run_id: DAG ghi run_id của
#          Airflow (<dag_id>_manual__...), luồng dev của bộ tài liệu ghi 'manual';
#       4. chạy test QA cho từng ngày (dwh_ctrl.run_qa_automation).
#       In bảng tổng kết giống local_pg/run_all.ps1; trả mã lỗi 1 nếu có case chưa đạt.
# ---------------------------------------------------------------------------
import argparse
import csv
import json
import os
import sys
from pathlib import Path

import psycopg2

WAREHOUSE = Path(os.environ.get("DWH_WAREHOUSE_DIR") or os.environ.get("DWH_KIT_DIR") or "/opt/airflow/warehouse")
IGNORED_COLUMNS = {"tf_run_id"}


def connect(dbname):
    conn = psycopg2.connect(
        host=os.environ.get("DWH_LOCAL_HOST", "postgres"),
        port=5432,
        user=os.environ.get("DWH_LOCAL_USER", "airflow"),
        password=os.environ.get("DWH_LOCAL_PASSWORD", "airflow"),
        dbname=dbname,
        options="-c client_min_messages=warning",
    )
    conn.autocommit = True
    return conn


def case_dirs(names):
    dirs = sorted(p for p in (WAREHOUSE / "cases").iterdir() if (p / "case.json").exists())
    if names:
        unknown = set(names) - {p.name for p in dirs}
        if unknown:
            sys.exit(f"Không có case: {', '.join(sorted(unknown))}. Các case: {', '.join(p.name for p in dirs)}")
        dirs = [p for p in dirs if p.name in names]
    return dirs


def read_case(case_dir):
    cfg = json.loads((case_dir / "case.json").read_text(encoding="utf-8"))
    dates = cfg.get("business_dates") or [cfg["business_date"]]
    dag_ids = [step["dag_id"] for step in cfg["steps"]]
    return cfg, dates, dag_ids


def run_sql_file(cur, path):
    cur.execute(path.read_text(encoding="utf-8"))


def one_sql(case_dir, subdir, pattern):
    files = sorted((case_dir / subdir).glob(pattern))
    if len(files) != 1:
        raise SystemExit(f"{case_dir.name}: cần đúng một file {subdir}/{pattern}, thấy {len(files)}")
    return files[0]


# ---------------------------------------------------------------------------
def cmd_load(args):
    dwh, ctrl = connect("dwh"), connect("log_db")
    for case_dir in case_dirs(args.cases):
        cfg, dates, dag_ids = read_case(case_dir)
        with dwh.cursor() as cur:
            for subdir, pattern in (("ddl", "01_create_tables.sql"), ("data", "02_load_test_data.sql")):
                path = one_sql(case_dir, subdir, pattern)
                print(f"[{case_dir.name}] dwh: {path.relative_to(WAREHOUSE).as_posix()}")
                run_sql_file(cur, path)
        with ctrl.cursor() as cur:
            cur.execute("delete from dwh_ctrl.log_etl_table where project_name = 'dwh' and job_name = any(%s) "
                        "and data_date = any(%s::date[])", (dag_ids, dates))
            print(f"[{case_dir.name}] log_db: xóa {cur.rowcount} dòng log của {', '.join(dag_ids)} ngày {', '.join(dates)}")
    print("Xong. Trigger lại DAG L1 rồi DAG layer 2 của case cho từng ngày test (README, mục Chạy dbt qua Cosmos).")


# ---------------------------------------------------------------------------
def sync_logs(ctrl, dwh, dag_ids, dates):
    with ctrl.cursor() as cur:
        cur.execute("""select data_date, project_name, job_name, start_time, end_time, status_name, status_flag
                       from dwh_ctrl.log_etl_table
                       where project_name = 'dwh' and job_name = any(%s) and data_date = any(%s::date[])""",
                    (dag_ids, dates))
        rows = cur.fetchall()
    with dwh.cursor() as cur:
        cur.execute("delete from dwh_ctrl.log_etl_table where project_name = 'dwh' and job_name = any(%s) "
                    "and data_date = any(%s::date[])", (dag_ids, dates))
        for row in rows:
            cur.execute("""insert into dwh_ctrl.log_etl_table
                           (data_date, project_name, job_name, start_time, end_time, status_name, status_flag)
                           values (%s, %s, %s, %s, %s, %s, %s)""", row)
    return {(str(r[0]), r[2]): r[5] for r in rows}


def compare(cur, case_dir, cfg, dates):
    results = []
    for csv_path in sorted((case_dir / "data" / "expected").glob("*.csv")):
        table = csv_path.stem
        expected = "qa_expected." + table.replace(".", "__")
        with csv_path.open(encoding="utf-8-sig", newline="") as f:
            header = next(csv.reader(f))
        date_col = cfg["expected_filter"][table]
        cols = [c for c in header if c not in IGNORED_COLUMNS]
        actual_cols = ", ".join(f"rtrim({c}::text) as {c}" for c in cols)
        wanted_cols = ", ".join(cols)
        for day in dates:
            actual = f"select {actual_cols} from {table} where {date_col} = %(d)s"
            wanted = f"select {wanted_cols} from {expected} where {date_col} = %(d)s"
            cur.execute(f"""select (select count(*) from ({wanted}) x),
                                   (select count(*) from {table} where {date_col} = %(d)s),
                                   (select count(*) from ({actual} except {wanted}) x),
                                   (select count(*) from ({wanted} except {actual}) x)""", {"d": day})
            n_expected, n_actual, not_expected, missing = cur.fetchone()
            run_ids = ""
            if "tf_run_id" in header:
                cur.execute(f"select string_agg(distinct tf_run_id, ', ') from {table} where {date_col} = %(d)s", {"d": day})
                run_ids = cur.fetchone()[0] or ""
            ok = not_expected == 0 and missing == 0 and n_expected > 0
            results.append((table, day, n_expected, n_actual, not_expected, missing, "pass" if ok else "fail", run_ids))
    return results


def run_qa(cur, cfg, dates):
    rows = []
    for day in dates:
        cur.execute("select out_testcase_id, out_test_result, coalesce(out_failure_reason, '') "
                    "from dwh_ctrl.run_qa_automation(%s, %s) order by 1", (day, cfg["testcase_prefix"] + "%"))
        rows.extend((day, *r) for r in cur.fetchall())
    return rows


def cmd_check(args):
    dwh, ctrl = connect("dwh"), connect("log_db")
    summary = []
    for case_dir in case_dirs(args.cases):
        cfg, dates, dag_ids = read_case(case_dir)
        print(f"\n== Case {case_dir.name} - {cfg.get('title', '')}: ngày {', '.join(dates)}")
        logs = sync_logs(ctrl, dwh, dag_ids, dates)
        for day in dates:
            states = ", ".join(f"{dag}={logs.get((day, dag), 'chưa chạy')}" for dag in dag_ids)
            print(f"  log {day}: {states}")
        with dwh.cursor() as cur:
            for pattern in ("*_register_qa_scripts.sql", "*_load_expected.sql"):
                run_sql_file(cur, one_sql(case_dir, "qa", pattern))
            results = compare(cur, case_dir, cfg, dates)
            print(f"  So với kết quả mong đợi (không so {', '.join(sorted(IGNORED_COLUMNS))}):")
            print(f"    {'bảng':<38} {'ngày':<10} {'mong đợi':>8} {'thực tế':>8} {'thừa':>5} {'thiếu':>5}  kết quả")
            for table, day, n_exp, n_act, extra, miss, res, run_ids in results:
                print(f"    {table:<38} {day:<10} {n_exp:>8} {n_act:>8} {extra:>5} {miss:>5}  {res}")
                if run_ids:
                    print(f"      tf_run_id: {run_ids}")
            qa = run_qa(cur, cfg, dates)
        print("  Test QA (dwh_ctrl.run_qa_automation):")
        for day, tc, res, reason in qa:
            print(f"    {day}  {tc:<38} {res:<10} {reason}")
        n_pass = sum(1 for r in qa if r[2] == "pass")
        expected_ok = all(r[6] == "pass" for r in results) and bool(results)
        summary.append((case_dir.name, len(dates), "pass" if expected_ok else "fail", n_pass, len(qa)))

    print("\n== Tổng kết")
    for name, days, exp, n_pass, total in summary:
        print(f"  {name:<12} {days} ngày  so với kết quả mong đợi: {exp:<5} test QA: {n_pass}/{total} pass")
    bad = [s for s in summary if s[2] != "pass" or s[3] != s[4] or s[4] == 0]
    if bad:
        print("CÓ CASE CHƯA ĐẠT: xem bảng ở trên. Case 02_deposit và 03_loan dùng chung bảng nguồn T24 LD,")
        print("chỉ case vừa nạp (dwh_kit.py load <case>) mới chạy đúng DAG và test QA.")
        sys.exit(1)


def main():
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Nạp lại dữ liệu test và so kết quả DAG với bộ tài liệu dự án")
    sub = parser.add_subparsers(dest="command", required=True)
    p_load = sub.add_parser("load", help="dựng lại bảng và dữ liệu test của case trong database dwh")
    p_load.add_argument("cases", nargs="+", help="tên case, ví dụ 02_deposit")
    p_check = sub.add_parser("check", help="so bảng đích với kết quả mong đợi và chạy test QA")
    p_check.add_argument("cases", nargs="*", help="tên case (mặc định: tất cả)")
    args = parser.parse_args()
    if not (WAREHOUSE / "cases").is_dir():
        sys.exit(f"Không thấy thư mục warehouse tại {WAREHOUSE} (docker-compose.yaml mount ./warehouse)")
    {"load": cmd_load, "check": cmd_check}[args.command](args)


if __name__ == "__main__":
    main()
