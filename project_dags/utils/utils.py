#----------------------------------------------------------------------
# Module        : utils (bản cho Airflow local)
# Mô tả         : Hằng số và hàm dùng chung của các DAG, theo dags/utils/utils.py
#                 của kho mã nguồn (Git). Chỉ giữ phần các DAG trên Airflow local dùng tới.
#                 Khác bản production:
#                 - on_failure_callback chỉ ghi log, không gửi thông báo;
#                 - dbt project, manifest và dbt là bản của Airflow local (dbt/dwh_project,
#                   /opt/airflow/artifact/manifest.json, /opt/airflow/dbt_venv/bin/dbt);
#                 - profile dbt dựng từ connection PostgreSQL trỏ vào database dwh của container postgres;
#                 - sensor chờ nguồn báo lỗi ngay khi business date không có log nguồn nào
#                   (dữ liệu test chỉ có 2026-09-29 và 2026-09-30), thay vì chờ hết P_TIMEOUT.
#----------------------------------------------------------------------

from airflow.exceptions import AirflowFailException
from airflow.models import Variable
from cosmos import ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.constants import TestIndirectSelection
from cosmos.profiles import PostgresUserPasswordProfileMapping

P_TIMEOUT = 86400
P_RETRIES = 6
P_MAX_ACTIVE_RUN = 1
P_MAX_CONCURRENCY = 50

# dbt của Airflow local (xem Dockerfile và docker-compose.yaml)
DBT_PROJECT_PATH = "/opt/airflow/dags/dbt/dwh_project"
DBT_MANIFEST_PATH = "/opt/airflow/artifact/manifest.json"   # sinh bằng dbt parse khi container khởi động
DBT_EXECUTABLE_PATH = "/opt/airflow/dbt_venv/bin/dbt"       # dbt-core, dbt-postgres 1.10 trong virtualenv riêng

# Câu của SqlSensor chờ nguồn: true khi mọi job_waiting của DAG (khớp prefix src_stm) đã có log success.
# Riêng Airflow local: trả NULL khi business date không có dòng log nguồn (project eod) nào, để
# _success_criteria báo lỗi ngay thay vì chờ tới P_TIMEOUT cho một ngày không có dữ liệu test.
SQL_CHECK_EOD_LOG = """
            with table_unready as(
                select count(distinct a.job_name) as num_unready
                from dwh_ctrl.cstb_etl_waiting a
                left join dwh_ctrl.log_etl_table b on a.job_waiting = b.job_name and b.data_date = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}' and b.status_name = 'success'
                where a.job_name || '_' || (case when src_stm = 'all' then '' else src_stm end) in ('{{ dag.dag_id }}' || '{{ params.prefix }}') and lower(a.status) = 'a' and b.job_name is null
            ), test_data as (
                select exists (
                    select 1 from dwh_ctrl.log_etl_table
                    where project_name = 'eod' and data_date = '{{ dag_run.logical_date.astimezone(dag.timezone) | ds }}'
                ) as has_source_log
            )
            select case when not test_data.has_source_log then null
                        when num_unready = 0 then true else false end
            from table_unready, test_data
        """


def get_airflow_var(key, default_value):
    return Variable.get(key, default_var=default_value)


def on_failure_callback(context):
    # Production gửi thông báo DAG lỗi cho nhóm; Airflow local chỉ ghi một dòng log
    print(f"DAG {context['dag'].dag_id} failed (Airflow local: không gửi thông báo)")


def _success_criteria(record):
    if record is None:
        # AirflowFailException: task fail ngay, không retry; log_insert_task vẫn ghi status_flag 3
        raise AirflowFailException(
            "Business date của run không có log nguồn nào trong dwh_ctrl.log_etl_table: dữ liệu test "
            "chỉ có ngày 2026-09-29 và 2026-09-30. Trigger lại bằng 'Trigger DAG w/ config' với Logical "
            "date 2026-09-29T00:00:00+07:00 hoặc 2026-09-30T00:00:00+07:00."
        )
    return record


def get_project_config(
    dbt_project_path: str = DBT_PROJECT_PATH,
    manifest_path: str = DBT_MANIFEST_PATH,
    partial_parse: bool = False,
) -> ProjectConfig:
    """ProjectConfig dùng chung cho các DAG gọi dbt qua Cosmos.

    - partial_parse=False: Cosmos chạy dbt với --no-partial-parse, các task chạy song song
      không đọc chung một file partial_parse.msgpack.
    - install_dbt_deps=False: package dbt (dbt_date) đã có sẵn trong image tại
      /opt/airflow/dbt_packages, task không chạy dbt deps nên không cần mạng.
    - env_vars: DBT_STATIC_PARSER bật static parser của dbt-core. DBT_TARGET_PATH = "target"
      (đường dẫn tương đối): mỗi task dbt ghi file compile, run_results.json vào thư mục
      target trong bản sao tạm của dbt project mà Cosmos tạo riêng cho task đó, không đè
      manifest /opt/airflow/artifact/manifest.json (biến DBT_TARGET_PATH của container dùng
      cho dbt chạy tay). Production đặt /tmp/cosmos_cache vì mỗi task chạy trên worker riêng;
      ở Airflow local mọi task chạy chung một container (LocalExecutor), dùng chung một thư mục
      thì task chạy song song đọc nhầm run_results.json của nhau: Cosmos ghi dataset sai model
      và hai task cùng tạo một dataset, task sau lỗi UniqueViolation (idx_uri_unique) rồi retry.
    """
    return ProjectConfig(
        dbt_project_path=dbt_project_path,
        partial_parse=partial_parse,
        manifest_path=manifest_path,
        install_dbt_deps=False,
        env_vars={
            "DBT_STATIC_PARSER": "True",
            "DBT_TARGET_PATH": "target",
        },
    )


def get_profile_config(conn_id: str) -> ProfileConfig:
    """ProfileConfig PostgreSQL dựng từ Airflow connection postgres-* (schema của connection là tên database).

    Target "prod": generate_schema_name_for_env ghi model vào đúng schema khai trong schema.yml.
    """
    return ProfileConfig(
        profile_name="dwh",
        target_name="prod",
        profile_mapping=PostgresUserPasswordProfileMapping(
            conn_id=conn_id,
            profile_args={"schema": "public"},
        ),
    )


def get_execution_config(
    test_indirect_selection: TestIndirectSelection = TestIndirectSelection.EAGER,
) -> ExecutionConfig:
    """ExecutionConfig dùng chung: dbt trong virtualenv của image Airflow local.

    Nhóm test của DAG truyền TestIndirectSelection.CAUTIOUS (xem chú thích ở nhóm test trong DAG).
    """
    return ExecutionConfig(
        dbt_executable_path=DBT_EXECUTABLE_PATH,
        test_indirect_selection=test_indirect_selection,
    )
