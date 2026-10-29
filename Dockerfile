# ---------------------------------------------------------------------------
# Image Airflow local của DWH: Airflow 2.10.5 + astronomer-cosmos + dbt-postgres
# ---------------------------------------------------------------------------
# - astronomer-cosmos cài vào môi trường Python của Airflow. Ghim apache-airflow==2.10.5
#   trong cùng lệnh pip để pip không tự nâng Airflow khi giải phụ thuộc.
# - dbt-core và dbt-postgres 1.10 cài trong virtualenv riêng /opt/airflow/dbt_venv
#   (khuyến nghị của Cosmos), tránh xung đột thư viện với Airflow. Cosmos gọi
#   /opt/airflow/dbt_venv/bin/dbt qua ExecutionConfig(dbt_executable_path=...).
# - Package dbt (dbt_date) tải một lần lúc build vào /opt/airflow/dbt_packages, nên DAG
#   chạy dbt không cần mạng. Đổi packages.yml thì build lại image.
# Build: docker compose build (hoặc docker compose up -d --build).
# ---------------------------------------------------------------------------
FROM apache/airflow:2.10.5

# git cho lệnh "dbt debug" (bước kiểm tra phụ thuộc); dbt deps tải package từ dbt hub không cần git
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
USER airflow

ARG COSMOS_VERSION=1.15.1
# Ghim đúng bản đã kiểm thử với bộ tài liệu (README, mục Thành phần)
ARG DBT_CORE_SPEC="dbt-core==1.10.23"
ARG DBT_POSTGRES_SPEC="dbt-postgres==1.10.2"

# Cosmos trong môi trường của Airflow (image chạy pip với user airflow, cài vào ~/.local)
RUN pip install --no-cache-dir "apache-airflow==2.10.5" "astronomer-cosmos==${COSMOS_VERSION}"

# dbt trong virtualenv riêng. PIP_USER=false vì image Airflow bật PIP_USER, pip trong venv sẽ báo lỗi.
RUN python -m venv /opt/airflow/dbt_venv \
 && PIP_USER=false /opt/airflow/dbt_venv/bin/pip install --no-cache-dir --upgrade pip \
 && PIP_USER=false /opt/airflow/dbt_venv/bin/pip install --no-cache-dir "${DBT_CORE_SPEC}" "${DBT_POSTGRES_SPEC}" \
 && /opt/airflow/dbt_venv/bin/dbt --version

# Tải package dbt vào đường dẫn cố định ngoài thư mục dbt project (thư mục project được mount từ máy)
ENV DBT_PACKAGES_INSTALL_PATH=/opt/airflow/dbt_packages \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false
COPY --chown=airflow:root dbt/dwh_project/dbt_project.yml dbt/dwh_project/packages.yml /tmp/dbt_deps/
RUN cd /tmp/dbt_deps \
 && /opt/airflow/dbt_venv/bin/dbt deps --project-dir /tmp/dbt_deps \
 && ls /opt/airflow/dbt_packages \
 && rm -rf /tmp/dbt_deps

# Thư mục chứa manifest.json do "dbt parse" sinh ra khi container khởi động (xem docker-compose.yaml)
RUN mkdir -p /opt/airflow/artifact
