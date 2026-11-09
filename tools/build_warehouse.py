#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# DWH - chép DDL và dữ liệu test của database dwh từ bộ tài liệu dự án (training/) vào warehouse/
# ---------------------------------------------------------------------------
# Chỉ dùng thư viện chuẩn của Python 3 (không cần cài thêm gì).
#
# warehouse/ chứa mọi file mà Airflow local cần để dựng database dwh: initdb/03_dwh_warehouse.sh
# (container postgres) và tools/dwh_kit.py (container airflow) chỉ đọc thư mục này, nên
# docker compose up không cần gì ngoài thư mục local_airflow. Bộ tài liệu dự án vẫn là nguồn duy
# nhất: công cụ này chép nguyên từng byte các file dưới đây, không đổi nội dung hay xuống dòng:
#   ddl/<file>.sql                                 training/common/sql/*.sql
#   cases/<case>/case.json                         training/cases/<case>/case.json
#   cases/<case>/ddl/01_create_tables.sql          training/cases/<case>/sql/01_create_tables.sql
#   cases/<case>/data/02_load_test_data.sql        training/cases/<case>/sql/02_load_test_data.sql
#   cases/<case>/data/expected/*.csv               training/cases/<case>/data/expected/*.csv
#   cases/<case>/qa/<NN>_register_qa_scripts.sql   training/cases/<case>/sql/<NN>_register_qa_scripts.sql
#   cases/<case>/qa/<NN>_load_expected.sql         training/cases/<case>/sql/<NN>_load_expected.sql
# Chỉ lấy thư mục case có case.json. File trong ddl/ (*.sql) và cases/ không còn trong bộ tài liệu
# bị xóa. Hai file viết tay không bị đụng tới (HAND_WRITTEN): warehouse/README.md và
# warehouse/ddl/04_dbt_test_config.sql (hai bảng mà generic test của dbt đọc, bộ tài liệu không có).
#
# Cách chạy: py -3.12 tools\build_warehouse.py [--check]
# (tại thư mục local_airflow, Python 3.12 của máy; "py -3.12" chọn đúng bản 3.12 khi máy cài nhiều
# bản Python):
#   py -3.12 tools\build_warehouse.py               chép lại warehouse/ từ bộ tài liệu
#   py -3.12 tools\build_warehouse.py --check       chỉ so, báo file thiếu, thừa hoặc khác bộ tài liệu
#                                                   (mã lỗi 1); khác biệt CRLF/LF không tính
# Công cụ chỉ dùng để sinh lại warehouse/ khi bộ tài liệu thay đổi, docker compose up không cần nó.
# Sau khi chép lại, nạp case vào database dwh đang chạy bằng tools/dwh_kit.py load <case>
# (README, mục "Sinh lại manifest sau khi sửa model").
# ---------------------------------------------------------------------------
import argparse
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]                 # local_airflow
DEFAULT_KIT = ROOT.parent / "training"
DEFAULT_OUT = ROOT / "warehouse"

# File viết tay trong warehouse/: công cụ không ghi, không xóa, không so
HAND_WRITTEN = {"README.md", "ddl/04_dbt_test_config.sql"}

# File của từng case: (thư mục trong case của bộ tài liệu, mẫu tên, thư mục trong warehouse/cases/<case>,
# số file: "one" = đúng một file, "many" = ít nhất một file)
CASE_FILES = [
    ("sql", "01_create_tables.sql", "ddl", "one"),
    ("sql", "02_load_test_data.sql", "data", "one"),
    ("data/expected", "*.csv", "data/expected", "many"),
    ("sql", "*_register_qa_scripts.sql", "qa", "one"),
    ("sql", "*_load_expected.sql", "qa", "one"),
]


# ---------------------------------------------------------------------------
# Danh sách file cần có trong warehouse/: {đường dẫn tương đối trong warehouse: file nguồn}
# ---------------------------------------------------------------------------
def plan(kit):
    files = {}

    def add(rel, src):
        if rel in HAND_WRITTEN:
            raise ValueError(f"Bộ tài liệu có {src}, trùng file viết tay warehouse/{rel}")
        if rel in files:
            raise ValueError(f"Trùng file khi chép: warehouse/{rel} ({files[rel]} và {src})")
        files[rel] = src

    common = sorted(p for p in (kit / "common" / "sql").glob("*.sql") if p.is_file())
    if not common:
        raise ValueError(f"Không có file nào trong {kit / 'common' / 'sql'}")
    for src in common:
        add(f"ddl/{src.name}", src)

    case_dirs = sorted(p for p in (kit / "cases").iterdir() if (p / "case.json").is_file())
    if not case_dirs:
        raise ValueError(f"Không có case nào (thư mục có case.json) trong {kit / 'cases'}")
    for case_dir in case_dirs:
        case = case_dir.name
        add(f"cases/{case}/case.json", case_dir / "case.json")
        for sub, pattern, target, count in CASE_FILES:
            found = sorted(p for p in (case_dir / sub).glob(pattern) if p.is_file())
            if (count == "one" and len(found) != 1) or not found:
                need = "đúng một file" if count == "one" else "ít nhất một file"
                raise ValueError(f"{case}: cần {need} {sub}/{pattern}, thấy {len(found)}")
            for src in found:
                add(f"cases/{case}/{target}/{src.name}", src)
    return files, [p.name for p in case_dirs]


def managed_existing(out):
    """File đang có trong phần warehouse/ do công cụ quản lý: ddl/*.sql (trừ file viết tay) và mọi file của cases/."""
    found = set()
    if (out / "ddl").is_dir():
        found.update(f"ddl/{p.name}" for p in (out / "ddl").glob("*.sql") if p.is_file())
    if (out / "cases").is_dir():
        found.update(p.relative_to(out).as_posix() for p in (out / "cases").rglob("*") if p.is_file())
    return found - HAND_WRITTEN


def same_text(a, b):
    """So nội dung, không tính khác biệt CRLF/LF."""
    return a.read_bytes().replace(b"\r\n", b"\n") == b.read_bytes().replace(b"\r\n", b"\n")


# ---------------------------------------------------------------------------
# Chép lại và so
# ---------------------------------------------------------------------------
def build(files, out):
    written = 0
    for rel, src in sorted(files.items()):
        dst = out / rel
        if dst.is_file() and dst.read_bytes() == src.read_bytes():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        written += 1
    stale = sorted(managed_existing(out) - set(files))
    for rel in stale:
        (out / rel).unlink()
    # Thư mục trống còn lại trong cases/ (case hoặc thư mục con không còn file nào), xóa từ trong ra ngoài
    if (out / "cases").is_dir():
        for d in sorted((p for p in (out / "cases").rglob("*") if p.is_dir()),
                        key=lambda p: len(p.parts), reverse=True):
            if not any(d.iterdir()):
                d.rmdir()
    return written, stale


def check(files, out):
    existing = managed_existing(out)
    missing = sorted(rel for rel in files if not (out / rel).is_file())
    extra = sorted(existing - set(files))
    changed = sorted(rel for rel in files if (out / rel).is_file() and not same_text(files[rel], out / rel))
    return missing, extra, changed


def show(path):
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def main():
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Chép DDL và dữ liệu test của database dwh từ bộ tài liệu dự án vào warehouse/")
    parser.add_argument("--kit", type=Path, default=DEFAULT_KIT, help="thư mục bộ tài liệu (mặc định ../training)")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="thư mục đích (mặc định warehouse)")
    parser.add_argument("--check", action="store_true", help="chỉ so với bản đang có, không ghi")
    args = parser.parse_args()
    kit, out = args.kit.resolve(), args.out.resolve()
    if not (kit / "cases").is_dir() or not (kit / "common" / "sql").is_dir():
        sys.exit(f"Không thấy bộ tài liệu tại {kit}.\n"
                 "Công cụ này chỉ dùng để sinh lại warehouse/ khi bộ tài liệu thay đổi: cần thư mục training "
                 "cạnh local_airflow, hoặc chỉ đường bằng --kit <thư mục>.\n"
                 "docker compose up không cần công cụ này: DDL và dữ liệu test đã có sẵn trong warehouse/.")
    try:
        files, cases = plan(kit)
    except ValueError as exc:
        sys.exit(str(exc))

    if args.check:
        missing, extra, changed = check(files, out)
        if missing or extra or changed:
            print(f"{show(out)} khác bộ tài liệu, chạy lại tools/build_warehouse.py:")
            for label, rels in (("thiếu", missing), ("thừa", extra), ("khác", changed)):
                for rel in rels:
                    print(f"  {label:<6} {rel}")
            sys.exit(1)
        print("[ok] warehouse khớp bộ tài liệu")
        return

    written, stale = build(files, out)
    print(f"[ok] {show(out)}: {len(files)} file từ bộ tài liệu, các case {', '.join(cases)}; "
          f"chép lại {written} file, xóa {len(stale)} file cũ")
    for rel in stale:
        print(f"     đã xóa {rel}")
    for rel in sorted(HAND_WRITTEN):
        if not (out / rel).is_file():
            print(f"     chưa có file viết tay {rel}")
    print("     Nạp vào database dwh đang chạy: docker compose exec airflow python /opt/airflow/tools/dwh_kit.py load <case>")


if __name__ == "__main__":
    main()
