# warehouse · DDL và dữ liệu test của database dwh

Thư mục này chứa mọi file để dựng database `dwh` (kho dữ liệu) của Airflow local: DDL, dữ liệu test của hai ngày `2026-09-29` và `2026-09-30`, kết quả mong đợi và test QA của 4 case DWH-101..104. Các file được chép nguyên từng byte từ bộ tài liệu dự án (`dwh_onboarding/training/`, tức `../training` tính từ `local_airflow/`) bằng `tools/build_warehouse.py`. Nhờ vậy `docker compose up` chỉ cần thư mục `local_airflow/`, không đọc gì bên ngoài: clone riêng `local_airflow/` cũng dựng được `dwh`.

## Ai đọc thư mục này

| Ai đọc | Mount trong container | Đọc gì |
| --- | --- | --- |
| `initdb/03_dwh_warehouse.sh` (container `postgres`, chỉ chạy khi volume postgres được tạo lần đầu) | `/warehouse` | `ddl/*.sql` và các file của từng case, theo thứ tự ở mục "Thứ tự nạp" |
| `tools/dwh_kit.py` (container `airflow`) | `/opt/airflow/warehouse` | `load <case>`: `ddl/01_create_tables.sql`, `data/02_load_test_data.sql` của case; `check`: `case.json`, `qa/*.sql`, `data/expected/*.csv` |

Cả hai mount chỉ đọc. Sửa file trên máy thì `dwh_kit.py` thấy ngay ở lần chạy sau; `initdb` chỉ chạy lại khi volume postgres được tạo mới.

## Cấu trúc

```
warehouse/
├── README.md                          file này (viết tay)
├── ddl/
│   ├── 00_schemas.sql                 schema của kho                                  ← common/sql/00_schemas.sql
│   ├── 01_ctrl_tables.sql             bảng dwh_ctrl của luồng QA                      ← common/sql/01_ctrl_tables.sql
│   ├── 02_qa_runner.sql               hàm dwh_ctrl.run_qa_automation                  ← common/sql/02_qa_runner.sql
│   ├── 03_functions.sql               hàm public.months_between, public.last_day      ← common/sql/03_functions.sql
│   └── 04_dbt_test_config.sql         hai bảng cấu hình generic test của dbt, trống  (viết tay)
└── cases/<case>/                      01_branch, 02_deposit, 03_loan, 04_card
    ├── case.json                      ngày test, DAG, bảng đích, cột ngày để so      ← case.json
    ├── ddl/01_create_tables.sql       tạo bảng nguồn và bảng đích của case            ← sql/01_create_tables.sql
    ├── data/02_load_test_data.sql     dữ liệu test của cả 2 ngày (INSERT)             ← sql/02_load_test_data.sql
    ├── data/expected/*.csv            kết quả mong đợi, dwh_kit.py check so với nó    ← data/expected/*.csv
    └── qa/
        ├── 05_register_qa_scripts.sql đăng ký test QA                                 ← sql/05_register_qa_scripts.sql
        └── 06_load_expected.sql       nạp kết quả mong đợi vào schema qa_expected     ← sql/06_load_expected.sql
```

Cột bên phải là file nguồn trong bộ tài liệu: `common/sql/` của bộ tài liệu, hoặc thư mục `cases/<case>/` của case. File trong `qa/` giữ nguyên tên trong bộ tài liệu (số thứ tự `05`, `06` của case).

`04_dbt_test_config.sql` tạo `dwh_ref.test_case_config` và `raw_eod.t24_holiday__snp`: macro `futils_test_should_run` của generic test đọc hai bảng này. dbt project trung tâm đã có chúng, bộ tài liệu thì không, nên Airflow local tự tạo và để trống (mọi test đều bật, không có ngày nghỉ).

Không có trong `warehouse/`: `sql/03_run_*.sql`, `04_run_*.sql` của bộ tài liệu (luồng dev; ở Airflow local, dbt chạy model qua DAG) và `*_check_expected.sql` (`dwh_kit.py check` làm việc so sánh, không so cột `tf_run_id`).

## Thứ tự nạp

`initdb/03_dwh_warehouse.sh` dựng `dwh` theo thứ tự:

1. Tạo database `dwh` (`UTF8`, `template0`) và đặt timezone `UTC`.
2. `ddl/*.sql` theo tên, từ `00_schemas.sql` tới `04_dbt_test_config.sql`.
3. Từng thư mục trong `cases/` có `case.json`, theo tên thư mục: `ddl/01_create_tables.sql` → `data/02_load_test_data.sql` → `qa/*_register_qa_scripts.sql` → `qa/*_load_expected.sql`.

Lỗi ở bất kỳ file nào (hoặc thiếu file) thì script dừng và container `postgres` báo lỗi, không chạy với kho thiếu dữ liệu. Xem các bước đã chạy bằng `docker compose logs postgres` (các dòng `== dwh: ...`).

## Case 02 và 03

Case `02_deposit` và `03_loan` dùng chung ba bảng nguồn: hai bảng T24 LD và file map category (`raw_eod.t24_ld_loans_and_depo__mnp`, `raw_eod.t24_ld_loans_and_depo_details__mnp`, `dwh_ref.csv_ma_map_cgy_ar_tp__mnp`). Case nạp sau là `03_loan`, nên sau khi tạo volume các bảng này chứa dữ liệu của case 03, giống trạng thái sau `run_all.ps1` của bộ tài liệu. Muốn chạy case 02 thì nạp lại case đó:

```powershell
docker compose exec airflow python /opt/airflow/tools/dwh_kit.py load 02_deposit
```

Các bước tiếp theo nằm ở README của `local_airflow`, mục "Nạp lại dữ liệu test của một case".

## Sinh lại khi bộ tài liệu thay đổi

Đừng sửa tay các file chép từ bộ tài liệu (mọi file trừ `README.md` và `ddl/04_dbt_test_config.sql`). Sửa DDL, CSV hay test trong bộ tài liệu, sinh lại `sql/` của case bằng `tools/build_sql.py` của bộ tài liệu, rồi tại thư mục `local_airflow` chạy:

```powershell
py -3.12 tools\build_warehouse.py
py -3.12 tools\build_warehouse.py --check
```

- Lệnh đầu chép lại file khác bộ tài liệu (đúng từng byte), tạo thư mục còn thiếu và xóa file trong `ddl/` (`*.sql`) hay `cases/` không còn trong bộ tài liệu. Thư mục case không có `case.json` bị bỏ qua. `README.md` và `ddl/04_dbt_test_config.sql` không bị đụng tới.
- `--check` chỉ so, không ghi: in `[ok] warehouse khớp bộ tài liệu`, hoặc danh sách file thiếu, thừa, khác kèm mã lỗi 1. Khác biệt xuống dòng (CRLF/LF) không tính.
- Công cụ cần bộ tài liệu ở `../training` (hoặc chỉ đường bằng `--kit <thư mục>`). Clone riêng `local_airflow/` thì công cụ báo không thấy bộ tài liệu, nhưng `docker compose up` vẫn chạy bình thường vì không cần công cụ này.

Máy không có Python 3.12 thì chạy bằng Python 3.12 trong image Airflow, giống lệnh của `tools/build_dbt_project.py` trong README của `local_airflow`:

```powershell
docker compose run --rm --no-deps -v "${PWD}:/la" -v "${PWD}\..\training:/training:ro" --entrypoint python airflow /la/tools/build_warehouse.py
```

Đưa thay đổi vào database `dwh` đang chạy:

- DDL, dữ liệu test của một case: `docker compose exec airflow python /opt/airflow/tools/dwh_kit.py load <case>`, rồi chạy lại DAG của case. `dwh_kit.py check` luôn đọc `qa/` và `data/expected/` mới nhất.
- `ddl/` (DDL dùng chung): chỉ chạy khi volume postgres được tạo, nên chạy `docker compose down -v` rồi `docker compose up -d` (môi trường mới, mất log và lịch sử chạy).

## Xuống dòng

File SQL sinh sẵn trong `sql/` của bộ tài liệu dùng CRLF; `common/sql/`, `case.json` và CSV dùng LF. `psql` đọc được cả hai. `.gitattributes` của `local_airflow` có dòng `warehouse/** -text`, nên Git không đổi xuống dòng của các file ở đây: file trong Git và trên máy giữ đúng từng byte như bộ tài liệu.
