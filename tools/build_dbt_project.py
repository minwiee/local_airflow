#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# DWH - dựng dbt project của Airflow local từ bộ tài liệu dự án (training/)
# ---------------------------------------------------------------------------
# Chỉ dùng thư viện chuẩn của Python 3 (không cần cài thêm gì).
#
# Bộ tài liệu dự án là nguồn duy nhất của model, macro và generic test. Công cụ này
# dựng lại các phần sinh ra của dbt/dwh_project/:
#   macros/                  chép từ training/dbt_project/macros/
#   tests/                   chép từ training/dbt_project/tests/
#   models/<lớp>/...         chép từ training/cases/<case>/dbt/models/ (giữ nguyên đường dẫn)
#   models/sources.yml       gộp sources.yml của mọi case: mỗi nguồn một khối, bảng khai ở
#                            nhiều case (bảng T24 LD của case 02 và 03) chỉ giữ một lần; thêm
#                            hai nguồn mà macro futils_test_should_run đọc (LOCAL_SOURCES)
#   models/schema.yml        gộp schema.yml của mọi case, giữ nguyên cấu hình và test; tham số
#                            của generic test (filter_column, column_name...) lồng dưới
#                            "arguments:", cách khai dbt hỗ trợ từ 1.10.5 (TEST_PROPERTIES)
#   models/ngoai_pham_vi/    model giữ chỗ cho bảng do DAG khác dựng (khai trong schema.yml,
#                            đọc bằng ref(), không có file .sql trong bộ tài liệu)
# Hai phần cuối là thứ dbt project trung tâm có sẵn nhưng bộ tài liệu không mang theo.
# Các file khác của dbt/dwh_project (dbt_project.yml, packages.yml) không bị đụng tới.
#
# Cách chạy (tại thư mục local_airflow, Python 3.12 của máy; "py -3.12" chọn đúng bản 3.12
# khi máy cài nhiều bản Python):
#   py -3.12 tools\build_dbt_project.py               dựng lại các thư mục trên
#   py -3.12 tools\build_dbt_project.py --check       chỉ so, báo file nào khác bộ tài liệu (mã lỗi 1)
# Sau khi dựng lại, sinh lại manifest trong container (xem README, mục "Sinh lại manifest").
# ---------------------------------------------------------------------------
import argparse
import filecmp
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]                 # local_airflow
DEFAULT_KIT = ROOT.parent / "training"
PROJECT = ROOT / "dbt" / "dwh_project"
GENERATED = ("models", "macros", "tests")
LOCAL_DIR = "ngoai_pham_vi"

# Nguồn mà macro futils_test_should_run (generic test) đọc. Ở dbt project trung tâm hai
# nguồn này đã khai báo; bộ tài liệu không có nên Airflow local tự khai. Bảng tương ứng
# do initdb/03_dwh_warehouse.sh tạo trống: test luôn bật, không có ngày nghỉ.
LOCAL_SOURCES = [
    {"name": "dwh_ref", "database": "{{ var('src_bu_intf_db') }}", "schema": "dwh_ref",
     "tables": [("raw_test_case_config", "test_case_config",
                 "bật/tắt generic test theo model và loại test (futils_test_should_run)")]},
    {"name": "raw_eod_common", "database": "{{ var('src_bu_intf_db') }}", "schema": "raw_eod",
     "tables": [("raw_t24_holiday", "t24_holiday__snp",
                 "lịch ngày nghỉ T24, test có is_enable_holiday = false bỏ qua ngày nghỉ")]},
]

# Khóa được giữ ở cấp trên của một generic test trong schema.yml: thuộc tính của test và cấu hình
# test viết tắt (severity, where...). Mọi khóa khác là tham số của macro test, lồng dưới "arguments:".
TEST_PROPERTIES = {
    "arguments", "config", "name", "description",
    "severity", "where", "limit", "tags", "enabled", "meta", "store_failures", "store_failures_as",
    "warn_if", "error_if", "fail_calc", "database", "schema", "alias",
}

PLACEHOLDER = """/*
*----------------------------------------------------------------------*
* Program code  : {model}
* Mô tả         : Model giữ chỗ của Airflow local. {model} do DAG khác dựng (ngoài
*                 phạm vi bộ tài liệu); dữ liệu của nó được nạp sẵn từ bộ dữ liệu test
*                 (cases/{case}/data/source). File này chỉ để ref('{model}') của các model
*                 trong phạm vi phân giải được: cấu hình (schema, materialized) lấy theo
*                 schema.yml. Không có DAG nào chọn model này; nếu chạy tay thì model
*                 không nạp thêm dòng nào.
* Created by    : tools/build_dbt_project.py
*----------------------------------------------------------------------*
*/

select * from {{{{ this }}}} where false
"""


def read_lines(path):
    return path.read_text(encoding="utf-8").splitlines()


# ---------------------------------------------------------------------------
# sources.yml: mẫu cố định của bộ tài liệu
#   sources:
#     - name: <nguồn>
#       database: ...
#       schema: ...
#       tables:
#         - name: raw_...
#           identifier: ...
# ---------------------------------------------------------------------------
def parse_sources(path):
    sources, src, table = [], None, None
    for raw in read_lines(path):
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^  - name:\s*(\S+)$", line)
        if m:
            src = {"name": m.group(1), "props": {}, "tables": []}
            sources.append(src)
            table = None
            continue
        m = re.match(r"^    (\w+):\s*(.*)$", line)
        if m and src is not None:
            if m.group(1) != "tables":
                src["props"][m.group(1)] = m.group(2)
            continue
        m = re.match(r"^      - name:\s*(\S+)$", line)
        if m and src is not None:
            table = {"name": m.group(1), "lines": []}
            src["tables"].append(table)
            continue
        m = re.match(r"^        \S", line)
        if m and table is not None:
            table["lines"].append(line)
            continue
        if line in ("version: 2", "sources:"):
            continue
        raise ValueError(f"{path}: dòng không đúng mẫu sources.yml: {line!r}")
    return sources


def merge_sources(case_sources):
    """case_sources: [(case, [source...])]. Trả về danh sách nguồn đã gộp, giữ thứ tự xuất hiện."""
    merged, index = [], {}
    for case, sources in case_sources:
        for src in sources:
            name = src["name"]
            if name not in index:
                index[name] = {"name": name, "props": dict(src["props"]), "tables": [], "by_name": {}}
                merged.append(index[name])
            target = index[name]
            if target["props"] != src["props"]:
                raise ValueError(f"Nguồn {name} khai khác nhau giữa các case: {target['props']} / {src['props']} ({case})")
            for table in src["tables"]:
                known = target["by_name"].get(table["name"])
                if known is None:
                    entry = {"name": table["name"], "lines": table["lines"], "cases": [case], "note": None}
                    target["by_name"][table["name"]] = entry
                    target["tables"].append(entry)
                elif known["lines"] != table["lines"]:
                    raise ValueError(f"Bảng {name}.{table['name']} khai khác nhau giữa {known['cases']} và {case}")
                else:
                    known["cases"].append(case)
    for src in LOCAL_SOURCES:
        props = {"database": f"\"{src['database']}\"", "schema": src["schema"]}
        if src["name"] not in index:
            index[src["name"]] = {"name": src["name"], "props": props, "tables": [], "by_name": {}}
            merged.append(index[src["name"]])
        target = index[src["name"]]
        if target["props"] != props:
            raise ValueError(f"Nguồn {src['name']} của Airflow local khác khai báo trong bộ tài liệu")
        for name, identifier, note in src["tables"]:
            if name in target["by_name"]:
                raise ValueError(f"Bộ tài liệu đã khai {src['name']}.{name}: bỏ khỏi LOCAL_SOURCES")
            entry = {"name": name, "lines": [f"        identifier: {identifier}"], "cases": [], "note": note}
            target["by_name"][name] = entry
            target["tables"].append(entry)
    return merged


def render_sources(merged, kit_rel):
    out = [
        "# ---------------------------------------------------------------------------",
        "# File này do tools/build_dbt_project.py sinh ra. Đừng sửa tay: sửa sources.yml của case",
        f"# trong {kit_rel}/cases/<case>/dbt/ rồi chạy lại công cụ.",
        "# ---------------------------------------------------------------------------",
        "# Gộp sources.yml của mọi case. Bảng khai ở nhiều case chỉ giữ một lần, chú thích ghi",
        "# các case dùng bảng. Bảng ghi \"Airflow local\" là nguồn mà dbt project trung tâm có sẵn",
        "# nhưng bộ tài liệu không khai (generic test đọc qua macro futils_test_should_run).",
        "# ---------------------------------------------------------------------------",
        "version: 2",
        "",
        "sources:",
    ]
    for src in merged:
        out.append(f"  - name: {src['name']}")
        for key, value in src["props"].items():
            out.append(f"    {key}: {value}")
        out.append("    tables:")
        for table in src["tables"]:
            if table["note"]:
                out.append(f"      # Airflow local: {table['note']}")
            else:
                out.append(f"      # case: {', '.join(table['cases'])}")
            out.append(f"      - name: {table['name']}")
            out.extend(table["lines"])
        out.append("")
    return "\n".join(out).rstrip() + "\n"


# ---------------------------------------------------------------------------
# schema.yml: giữ nguyên các khối model (từ "  - name:" tới trước khối kế tiếp)
# ---------------------------------------------------------------------------
def parse_schema(path):
    lines = read_lines(path)
    try:
        start = lines.index("models:") + 1
    except ValueError:
        raise ValueError(f"{path}: không thấy dòng 'models:'")
    blocks, current = [], None
    for line in lines[start:]:
        m = re.match(r"^  - name:\s*(\S+)\s*$", line)
        if m:
            current = {"name": m.group(1), "lines": [line]}
            blocks.append(current)
        elif current is not None:
            current["lines"].append(line.rstrip())
        elif line.strip() and not line.lstrip().startswith("#"):
            raise ValueError(f"{path}: dòng nằm ngoài khối model: {line!r}")
    for block in blocks:
        while block["lines"] and not block["lines"][-1].strip():
            block["lines"].pop()
    return blocks


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def is_content(line):
    return bool(line.strip()) and not line.lstrip().startswith("#")


def nest_test_body(body):
    """Các dòng con của một generic test -> tham số lồng dưới "arguments:".

    Giữ nguyên khi test đã có "arguments:", không có tham số, hoặc không theo mẫu "khóa: giá trị".
    """
    keyed = [line for line in body if is_content(line)]
    if not keyed:
        return body
    key_indent = min(indent_of(line) for line in keyed)
    chunks = []                                   # [khóa, các dòng]: dòng khóa và dòng con của nó
    for line in body:
        if is_content(line) and indent_of(line) == key_indent:
            m = re.match(r"^\s*([\w-]+):", line)
            if not m:
                return body
            chunks.append([m.group(1), [line]])
        elif chunks:
            chunks[-1][1].append(line)
        else:
            chunks.append([None, [line]])         # chú thích đứng trước khóa đầu tiên
    keys = [key for key, _ in chunks]
    if "arguments" in keys or all(key is None or key in TEST_PROPERTIES for key in keys):
        return body
    out, opened = [], False
    for key, lines in chunks:
        if key is None or key in TEST_PROPERTIES:
            out.extend(lines)
            continue
        if not opened:
            out.append(" " * key_indent + "arguments:")
            opened = True
        out.extend("  " + line if line.strip() else line for line in lines)
    return out


def nest_test_arguments(lines):
    """Lồng tham số của mọi generic test (dưới tests: hoặc data_tests:) trong một khối model."""
    out, tests_indent, i = [], None, 0
    while i < len(lines):
        line = lines[i]
        if is_content(line) and tests_indent is not None:
            ind = indent_of(line)
            if ind < tests_indent or (ind == tests_indent and not line.lstrip().startswith("- ")):
                tests_indent = None
        if re.match(r"^\s*(tests|data_tests):\s*$", line):
            tests_indent = indent_of(line)
            out.append(line)
            i += 1
            continue
        if tests_indent is not None and re.match(r"^\s*- [\w.]+:\s*$", line):
            item_indent, j = indent_of(line), i + 1
            while j < len(lines) and (not lines[j].strip() or indent_of(lines[j]) > item_indent):
                j += 1
            body = lines[i + 1:j]
            trailing = []
            while body and not body[-1].strip():
                trailing.insert(0, body.pop())
            out.append(line)
            out.extend(nest_test_body(body))
            out.extend(trailing)
            i = j
            continue
        out.append(line)
        i += 1
    return out


def render_schema(case_blocks, kit_rel):
    out = [
        "# ---------------------------------------------------------------------------",
        "# File này do tools/build_dbt_project.py sinh ra. Đừng sửa tay: sửa schema.yml của case",
        f"# trong {kit_rel}/cases/<case>/dbt/ rồi chạy lại công cụ.",
        "# ---------------------------------------------------------------------------",
        "# Gộp schema.yml của mọi case: cấu hình (tag, schema, materialized) và test của từng model.",
        "# Tham số của generic test (filter_column, column_name...) được lồng dưới \"arguments:\" theo",
        "# cách khai dbt hỗ trợ từ 1.10.5; tên test và tham số giữ nguyên như schema.yml của case.",
        "# Model do DAG khác dựng (không có file .sql trong bộ tài liệu) có model giữ chỗ trong",
        f"# models/{LOCAL_DIR}/ để ref() phân giải được.",
        "# ---------------------------------------------------------------------------",
        "version: 2",
        "",
        "models:",
    ]
    for case, title, blocks in case_blocks:
        out.append(f"  # ===== Case {case} - {title} ({kit_rel}/cases/{case}/dbt/schema.yml)")
        out.append("")
        for block in blocks:
            out.extend(nest_test_arguments(block["lines"]))
            out.append("")
    return "\n".join(out).rstrip() + "\n"


# ---------------------------------------------------------------------------
# Dựng project
# ---------------------------------------------------------------------------
def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def copy_tree(src_dir, dst_dir, pattern="**/*.sql"):
    count = 0
    for src in sorted(src_dir.glob(pattern)):
        if src.is_file():
            dst = dst_dir / src.relative_to(src_dir)
            if dst.exists():
                raise ValueError(f"Trùng file khi chép: {dst}")
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
            count += 1
    return count


def build(kit, out):
    for name in GENERATED:
        if (out / name).exists():
            shutil.rmtree(out / name)
    kit_rel = "training"

    n_macros = copy_tree(kit / "dbt_project" / "macros", out / "macros")
    n_tests = copy_tree(kit / "dbt_project" / "tests", out / "tests")

    case_dirs = sorted(p for p in (kit / "cases").iterdir() if (p / "case.json").exists())
    case_sources, case_blocks, model_files, model_case = [], [], {}, {}
    n_models = 0
    for case_dir in case_dirs:
        cfg = json.loads((case_dir / "case.json").read_text(encoding="utf-8"))
        case = case_dir.name
        models_dir = case_dir / "dbt" / "models"
        for sql in sorted(models_dir.rglob("*.sql")):
            if sql.stem in model_files:
                raise ValueError(f"Model {sql.stem} có ở cả {model_files[sql.stem]} và {sql}")
            model_files[sql.stem] = sql
        n_models += copy_tree(models_dir, out / "models")
        case_sources.append((case, parse_sources(case_dir / "dbt" / "sources.yml")))
        blocks = parse_schema(case_dir / "dbt" / "schema.yml")
        for block in blocks:
            if block["name"] in model_case:
                raise ValueError(f"Model {block['name']} khai trong schema.yml của cả {model_case[block['name']]} và {case}")
            model_case[block["name"]] = case
        case_blocks.append((case, cfg.get("title", case), blocks))

    write_text(out / "models" / "sources.yml", render_sources(merge_sources(case_sources), kit_rel))
    write_text(out / "models" / "schema.yml", render_schema(case_blocks, kit_rel))

    placeholders = [m for m in model_case if m not in model_files]
    for model in placeholders:
        write_text(out / "models" / LOCAL_DIR / f"{model}.sql", PLACEHOLDER.format(model=model, case=model_case[model]))
    missing = [m for m in model_files if m not in model_case]
    if missing:
        raise ValueError(f"Model chưa khai trong schema.yml: {', '.join(missing)}")
    return {"macros": n_macros, "tests": n_tests, "models": n_models, "placeholders": placeholders,
            "cases": [p.name for p in case_dirs]}


def diff_dirs(left, right):
    """Trả về danh sách đường dẫn tương đối khác nhau giữa hai cây thư mục."""
    files = set()
    for base in (left, right):
        for name in GENERATED:
            if (base / name).exists():
                files.update(p.relative_to(base).as_posix() for p in (base / name).rglob("*") if p.is_file())
    changed = []
    for rel in sorted(files):
        a, b = left / rel, right / rel
        if not a.exists() or not b.exists() or not filecmp.cmp(a, b, shallow=False):
            changed.append(rel)
    return changed


def main():
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Dựng dbt project của Airflow local từ bộ tài liệu dự án")
    parser.add_argument("--kit", type=Path, default=DEFAULT_KIT, help="thư mục bộ tài liệu (mặc định ../training)")
    parser.add_argument("--check", action="store_true", help="chỉ so với bản đang có, không ghi")
    args = parser.parse_args()
    kit = args.kit.resolve()
    if not (kit / "cases").is_dir() or not (kit / "dbt_project").is_dir():
        sys.exit(f"Không thấy bộ tài liệu tại {kit}")

    if args.check:
        with tempfile.TemporaryDirectory() as tmp:
            build(kit, Path(tmp))
            changed = diff_dirs(Path(tmp), PROJECT)
        if changed:
            print("dbt project khác bộ tài liệu, chạy lại tools/build_dbt_project.py:")
            for rel in changed:
                print(f"  {rel}")
            sys.exit(1)
        print("[ok] dbt project khớp bộ tài liệu")
        return

    info = build(kit, PROJECT)
    print(f"[ok] {PROJECT.relative_to(ROOT).as_posix()}: {info['models']} model, {info['macros']} macro, "
          f"{info['tests']} generic test, từ các case {', '.join(info['cases'])}")
    if info["placeholders"]:
        print(f"     model giữ chỗ (models/{LOCAL_DIR}/): {', '.join(info['placeholders'])}")
    print("     Sinh lại manifest: docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt parse")


if __name__ == "__main__":
    main()
