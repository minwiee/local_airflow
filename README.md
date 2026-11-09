# Airflow local của DWH: Airflow, dbt và Cosmos

Hai container: `postgres` và `airflow` (Airflow 2.10.5, scheduler LocalExecutor và webserver chạy chung một container). Airflow chạy 8 DAG interface của 4 yêu cầu DWH-101..104 (model dbt chạy qua Cosmos `DbtTaskGroup`), `mark_fail_running_dag` và `master_trigger_dag` của dự án, cùng 5 DAG demo. Kho dữ liệu là database `dwh` trong container `postgres`, nạp từ thư mục `warehouse/`: DDL và bộ dữ liệu kiểm thử 2 ngày (`2026-09-29`, `2026-09-30`) chép nguyên từ bộ tài liệu dự án (`../training/`). Môi trường chỉ có trên máy cá nhân, không kết nối kho dữ liệu DWH, AWS hay database điều khiển của SIT và production.

Vị trí trong kho mã nguồn: `dwh_onboarding/local_airflow/`, trong gói `dwh_onboarding/` ở gốc kho (cạnh `dags/`, `config/` của dự án), cùng cấp với `dwh_onboarding/training/` và `dwh_onboarding/de_airflow/`. Thư mục này chạy được một mình: `docker compose up` chỉ mount các thư mục bên trong `local_airflow/` (DDL và dữ liệu test của `dwh` nằm sẵn trong `warehouse/`), nên clone riêng `local_airflow/` cũng dựng đủ môi trường. `../training` chỉ cần khi sinh lại các phần chép từ bộ tài liệu: `tools/build_warehouse.py` (thư mục `warehouse/`) và `tools/build_dbt_project.py` (`dbt/dwh_project/models`, `macros`, `tests`), xem mục "Sinh lại manifest sau khi sửa model". `de_airflow/` build image với `../local_airflow/dbt/dwh_project`, nên trong gói vẫn giữ các thư mục cạnh nhau.

Tên bảng điều khiển giống tài liệu dự án: database `log_db` trong container `postgres` có schema `dwh_ctrl`, connection Airflow `postgres-dwh-ctrl`, `project_name = 'dwh'`.

## Thành phần

| Container | Image | Nội dung | Cổng trên máy |
| --- | --- | --- | --- |
| `postgres` | `postgres:16` | Database `airflow` (metadata của Airflow), `log_db` (bảng điều khiển), `dwh` (kho dữ liệu) | 5433 |
| `airflow` | `dwh-airflow-local:2.10.5`, build từ `Dockerfile` | Airflow 2.10.5 và astronomer-cosmos 1.15.1 trên Python 3.12 của image `apache/airflow:2.10.5`; dbt-core 1.10.23 và dbt-postgres 1.10.2 trong virtualenv `/opt/airflow/dbt_venv`, dựng bằng cùng Python 3.12; package dbt `godatadriven/dbt_date` 0.17.2 tải sẵn vào `/opt/airflow/dbt_packages` | 8080 |

Hai database của container `postgres` dùng cho hai việc khác nhau, và mỗi database có một schema `dwh_ctrl` riêng:

| Database | Connection Airflow | Nội dung |
| --- | --- | --- |
| `log_db` | `postgres-dwh-ctrl` | Schema `dwh_ctrl`: `log_etl_table`, `cstb_etl_waiting`, `cstb_job_run_list`, `cstb_etl_gen_flag`, `t24_holiday__fu`, `log_etl_table_history`, `task_instance`. Đây là database điều khiển, giống Postgres `log_db` của SIT và production: sensor, `get_tbls_data_date`, `log_insert_task`, `master_trigger_dag`, `mark_fail_running_dag` đọc và ghi ở đây. |
| `dwh` | `postgres-dwh-prd-db` (DAG L1), `postgres-bi-prd-db` (DAG layer 2) | Kho dữ liệu, dựng bằng các file SQL trong `warehouse/` (chép nguyên từ bộ tài liệu): schema nguồn `raw_eod`, `dwh_stag_eod`, `dwh_ref`; schema của model `dwh_stag`, `dwh_intf`, `bi_stag`, `bi_ref`, `bi_intf`; kết quả mong đợi `qa_expected`. Schema `dwh_ctrl` ở đây là của bộ tài liệu (ở môi trường dev, `dwh_ctrl` nằm chung database kho): bảng kịch bản test QA, hàm `dwh_ctrl.run_qa_automation` và bảng `log_etl_table` mà hàm này đọc. DAG không ghi vào bảng này; `tools/dwh_kit.py check` chép log của DAG từ `log_db` sang trước khi chạy test QA. |

Connection của Airflow (tạo lại mỗi lần container `airflow` khởi động):

| Connection | Database | Dùng ở |
| --- | --- | --- |
| `postgres-dwh-ctrl` | `log_db` | SqlSensor, `get_tbls_data_date`, `log_insert_task`, `master_trigger_dag`, `mark_fail_running_dag` |
| `postgres-dwh-prd-db` | `dwh` | Profile dbt (Cosmos) của 4 DAG L1 |
| `postgres-bi-prd-db` | `dwh` | Profile dbt (Cosmos) của 4 DAG layer 2 |

## Thư mục

| Thư mục | Nội dung | Trong container |
| --- | --- | --- |
| `project_dags/dwh_intf/` | 4 DAG interface L1: `branch_intf_dag`, `depo_intf_dag`, `loan_contract_intf_dag`, `card_intf_dag` | `/opt/airflow/dags/dwh_intf` |
| `project_dags/bu_intf_layer_2/bi/` | 4 DAG layer 2 của khối BI: `bi_branch_info_intf__mnp_dag`, `bi_depo_info_intf__mnp_dag`, `bi_lend_repay_info_intf__fa_dag`, `bi_card_info_intf__mnp_dag` | `/opt/airflow/dags/bu_intf_layer_2` |
| `project_dags/integration/` | `mark_fail_running_dag.py`, `master_trigger_dag.py`: cùng logic với `dags/integration/` của kho mã nguồn (Git) | `/opt/airflow/dags/integration` |
| `project_dags/utils/` | `utils.py`: hằng số `P_RETRIES`, `P_TIMEOUT`, `P_MAX_ACTIVE_RUN`, câu sensor `SQL_CHECK_EOD_LOG`, hàm Cosmos dùng chung `get_project_config`, `get_profile_config`, `get_execution_config`; `check_data_holiday.py` (`is_holiday`, `get_tables_data_date`, `get_pre_last_working_day`); `insert_log_dag.py` (`log_insert_dag`) | `/opt/airflow/dags/utils` |
| `dags/` | 5 DAG demo và `demo_log.py` (hàm ghi log cho DAG demo) | `/opt/airflow/dags/demo` |
| `dbt/dwh_project/` | dbt project. `dbt_project.yml`, `packages.yml` là phần riêng của Airflow local; `models/`, `macros/`, `tests/` do `tools/build_dbt_project.py` dựng từ `../training/`, đừng sửa tay | `/opt/airflow/dags/dbt/dwh_project` |
| `dbt/profiles/` | `profiles.yml` (profile `dwh`, target `prod`) cho lệnh dbt chạy tay | `/opt/airflow/dbt_profiles` |
| `tools/` | `build_dbt_project.py` và `build_warehouse.py` (chạy trên máy bằng Python 3.12: `py -3.12 tools\build_dbt_project.py`, `py -3.12 tools\build_warehouse.py`, chỉ khi bộ tài liệu `../training` thay đổi): dựng `dbt/dwh_project` và chép `warehouse/` từ bộ tài liệu; `dwh_kit.py` (chạy trong container): nạp lại dữ liệu test của một case, so kết quả với kết quả mong đợi và chạy test QA | `/opt/airflow/tools` |
| `initdb/` | Chạy khi volume postgres được tạo lần đầu: `01`, `02` tạo `log_db` và bảng điều khiển; `03_dwh_warehouse.sh` tạo `dwh` và nạp DDL, dữ liệu test từ `warehouse/`; `04_sensor_seed.sql` nạp cấu hình chờ nguồn và log nguồn đã về | `/docker-entrypoint-initdb.d` |
| `warehouse/` | DDL và dữ liệu test của database `dwh`: `ddl/` (schema, bảng `dwh_ctrl` của luồng QA, hàm chạy QA, hàm dùng chung, hai bảng cấu hình generic test của dbt) và `cases/<case>/` (`case.json`; `ddl/` tạo bảng; `data/` gồm dữ liệu test 2 ngày và kết quả mong đợi; `qa/` đăng ký test QA và nạp kết quả mong đợi). Chép nguyên từng byte từ bộ tài liệu bằng `tools/build_warehouse.py`, đừng sửa tay; xem `warehouse/README.md` | `/warehouse` (postgres), `/opt/airflow/warehouse` (airflow) |
| `Dockerfile` | Image `dwh-airflow-local:2.10.5` | |

Mọi thư mục mount chỉ đọc. Sửa file DAG trên máy thì Airflow tự nạp lại sau khoảng 30 giây; sửa model thì làm theo mục "Sinh lại manifest sau khi sửa model". Khi `dags/integration/mark_fail_running_dag.py` hay `master_trigger_dag.py` ở gốc kho mã nguồn (`../../dags/integration/` tính từ thư mục này) đổi logic, cập nhật bản trong `project_dags/integration/` theo.

## Chạy

Cần Docker Desktop đang chạy (góc dưới báo "Engine running"). Mở PowerShell tại thư mục `dwh_onboarding\local_airflow` của kho mã nguồn (từ gốc kho: `cd dwh_onboarding\local_airflow`); mọi lệnh `docker compose` trong README chạy tại thư mục này:

```powershell
docker compose up -d --build
```

Lần đầu mất khoảng 5 đến 10 phút để tải image và build: cài `astronomer-cosmos`, dbt và package `dbt_date` (bước này cần mạng). Từ lần sau image đã có, lệnh chạy trong khoảng 2 phút và DAG chạy không cần mạng. Khi volume postgres được tạo, `initdb/03_dwh_warehouse.sh` nạp database `dwh` từ `warehouse/` (xem log bằng `docker compose logs postgres`, các dòng `== dwh: ...`). Mỗi lần khởi động, container `airflow` tạo connection, chạy `dbt parse` để sinh `manifest.json` cho Cosmos rồi mới bật scheduler và webserver. Mở http://localhost:8080, đăng nhập `admin` / `admin`: trang DAGs có 15 DAG, không có lỗi import. `docker compose ps` báo cả hai container `(healthy)`: `postgres` sau khi `initdb/` nạp xong, `airflow` khi webserver trả lời `/health` và scheduler có heartbeat (khoảng 1 đến 2 phút sau khi container khởi động; trước đó cột STATUS ghi `health: starting`).

Dừng: `docker compose down -v`. Lần `up` sau là môi trường mới, log, lịch sử chạy và dữ liệu do DAG ghi không còn, database `dwh` được nạp lại từ `warehouse/`. `docker compose down` không có `-v` cũng cho môi trường mới ở lần `up` sau, nhưng để lại volume cũ của postgres (volume không tên, Docker không gắn lại), mỗi lần một volume chiếm chỗ trên ổ đĩa. Muốn giữ nguyên để làm tiếp hôm sau thì dùng `docker compose stop` rồi `docker compose start`. Log task và `dbt.log` nằm trong container `airflow`, không nằm trong volume. Mỗi lần container này được tạo lại (`docker compose up -d` sau khi sửa `docker-compose.yaml`, `docker compose up -d --build` sau khi sửa `Dockerfile`), log của các run cũ mất: Grid vẫn hiện run nhưng mở Logs không thấy log cũ. Cần xem log thì clear run để chạy lại. Sửa file trong `initdb/` thì phải chạy `docker compose down -v` rồi `docker compose up -d`, vì script trong `initdb/` chỉ chạy khi volume postgres được tạo mới. Sửa `Dockerfile` hoặc `dbt/dwh_project/packages.yml` thì chạy `docker compose up -d --build`.

Đưa môi trường về trạng thái ban đầu (xóa cả volume postgres):

```powershell
docker compose down -v
docker compose up -d
```

## Các DAG

### DAG interface (dbt qua Cosmos)

| DAG | Yêu cầu | Sensor (src_stm) | Nhóm dbt (`DbtTaskGroup`, chọn theo tag) | Bảng đích |
| --- | --- | --- | --- | --- |
| `branch_intf_dag` | DWH-101 | `waiting_for_t24` (`t24`) | `branch_intf_src_t24` (`tag:src_t24_branch_intf`: `vw_init_branch_intf_sap`, `stg_branch_intf_t24__snp`, `branch_intf`) → `branch_intf_test` | `dwh_intf.branch_intf` |
| `depo_intf_dag` | DWH-102 | `waiting_for_t24_ld` (`t24_ld`), `waiting_for_ar_x_cl_pst` (`ar_x_cl_pst`) | `transform_depo_intf_t24_ld`, `transform_depo_intf_ar_x_cl_pst` → `transform_depo_intf` (`tag:depo_intf_all`) → `depo_intf_test` | `dwh_intf.depo_intf` |
| `loan_contract_intf_dag` | DWH-103 | `waiting_for_t24_ld` (`t24_ld`), `waiting_for_bal_sheet` (`bal_sheet`) | `loan_contract_intf_src_ld` (`tag:src_ld_for_loan_contract_intf`) → `loan_contract_intf` (`tag:loan_contract_intf,tag:intf`) → `loan_contract_intf_test` | `dwh_intf.loan_contract_intf` |
| `card_intf_dag` | DWH-104 | `waiting_for_way4` (`way4`) | `card_intf_src_way4` (`tag:card_intf`) → `card_intf_test` | `dwh_intf.card_intf` |
| `bi_branch_info_intf__mnp_dag` | DWH-101 | `waiting_for_all` (`all`: `branch_intf_dag`) | `tfm_bi_branch_info__mnp` → `bi_branch_info_intf__mnp` → `bi_branch_info_intf__mnp_test` | `bi_intf.bi_branch_info_intf__mnp` |
| `bi_depo_info_intf__mnp_dag` | DWH-102 | `waiting_for_all` (`all`: `depo_intf_dag`) | `tfm_bi_depo_prfl__mnp` → `bi_depo_info_intf__mnp` → `bi_depo_info_intf__mnp_test` | `bi_intf.bi_depo_info_intf__mnp` |
| `bi_lend_repay_info_intf__fa_dag` | DWH-103 | `waiting_for_all` (`all`: `loan_contract_intf_dag`, `repay_acty_intf_dag`) | `bi_lend_repay_info_intf__fa` → `bi_lend_repay_info_intf__fa_test` | `bi_intf.bi_lend_repay_info_intf__fa` |
| `bi_card_info_intf__mnp_dag` | DWH-104 | `waiting_for_all` (`all`: `card_intf_dag`, `prd_intf_dag`) | `tfm_bi_card_info__mnp` (hai staging và bảng tfm) → `bi_card_info_intf__mnp` → `bi_card_info_intf__mnp_test` | `bi_intf.bi_card_info_intf__mnp` |

Mọi DAG interface đi theo khuôn DAG interface của dự án: `start_task` → TaskGroup `flow_ctrl` (`check_holiday`) → `get_tbls_data_date` (`trigger_rule='all_done'`, đẩy XCom `<dag_id>_tbls_data_date`) → SqlSensor `waiting_for_<nguồn>` chạy `SQL_CHECK_EOD_LOG` trên `postgres-dwh-ctrl` → `DbtTaskGroup` của từng nhóm nguồn → nhóm test `<intf>_test` (`TestBehavior.AFTER_ALL`) → `log_insert_task` → `pipeline_success`. Tham số chuẩn:

| Tham số | Giá trị |
| --- | --- |
| `retries`, `retry_delay` (default_args, mọi task kể cả task dbt) | `P_RETRIES` = 6, 30 giây |
| `log_insert_task` | `retries=10`, `retry_delay` 10 giây, `trigger_rule='all_done'`; ghi `success` (1) hoặc `failed` (3) vào `dwh_ctrl.log_etl_table`, `project_name = 'dwh'`; khi ghi failed thì task raise lỗi |
| SqlSensor | `mode='reschedule'`, `poke_interval=30`, `timeout=P_TIMEOUT` (24 giờ), `fail_on_empty=False` |
| `schedule_interval`, `catchup`, `max_active_runs`, `concurrency` | `None`, `False`, `P_MAX_ACTIVE_RUN` = 1, 10 |
| Ngày nghiệp vụ | `{{ dag_run.logical_date.astimezone(dag.timezone) \| ds }}`, truyền cho dbt qua `--vars` cùng `run_id` (`<dag_id>_<run_id>`) và `tbls_data_date` |
| dbt | `LoadMode.DBT_MANIFEST` (đọc `/opt/airflow/artifact/manifest.json`), `ExecutionConfig(dbt_executable_path='/opt/airflow/dbt_venv/bin/dbt')`, profile `dwh` target `prod` dựng từ connection, không chạy `dbt deps` |

`depo_intf_dag` truyền thêm biến `pre_last_wk_day` (ngày làm việc trước, cho nhánh hợp đồng tất toán): task `get_tbls_data_date` tính từ lịch `dwh_ctrl.t24_holiday__fu` của `log_db` và đẩy XCom `depo_intf_dag_pre_last_wk_day`. Kết quả: `2026-09-28` cho ngày 29, `2026-09-29` cho ngày 30.

Nhóm test chọn test bằng `tag:<tag của model>+1,resource_type:test` và `--indirect-selection cautious`. Lý do: generic test của dự án đọc thêm hai nguồn cấu hình (`dwh_ref.test_case_config`, `raw_eod.t24_holiday__snp`, qua macro `futils_test_should_run`), Cosmos lấy tag của test theo cha đầu tiên là nguồn nên `tag:branch_intf` không chọn được test nào; `+1` lấy các test là con trực tiếp của model mang tag, `cautious` để dbt không chạy thêm test của model layer 2 nằm dưới model đó.

### DAG điều khiển và DAG demo

| DAG | Cấu trúc | Dùng để thử |
| --- | --- | --- |
| `mark_fail_running_dag` | `get_dag_running_task` → `mark_fail_dag_task` → `insert_log_fail_task` | DAG cần test, trong `project_dags/integration/` |
| `master_trigger_dag` | 2 phút/lần trigger job trong bảng `dwh_ctrl.cstb_job_run_list` (mặc định trống) | Tương tác giữa master và mark fail (mục "Thử cùng master_trigger_dag") |
| `demo_branch_intf_dag` | task group `src_t24` (2 task), `src_way4` (1 task) → `merge_branch_task` → task group `test` (3 task); khoảng 20 phút | Task đang chạy trong task group, task chưa chạy |
| `demo_depo_intf_dag` | `SqlSensor` chờ nguồn (mode reschedule, poke 30 giây, timeout `P_TIMEOUT` 24 giờ) → task group `dbt_run`, `dbt_test` | Sensor đang chờ (up_for_reschedule) |
| `demo_card_intf_dag` | dynamic task mapping 8 phân vùng, chạy 3 phân vùng cùng lúc, mỗi phân vùng 5 phút | Task mapped (`map_index`) đang chạy và chưa chạy |
| `demo_retry_api_dag` | task luôn lỗi, retry 6 lần cách 30 giây; khoảng 3 phút sau khi trigger mới failed hẳn | Task đang chờ retry (up_for_retry): bật mark fail trong 3 phút đầu |
| `demo_quick_dag` | 4 task, xong trong khoảng 1 phút | DAG đã success không bị đụng tới |

Retry của DAG demo giống DAG interface, lấy hằng số từ `utils/utils.py`: `default_args` có `retries = P_RETRIES` (6) và `retry_delay = 30 giây`; `log_insert_task` có `retries=10`, `retry_delay=10 giây`, `trigger_rule='all_done'`; `max_active_runs = P_MAX_ACTIVE_RUN` (1).

Mỗi DAG demo có task đầu `start_log_task` ghi dòng processing (`status_flag = 0`) vào bảng `dwh_ctrl.log_etl_table`, như `master_trigger_dag` ghi trước khi trigger. Task cuối `log_insert_task` (trigger_rule all_done) ghi success (1) hoặc failed (3). DAG interface không có `start_log_task`, giống production: dòng processing do `master_trigger_dag` ghi. `mark_fail_running_dag` chỉ dừng những DAG đang có dòng processing.

## Chạy dbt qua Cosmos

`initdb/04_sensor_seed.sql` đã nạp vào `log_db` cấu hình chờ nguồn của 8 DAG interface và log `success` của mọi bảng nguồn (và của các DAG ngoài phạm vi `bal_sheet_detail_intf_dag`, `repay_acty_intf_dag`, `prd_intf_dag`, có dữ liệu nạp sẵn) cho cả hai ngày test, nên sensor của DAG L1 qua ngay. Sensor của DAG layer 2 chờ DAG L1 cùng ngày ghi `success`.

Trigger DAG L1 cho ngày 29, chờ xong, rồi tới DAG layer 2 của ngày 29; làm lại với ngày 30 (chạy từng lệnh dưới đây, chờ DAG của lệnh trước success). Ngày 29 phải chạy trước ngày 30: `card_intf` của ngày 30 đọc chính bảng `card_intf` của ngày 29 (trạng thái thẻ hết hạn ngày D+1). `max_active_runs = 1` nên run thứ hai của cùng DAG nằm queued tới khi run trước xong; DAG layer 2 trigger sớm thì sensor `waiting_for_all` chờ tới khi DAG L1 cùng ngày ghi `success`.

```powershell
docker compose exec airflow airflow dags trigger -e "2026-09-29T00:00:00+07:00" branch_intf_dag
docker compose exec airflow airflow dags trigger -e "2026-09-29T00:00:00+07:00" bi_branch_info_intf__mnp_dag
docker compose exec airflow airflow dags trigger -e "2026-09-30T00:00:00+07:00" branch_intf_dag
docker compose exec airflow airflow dags trigger -e "2026-09-30T00:00:00+07:00" bi_branch_info_intf__mnp_dag
```

Đổi `branch_intf_dag` / `bi_branch_info_intf__mnp_dag` thành `card_intf_dag` / `bi_card_info_intf__mnp_dag` hoặc `loan_contract_intf_dag` / `bi_lend_repay_info_intf__fa_dag` cho case 04 và 03. Case 02 (`depo_intf_dag`, `bi_depo_info_intf__mnp_dag`) chạy được với dữ liệu mặc định, nhưng muốn kết quả khớp kết quả mong đợi thì nạp dữ liệu của case 02 trước, xem mục "Nạp lại dữ liệu test của một case". Trên giao diện: nút ▶ → Trigger DAG w/ config, ô Logical date nhập `2026-09-29T00:00:00+07:00` (hoặc chọn ngày 29, 00:00 giờ Việt Nam trên lịch), Trigger; run có cùng run_id `manual__2026-09-29T00:00:00+07:00` như khi trigger bằng lệnh. Mục Trigger DAG (không có form) lấy logical date là giờ hiện tại, tức business date là hôm nay. `log_db` chỉ có log nguồn của 2026-09-29 và 2026-09-30, nên với hôm nay (hoặc bất kỳ ngày nào khác) sensor `waiting_for_<nguồn>` fail ngay ở lần kiểm đầu, không retry, log task ghi `AirflowFailException: Business date của run không có log nguồn nào trong dwh_ctrl.log_etl_table ...`; `log_insert_task` vẫn ghi `status_flag = 3` cho ngày đó. Trigger lại bằng Trigger DAG w/ config với Logical date đúng. Kiểm tra này chỉ có ở Airflow local (trong `project_dags/utils/utils.py`); sensor chỉ nằm chờ khi ngày đó có log nguồn nhưng còn thiếu bảng, như bài tập sensor chờ ở dưới. Run đang chờ như vậy giữ chỗ `max_active_runs = 1`, nên run sau của cùng DAG nằm `queued`, và `mark_fail_running_dag` không dừng nó vì `log_db` không có dòng processing cho DAG và ngày đó. Dừng bằng một trong hai cách: trên Grid bấm cột của run, chọn Mark state as… rồi failed; hoặc ghi dòng processing cho đúng `data_date` của run (lệnh ở mục "Mark fail một DAG interface đang chạy dbt", đổi `data_date` và `job_name`) rồi trigger `mark_fail_running_dag`. Xem trạng thái run bằng lệnh `docker compose exec airflow airflow dags state branch_intf_dag "2026-09-29T00:00:00+07:00"`.

Mỗi DAG L1 chạy trong khoảng 30 đến 60 giây, DAG layer 2 khoảng 20 đến 60 giây (cộng thời gian sensor chờ DAG L1). Trên tab Grid của `branch_intf_dag`:

| Task | Ý nghĩa |
| --- | --- |
| `start_task`, `flow_ctrl.check_holiday`, `get_tbls_data_date` | Đầu DAG; log của `get_tbls_data_date` in `table_name_json` là ngày dữ liệu của từng bảng nguồn |
| `waiting_for_t24` | Sensor; xanh ngọc (up_for_reschedule) khi nguồn chưa về |
| `branch_intf_src_t24.vw_init_branch_intf_sap_run`, `.stg_branch_intf_t24__snp_run`, `.branch_intf_run` | Mỗi model một task, Cosmos chạy `dbt run --select fqn:<model>`; thứ tự theo `ref()`: view và staging trước, `branch_intf` sau |
| `branch_intf_test.dwh_project_test` | Một task `dbt test` cho 4 generic test của `branch_intf` (`count_gte_zero`, `unique_value`, hai `not_null_value`) |
| `log_insert_task`, `pipeline_success` | Ghi log `success` (1) hoặc `failed` (3); `pipeline_success` chỉ xanh khi DAG không có task lỗi |

Log của dbt nằm ở hai chỗ:

- Log task trên giao diện (bấm ô của task, chọn Logs): dòng `Running command: [... 'run', '--select', 'fqn:dwh_project.bu_intf.branch_intf.branch_intf', '--vars', '{"business_date": "2026-09-29", ...}' ...]` là lệnh dbt đầy đủ, tiếp theo là output của dbt, ví dụ `OK created sql incremental model dwh_intf.branch_intf ... [INSERT 0 12]` hoặc `PASS count_gte_zero_branch_intf_business_date`. File log task nằm trong container ở `/opt/airflow/logs/dag_id=<dag>/run_id=<run>/task_id=<task>/attempt=<n>.log` (mất khi container được tạo lại, xem mục Chạy).
- File log của dbt (mọi lần chạy, cả từ DAG lẫn chạy tay): `docker compose exec airflow tail -n 100 /opt/airflow/logs/dbt/dbt.log`.

Mỗi lần chạy, dbt in một thông báo không ảnh hưởng kết quả: `This version of dbt is deprecated` (dbt 1.10 đã hết thời hạn hỗ trợ của nhà phát triển dbt). Ngoài dòng đó, dbt không in cảnh báo deprecation nào với dbt project này: `schema.yml` của case khai tham số generic test ở cấp trên (`filter_column: ...`), còn `tools/build_dbt_project.py` lồng các tham số đó dưới `arguments:` khi dựng `dbt/dwh_project/models/schema.yml` (cách khai dbt hỗ trợ từ 1.10.5), nên không có bảng `DeprecationsSummary` đếm `MissingArgumentsPropertyInGenericTestDeprecation`; tên test và task Cosmos không đổi. `dbt --version` báo `Update available!` cho dbt-core và dbt-postgres vì image ghim đúng bản 1.10 đã kiểm thử, không cần nâng.

Chạy lại một ngày đã chạy: trigger cùng logical date sẽ báo DagRun đã có, nên clear run cũ (giao diện: bấm cột của run trên Grid → Clear → Clear existing tasks; hoặc lệnh dưới). pre_hook của model xóa dữ liệu của ngày trước khi nạp lại nên số dòng không đổi.

```powershell
docker compose exec airflow airflow tasks clear branch_intf_dag -s "2026-09-29T00:00:00+07:00" -e "2026-09-29T00:00:00+07:00" -y
```

Bài tập cho sensor chờ: xóa log nguồn của một bảng Way4 ngày 30, trigger (hoặc clear) `card_intf_dag` cho ngày 30. `waiting_for_way4` nằm ở up_for_reschedule, log task in `Poking:` 30 giây/lần. Nạp lại dòng log (lệnh thứ hai), trong vòng 30 giây sensor success và các task dbt chạy tiếp.

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "delete from dwh_ctrl.log_etl_table where data_date = '2026-09-30' and job_name = 'eod|aws_bankwide|way4_contr_status__mnp'"
docker compose exec postgres psql -U airflow -d log_db -c "insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, start_time, end_time, status_name, status_flag) values ('2026-09-30', 'eod', 'eod|aws_bankwide|way4_contr_status__mnp', now(), now(), 'success', 1)"
```

Tương tự, trigger `bi_card_info_intf__mnp_dag` cho một ngày trước khi `card_intf_dag` của ngày đó chạy xong: `waiting_for_all` chờ tới khi `card_intf_dag` ghi `success`. Cấu hình chờ của từng DAG: `docker compose exec postgres psql -U airflow -d log_db -c "select job_name, src_stm, job_waiting from dwh_ctrl.cstb_etl_waiting order by 1, 2, 3"`.

## Sinh lại manifest sau khi sửa model

Bộ tài liệu dự án là nguồn duy nhất của model: sửa model, `sources.yml` hay `schema.yml` trong `../training/cases/<case>/dbt/`, macro hoặc generic test trong `../training/dbt_project/`, rồi tại thư mục `local_airflow` chạy:

```powershell
py -3.12 tools\build_dbt_project.py
docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt parse
```

Lệnh đầu dựng lại `dbt/dwh_project/models`, `macros`, `tests` bằng Python 3.12 của máy, chỉ dùng thư viện chuẩn. `py` là Python Launcher, cài cùng Python từ python.org; `py` không kèm số phiên bản chạy bản Python mới nhất đã cài trên máy (có thể là bản khác 3.12), nên lệnh ghi rõ `-3.12`; `py -0p` liệt kê các bản đang có. Trên Windows, lệnh `python` có thể chỉ là lối tắt mở Microsoft Store và báo `Python was not found`. Máy không có Python 3.12 thì chạy công cụ bằng Python 3.12 trong image Airflow (mount thư mục `local_airflow` và `../training` vào một container tạm; dòng thứ hai là `tools/build_warehouse.py` ở cuối mục này):

```powershell
docker compose run --rm --no-deps -v "${PWD}:/la" -v "${PWD}\..\training:/training:ro" --entrypoint python airflow /la/tools/build_dbt_project.py
docker compose run --rm --no-deps -v "${PWD}:/la" -v "${PWD}\..\training:/training:ro" --entrypoint python airflow /la/tools/build_warehouse.py
```

Lệnh `dbt parse` sinh lại `/opt/airflow/artifact/manifest.json`; scheduler parse lại file DAG trong khoảng 30 giây và Grid hiện task theo manifest mới. Task dbt chạy thẳng trên thư mục `dbt/dwh_project`, nên sửa câu SQL có hiệu lực ngay ở lần chạy sau; manifest quyết định task nào có trong DAG (model mới, tag, `ref()`), nên luôn sinh lại sau khi sửa. `py -3.12 tools\build_dbt_project.py --check` (hoặc thêm `--check` vào cuối lệnh `docker compose run` ở trên) báo file nào của `dbt/dwh_project` khác bộ tài liệu. Manifest cũng được sinh lại mỗi lần container `airflow` khởi động.

Nếu `dbt parse` báo lỗi, DAG có `DbtTaskGroup` vẫn dùng manifest cũ; sửa lỗi rồi parse lại. Khi manifest không có (lỗi ngay lúc khởi động), trang DAGs báo import error cho 8 DAG interface.

Bộ tài liệu cũng là nguồn của `warehouse/` (DDL, dữ liệu test, kết quả mong đợi, test QA của database `dwh`). Sửa DDL, CSV hay test QA của một case (hoặc `common/sql/`) trong `../training/`, sinh lại `sql/` của case bằng `tools/build_sql.py` của bộ tài liệu, rồi tại thư mục `local_airflow` chép lại `warehouse/` và nạp lại case vào `dwh`:

```powershell
py -3.12 tools\build_warehouse.py
docker compose exec airflow python /opt/airflow/tools/dwh_kit.py load <case>
```

`build_warehouse.py` chép đúng từng byte các file khác bộ tài liệu, tạo thư mục còn thiếu, xóa file của `warehouse/ddl/` và `warehouse/cases/` không còn trong bộ tài liệu, không đụng tới hai file viết tay `warehouse/README.md` và `warehouse/ddl/04_dbt_test_config.sql`. `py -3.12 tools\build_warehouse.py --check` (hoặc thêm `--check` vào cuối dòng thứ hai của lệnh `docker compose run` ở trên) chỉ so: in `[ok] warehouse khớp bộ tài liệu`, hoặc danh sách file thiếu, thừa, khác kèm mã lỗi 1 (khác biệt CRLF/LF không tính). Sau `load <case>` thì chạy lại DAG của case như mục "Nạp lại dữ liệu test của một case"; `dwh_kit.py check` luôn đọc test QA và kết quả mong đợi mới nhất trong `warehouse/`. Riêng `warehouse/ddl/` chỉ chạy lúc volume postgres được tạo, nên sửa phần đó thì `docker compose down -v` rồi `docker compose up -d`. Chi tiết trong `warehouse/README.md`.

## Chạy dbt CLI trong container

Container `airflow` đặt sẵn `DBT_PROJECT_DIR`, `DBT_PROFILES_DIR` (profile `dwh`, target `prod` trong `dbt/profiles/profiles.yml`, cùng database `dwh` với DAG) và `DBT_TARGET_PATH=/opt/airflow/artifact`, nên gọi dbt không cần thêm tham số đường dẫn:

```powershell
docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt debug
docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt ls --select tag:src_t24_branch_intf
docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt compile --select branch_intf --vars "{business_date: '2026-09-29', model_branch: T24_BANK_COMPANY}"
docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt run --select tag:src_t24_branch_intf --vars "{business_date: '2026-09-29', model_branch: T24_BANK_COMPANY}"
docker compose exec airflow /opt/airflow/dbt_venv/bin/dbt test --select "tag:branch_intf+1,resource_type:test" --indirect-selection cautious --vars "{business_date: '2026-09-29'}"
```

Câu SQL đã biên dịch nằm ở `/opt/airflow/artifact/compiled/dwh_project/models/...`, ví dụ `docker compose exec airflow cat /opt/airflow/artifact/compiled/dwh_project/models/bu_intf/branch_intf/branch_intf.sql`. `--vars` viết dạng YAML nháy đơn trong nháy kép, vì Windows PowerShell 5.1 làm mất dấu nháy kép bên trong dạng JSON. `business_date` không có giá trị mặc định: thiếu thì dbt báo lỗi thay vì chạy sai ngày. Model của `depo_intf` cần thêm `pre_last_wk_day` (`2026-09-28` cho ngày 29, `2026-09-29` cho ngày 30); `branch_intf` cần `model_branch: T24_BANK_COMPANY` để pre_hook chỉ xóa dòng T24 (để trống thì pre_hook xóa cả dòng của nguồn khác). dbt chạy tay ghi vào cùng bảng với DAG nhưng không ghi `log_etl_table`.

## Kiểm tra kết quả trong dwh

So bảng đích với kết quả mong đợi (`warehouse/cases/<case>/data/expected/`) và chạy test QA của các case, tại thư mục `local_airflow`:

```powershell
docker compose exec airflow python /opt/airflow/tools/dwh_kit.py check 01_branch 03_loan 04_card
```

Với từng case, công cụ chép log của DAG từ `log_db` sang `dwh_ctrl.log_etl_table` của database `dwh`, nạp lại test QA và kết quả mong đợi (`warehouse/cases/<case>/qa/*_register_qa_scripts.sql`, `qa/*_load_expected.sql`), so từng bảng đích theo từng ngày rồi chạy `dwh_ctrl.run_qa_automation` cho từng ngày. Phép so giống `sql/*_check_expected.sql` của bộ tài liệu nhưng bỏ cột `tf_run_id`: ba bảng layer 2 ghi `run_id` của Airflow (ví dụ `bi_branch_info_intf__mnp_dag_manual__2026-09-29T00:00:00+07:00`), còn kết quả mong đợi lấy từ luồng dev ghi `manual` (riêng `bi_depo_info_intf__mnp` ghi hằng `prod` ở cả hai nơi); công cụ in giá trị `tf_run_id` của bảng dưới mỗi dòng kết quả. Chạy nguyên `sql/*_check_expected.sql` của bộ tài liệu thì ba bảng layer 2 đó báo `fail` ở mọi dòng chỉ vì cột này. Kết quả đúng sau khi chạy đủ 8 DAG cho hai ngày:

| Bảng | 2026-09-29 | 2026-09-30 | Test QA (2 ngày) |
| --- | --- | --- | --- |
| `dwh_intf.branch_intf`, `bi_intf.bi_branch_info_intf__mnp` | 13, 11 | 10, 8 | case 01: 18/18 |
| `dwh_intf.depo_intf`, `bi_intf.bi_depo_info_intf__mnp` | 16, 13 | 10, 8 | case 02: 18/18 |
| `dwh_intf.loan_contract_intf`, `bi_intf.bi_lend_repay_info_intf__fa` | 15, 10 | 12, 8 | case 03: 20/20 |
| `dwh_intf.card_intf`, `bi_intf.bi_card_info_intf__mnp` | 4, 4 | 17, 16 | case 04: 20/20 |

Mỗi bảng mỗi ngày báo `pass` (không thừa, không thiếu dòng nào), tổng kết in `so với kết quả mong đợi: pass` và đủ số test QA. Bộ dữ liệu test nạp sẵn vài dòng vào bảng đích, cả L1 lẫn layer 2 (dòng của nguồn khác, của ngày khác như `2026-09-28` hoặc của lần chạy trước) để kiểm tra pre_hook xóa gì và giữ gì, xem README của case. Xem nhanh số dòng bằng `check_status.ps1` (bảng 4), hoặc:

```powershell
docker compose exec postgres psql -U airflow -d dwh -c "select business_date, src_sys_code, count(*) from dwh_intf.branch_intf group by 1, 2 order by 1, 2"
docker compose exec postgres psql -U airflow -d dwh -c "select out_testcase_id, out_test_result from dwh_ctrl.run_qa_automation('2026-09-30', 'TC04%')"
```

Câu thứ hai chạy test QA trực tiếp; nó chỉ chạy test của interface đã có log success trong `dwh_ctrl.log_etl_table` của `dwh`, nên chạy `dwh_kit.py check` trước một lần để chép log. Postgres mở cổng 5433 trên máy (user `airflow`, mật khẩu `airflow`, database `dwh` và `log_db`) nếu muốn xem bằng DBeaver hoặc pgAdmin.

### Nạp lại dữ liệu test của một case

Case 02 và 03 dùng chung ba bảng nguồn (`raw_eod.t24_ld_loans_and_depo__mnp`, `raw_eod.t24_ld_loans_and_depo_details__mnp`, `dwh_ref.csv_ma_map_cgy_ar_tp__mnp`), mỗi case nạp dữ liệu riêng. `initdb` nạp các case theo thứ tự tên, nên sau khi tạo volume các bảng này chứa dữ liệu của case 03, giống trạng thái sau `run_all.ps1` của bộ tài liệu. Với dữ liệu đó, `depo_intf_dag` vẫn chạy thành công (model staging tiền gửi lọc category tiền gửi trước khi ép kiểu ngày, nên ngày đáo hạn sai lịch `20270229` mà case 03 cố ý đưa vào hợp đồng cho vay không làm model lỗi), nhưng chỉ thấy dữ liệu của case 03, nên khác kết quả mong đợi của case 02 và test QA `TC02_*` không đạt hết. Muốn chạy case 02:

```powershell
docker compose exec airflow python /opt/airflow/tools/dwh_kit.py load 02_deposit
```

Lệnh chạy lại `warehouse/cases/02_deposit/ddl/01_create_tables.sql` và `warehouse/cases/02_deposit/data/02_load_test_data.sql` trong `dwh` (dựng lại bảng nguồn và bảng đích của case 02), rồi xóa log của `depo_intf_dag`, `bi_depo_info_intf__mnp_dag` cho hai ngày test trong `log_db`. Sau đó trigger `depo_intf_dag` và `bi_depo_info_intf__mnp_dag` cho ngày 29 rồi 30 (nếu DAG đã có run của ngày đó thì clear như mục trên) và chạy `dwh_kit.py check 02_deposit`. Bảng đích của case 03 vẫn giữ, nhưng test QA của case 03 đọc cả bảng nguồn nên sẽ fail cho tới khi `dwh_kit.py load 03_loan` và chạy lại DAG của case 03 (clear run ngày 29 của `loan_contract_intf_dag`, `bi_lend_repay_info_intf__fa_dag`, rồi run ngày 30). Ngược lại, sau `load 03_loan` thì bảng đích của case 02 vẫn đúng nhưng `dwh_kit.py check 02_deposit` báo test QA 10/18. Dùng `load` cũng để đưa một case về đúng dữ liệu test ban đầu.

## Test mark_fail_running_dag

1. Trigger các DAG demo trên giao diện (nút ▶). Chạy `demo_quick_dag` trước để nó kịp success.
2. Chờ 1–3 phút cho các task chạy lâu sang running, task retry sang up_for_retry, sensor sang up_for_reschedule.
3. Xem log trước khi dừng (mục "Xem và sửa log" bên dưới): các DAG demo đang chạy có `status_flag = 0`, `demo_quick_dag` có `status_flag = 1`.
4. Trigger `mark_fail_running_dag`.
5. Kết quả mong đợi:
    - Các DagRun demo đang chạy chuyển failed. Task đang chạy, chờ retry, chờ sensor và task chưa chạy chuyển failed. Task đã xong giữ nguyên trạng thái.
    - Dòng log của chúng chuyển `failed`, `status_flag = 3`, có `end_time`.
    - `demo_quick_dag` vẫn success, log vẫn `status_flag = 1`.
    - DagRun bị dừng và từng task bị chuyển failed có Note `Mark fail bởi mark_fail_running_dag lúc <giờ> (run <run_id>)` (tab Grid, mục Note ở khung Details); task đã xong và `demo_quick_dag` không có Note.
    - Vài phút sau, không task nào tự chạy lại và log không bị ghi đè sang success.

Thử thêm:

- Trigger `demo_branch_intf_dag` hai lần liên tiếp: lần sau nằm queued (`max_active_runs=1`), `mark_fail_running_dag` dừng cả hai.
- Trigger một DAG demo với logical date của ngày hôm qua (Trigger DAG w/ config, chọn ngày): dòng log có `data_date` hôm qua, `mark_fail_running_dag` vẫn tìm đúng DagRun.
- Thêm một dòng processing không có DagRun (lệnh bên dưới): `mark_fail_running_dag` in "Không tìm thấy DagRun" và vẫn ghi log failed cho dòng đó.
- Cho `demo_depo_intf_dag` chạy tiếp như bình thường: nạp dòng nguồn success (lệnh bên dưới), sensor qua trong vòng 30 giây.

### Mark fail một DAG interface đang chạy dbt

DAG interface không tự ghi dòng processing (production: `master_trigger_dag` ghi trước khi trigger). Khi trigger tay, ghi dòng đó như master rồi mới trigger, ví dụ cho `branch_intf_dag` ngày 29:

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, start_time, status_name, status_flag) values ('2026-09-29', 'dwh', 'branch_intf_dag', now(), 'processing', 0) on conflict (data_date, job_name, project_name) do update set status_flag = 0, status_name = 'processing', start_time = now(), end_time = null"
```

Run đã trigger mà chưa có dòng processing thì ghi dòng này sau cũng được: lần chạy `mark_fail_running_dag` kế tiếp vẫn tìm đúng DagRun theo `data_date`.

Task dbt của bộ dữ liệu test chỉ chạy vài giây. Muốn có đủ thời gian bật mark fail khi task dbt đang chạy, mở một cửa sổ PowerShell khác và giữ khóa bảng đích trong 3 phút: pre_hook của `branch_intf` (câu `delete`) chờ khóa nên task `branch_intf_src_t24.branch_intf_run` nằm ở running.

```powershell
docker compose exec postgres psql -U airflow -d dwh -c "begin; lock table dwh_intf.branch_intf in access exclusive mode; select pg_sleep(180); commit;"
```

Trigger (hoặc clear) `branch_intf_dag` cho ngày 29; khi `branch_intf_run` sang running thì trigger `mark_fail_running_dag`. Kết quả mong đợi: DagRun `manual__2026-09-29T00:00:00+07:00` failed và có Note `Mark fail bởi mark_fail_running_dag ...`, các task bị chuyển failed cũng có Note; task dbt đang chạy có `Received SIGTERM` trong log, `branch_intf_test.dwh_project_test`, `log_insert_task`, `pipeline_success` chuyển failed mà không chạy; dòng log `branch_intf_dag` ngày 29 chuyển `3 failed`. Bảng đích không đổi: dbt chưa kịp xóa hay nạp dòng nào. Chạy lại ngày 29 (clear) sau khi khóa hết hạn thì DAG success và log về `1`.

## Thử cùng master_trigger_dag

`master_trigger_dag` chạy 2 phút/lần. Bảng `dwh_ctrl.cstb_job_run_list` mặc định trống nên master không trigger gì. Để master tự chạy một DAG demo cho business date hôm nay:

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "insert into dwh_ctrl.t24_holiday__fu values (current_date, 'W', 'Y') on conflict (mth_day_no) do update set airflow_business_date_flag = 'Y'; insert into dwh_ctrl.cstb_job_run_list values ('dwh', 'demo_branch_intf_dag', 1, 99, 0); insert into dwh_ctrl.cstb_etl_gen_flag values ('dwh', 'demo_branch_intf_dag', 'all', now(), current_date)"
```

Master trigger với `run_id = manual__<ngày>T00:00:00+07:00` và `reset_dag_run=True`, và trigger lại mọi job mà log không ở trạng thái 0 hoặc 1. Kết quả đã chạy thử:

| Bước | Kết quả |
| --- | --- |
| Mark fail khi DAG do master trigger đang chạy | DagRun và task failed, log `3 failed` |
| Lần chạy kế tiếp của master (tối đa 2 phút sau) | Master trigger lại đúng run_id đó, reset DagRun, DAG chạy lại từ đầu, log quay về `0 processing` |
| Có từ 5 dòng `failed` (cột `checked` trống) trong bảng `dwh_ctrl.log_etl_table_history` cho job và ngày đó, rồi mark fail | Master không trigger lại, DAG giữ failed |

Thêm 5 dòng failed vào lịch sử cho job và ngày hôm nay:

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "insert into dwh_ctrl.log_etl_table_history (data_date, project_name, job_name, status_name, status_flag) select current_date, 'dwh', 'demo_branch_intf_dag', 'failed', 3 from generate_series(1, 5)"
```

Cho master chạy một DAG interface với business date `2026-09-29`: chỉ đặt cờ business date cho ngày đó, đăng ký job, và xóa log cũ của job cho ngày đó (master chỉ chọn job chưa có log 0 hoặc 1). Trong vòng 2 phút, master ghi dòng processing rồi trigger run `manual__2026-09-29T00:00:00+07:00`; nếu DAG đã có run đó (đã trigger tay trước đây) thì `reset_dag_run=True` cho run chạy lại từ đầu. Log đi từ `0 processing` sang `1 success` khi DAG xong, và master không trigger lại nữa.

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "update dwh_ctrl.t24_holiday__fu set airflow_business_date_flag = case when mth_day_no = '2026-09-29' then 'Y' else 'N' end; insert into dwh_ctrl.cstb_job_run_list values ('dwh', 'branch_intf_dag', 100, 99, 0); insert into dwh_ctrl.cstb_etl_gen_flag values ('dwh', 'branch_intf_dag', 'all', now(), '2026-09-29'); delete from dwh_ctrl.log_etl_table where data_date = '2026-09-29' and job_name = 'branch_intf_dag'"
```

Muốn master ngừng trigger một job: đặt `"enable"` khác 99 trong `dwh_ctrl.cstb_job_run_list`, hoặc pause `master_trigger_dag`. Dọn sau khi thử (lịch 26-30/09/2026 của bộ dữ liệu test được giữ, chỉ bỏ cờ business date):

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "delete from dwh_ctrl.cstb_job_run_list; delete from dwh_ctrl.cstb_etl_gen_flag; delete from dwh_ctrl.log_etl_table_history; delete from dwh_ctrl.t24_holiday__fu where mth_day_no not between '2026-09-26' and '2026-09-30'; update dwh_ctrl.t24_holiday__fu set airflow_business_date_flag = 'N'"
```

## Kiểm tra trạng thái

Xem nhanh bằng một lệnh, tại thư mục `local_airflow`:

```powershell
powershell -ExecutionPolicy Bypass -File .\check_status.ps1
```

Script in 6 bảng: 20 DagRun gần nhất trừ `master_trigger_dag`, run đang chạy hoặc queued lên đầu (bảng 1); số run của `master_trigger_dag` theo trạng thái (bảng 1b, vì DAG này chạy 2 phút/lần sẽ chiếm hết bảng 1); task của các DagRun ở bảng 1 gom theo trạng thái (bảng 2); dòng log của DAG trong `dwh_ctrl.log_etl_table` (bảng 3) và số dòng log còn lại (bảng nguồn, DAG ngoài phạm vi) đếm theo trạng thái (bảng 3b); số dòng của 8 bảng đích trong `dwh` theo hai ngày test (bảng 4).

Trên giao diện: trang DAGs, cột Runs có vòng tròn đếm số lần chạy theo màu (xanh lá success, đỏ failed, xanh nhạt running, xám queued). Bấm vào DAG, tab Grid, mỗi cột là một DagRun và mỗi ô là một task (vàng up_for_retry, xanh ngọc up_for_reschedule, nâu nhạt scheduled). Bấm vào ô rồi chọn Logs để xem log của task.

`mark_fail_running_dag` chạy đúng khi đủ 5 điều:

| Kiểm tra | Đúng khi | Xem ở đâu |
| --- | --- | --- |
| DAG tự chạy xong | 3 task của `mark_fail_running_dag` đều success | Grid của `mark_fail_running_dag` |
| Dừng đúng DagRun | Mọi DagRun running hoặc queued của DAG có dòng processing (cùng `data_date`) chuyển failed; task đã xong giữ trạng thái cũ; task đang chạy, chờ retry, chờ sensor, chưa chạy chuyển failed | Bảng 1, 2 của `check_status.ps1`; log task `mark_fail_dag_task` (dòng `Mark fail dag_id=...` và `<task> (map_index=-1): running -> failed`, task mapped có `map_index` từ 0) |
| Có đánh dấu mark fail | DagRun và từng task bị chuyển failed có Note `Mark fail bởi mark_fail_running_dag lúc <giờ> (run <run_id của mark fail>)`; task đã xong từ trước không có Note. DAG tự lỗi thì không có Note này | Tab Grid: bấm cột DagRun hoặc ô task, mục Note ở khung Details |
| Task dừng hẳn | Log của task đang chạy có `State of this instance has been externally set to failed. Terminating instance` và `Received SIGTERM`; vài phút sau task không chạy lại | Logs của task đó trên giao diện |
| Ghi log đúng | Dòng đang processing (0) chuyển `failed` (3), có `end_time` bằng giờ chạy mark fail; dòng success, dòng `eod`, dòng cấp bảng (không có `_dag`) giữ nguyên | Bảng 3 và 3b của `check_status.ps1`; log task `insert_log_fail_task` (`Đã insert log failed` hoặc `Bỏ qua`) |

Nên chạy `check_status.ps1` một lần trước khi bật `mark_fail_running_dag` để ghi nhận dòng nào đang processing, rồi chạy lại sau khi nó xong để so.

## Xem và sửa log

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "select data_date, project_name, job_name, status_flag, status_name, start_time, end_time from dwh_ctrl.log_etl_table where job_name ~ '_dag' order by data_date, job_name"
```

Thêm dòng processing không có DagRun:

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, start_time, status_name, status_flag) values (current_date, 'dwh', 'abc_dag', now(), 'processing', 0)"
```

Cho sensor của `demo_depo_intf_dag` qua:

```powershell
docker compose exec postgres psql -U airflow -d log_db -c "insert into dwh_ctrl.log_etl_table (data_date, project_name, job_name, status_name, status_flag) values (current_date, 'eod', 'demo_t24_ld', 'success', 1)"
```

## Lưu ý

- `on_failure_callback` trong `utils/utils.py` của Airflow local chỉ in một dòng log khi DAG lỗi. Bản production gửi thông báo cho nhóm qua AWS, môi trường local không có kết nối đó.
- `dwh_ctrl.cstb_etl_waiting` của `log_db` có cấu hình chờ của 8 DAG interface (nạp bởi `initdb/04_sensor_seed.sql`, cấu hình của `branch_intf_dag` lấy theo `cases/01_branch/ctrl/dependency_and_sensor.sql`). `demo_depo_intf_dag` vẫn dùng câu sensor riêng, chờ dòng `eod` / `demo_t24_ld` success.
- `log_db` chạy theo giờ Việt Nam, nên `current_date` trong các lệnh trên trùng `data_date` của DAG trigger hôm nay. Database `dwh` đặt timezone UTC, vì `dbt_date.convert_timezone` trên PostgreSQL coi giờ của phiên là UTC rồi đổi sang giờ Việt Nam (cột `ppn_date`); trong `docker compose exec postgres psql` phiên vẫn theo giờ Việt Nam (biến `PGTZ` của container).
- DAG interface của Airflow local không gọi `DynamicTaskDependency` (cuối file DAG production, đọc `dags/dag_dependencies.yaml`): DAG layer 2 chờ DAG L1 qua sensor `waiting_for_all` và `cstb_etl_waiting`. `DummyOperator` của khuôn production viết là `EmptyOperator` (cùng lớp trong Airflow 2.10, tên cũ đã deprecated).
- `get_project_config` trong `utils/utils.py` đặt `DBT_TARGET_PATH = "target"` cho task dbt, khác giá trị `/tmp/cosmos_cache` của production: mỗi task ghi `run_results.json` và file compile vào bản sao tạm của dbt project mà Cosmos tạo riêng cho task. Ở Airflow local mọi task chạy chung một container, nếu dùng chung một thư mục thì hai task dbt chạy song song (ví dụ `vw_init_branch_intf_sap_run` và `stg_branch_intf_t24__snp_run`) đọc nhầm kết quả của nhau, Cosmos ghi dataset sai model và một task lỗi `UniqueViolation ... idx_uri_unique` rồi phải retry.
- Model trong `dbt/dwh_project/models/ngoai_pham_vi/` là model giữ chỗ cho bảng do DAG khác dựng (`dwh_ref.tfm_re_crf_sbv__mnp`, `dwh_intf.repay_acty_intf`, `dwh_intf.prd_intf`): bộ tài liệu khai chúng trong `schema.yml` và đọc bằng `ref()`, các model này đã có trong dbt project trung tâm nên bộ tài liệu không mang theo file `.sql`. Dữ liệu của các bảng này nạp sẵn từ bộ dữ liệu test. Tương tự, `models/sources.yml` khai thêm hai nguồn mà generic test đọc (`dwh_ref.test_case_config`, `raw_eod.t24_holiday__snp`); hai bảng này để trống nên mọi test đều bật.
- Container `postgres` báo healthy bằng `pg_isready -h 127.0.0.1` (qua TCP), nên container `airflow` chỉ khởi động sau khi `initdb/` nạp xong `log_db` và `dwh`. Container `airflow` báo healthy khi `curl http://localhost:8080/health` trong container trả scheduler `healthy` (kiểm tra 30 giây/lần; lần kiểm tra lỗi trong 3 phút đầu không bị tính). Trên giao diện, nút ▶ luôn có menu Trigger DAG / Trigger DAG w/ config (biến `AIRFLOW__WEBSERVER__SHOW_TRIGGER_FORM_IF_NO_PARAMS`).
- Image tắt số liệu sử dụng gửi ra ngoài của Cosmos, Airflow và dbt; sau khi build, DAG chạy không cần mạng (đã chạy thử `card_intf_dag` với container `airflow` không có đường ra Internet).
- Trong `docker compose logs postgres`, vài dòng `ERROR: relation "connection" does not exist` (hoặc `ab_user`, `log`) lúc Airflow khởi động lần đầu là bình thường: Airflow dò bảng trước khi `airflow db migrate` tạo xong.
- Tài khoản `airflow` / `airflow` và `admin` / `admin` chỉ dùng cho môi trường local.
