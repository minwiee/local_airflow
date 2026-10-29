# Xem nhanh trạng thái DagRun, task và bảng dwh_ctrl.log_etl_table của Airflow local.
# Chạy tại thư mục dwh_onboarding\local_airflow:
#   powershell -ExecutionPolicy Bypass -File .\check_status.ps1
Set-Location $PSScriptRoot
docker compose cp .\check_status.sql postgres:/tmp/check_status.sql | Out-Null
docker compose exec -T postgres psql -U airflow -d airflow -P pager=off -f /tmp/check_status.sql
