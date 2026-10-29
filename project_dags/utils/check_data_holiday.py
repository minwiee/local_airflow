#----------------------------------------------------------------------
# Module        : check_data_holiday (bản cho Airflow local)
# Mô tả         : Hàm của nhóm flow_ctrl và task get_tbls_data_date trong DAG interface,
#                 theo dags/utils/check_data_holiday.py của kho mã nguồn (Git). Đọc bảng điều
#                 khiển dwh_ctrl trên log_db qua connection postgres-dwh-ctrl.
#                 Thêm get_pre_last_working_day cho biến pre_last_wk_day của depo_intf_dag.
#----------------------------------------------------------------------
import traceback
from datetime import date, timedelta

from airflow.providers.postgres.hooks.postgres import PostgresHook

CTRL_CONN_ID = "postgres-dwh-ctrl"


def is_holiday(data_date):
    """ShortCircuitOperator check_holiday: giống production, luôn trả True (DAG chạy cả ngày nghỉ).

    Ngày nghỉ xử lý qua cstb_job_run_list.holiday = 1 và ngày dữ liệu riêng của từng bảng (tbls_data_date).
    """
    print(f"check holiday for date {data_date}")
    return True


def get_tables_data_date(job_name, logical_date):
    """Ngày dữ liệu của từng bảng nguồn mà DAG chờ: {tên bảng: 'YYYY-MM-DD'}.

    Tên bảng là phần cuối của job_waiting (ví dụ 'eod|aws_bankwide|t24_company__s2' -> 't24_company__s2'),
    trùng tên bảng vật lý mà macro get_data_date_for_table tra. Bảng của job có holiday = 1 lấy ngày làm
    việc gần nhất (<= ngày chạy) trong dwh_ctrl.t24_holiday__fu; bảng khác lấy đúng ngày chạy.
    """
    print(f"get tables data date for job_name: {job_name} , logical_date: {logical_date}")
    sql_query = r'''
        select distinct substring(a.job_waiting from '(\w+)$') job_waiting,
        to_char(case when b.holiday = 1 then c.mth_day_no else %s::date end, 'yyyy-mm-dd')::varchar(30) as data_date
        from dwh_ctrl.cstb_etl_waiting a
        left join dwh_ctrl.cstb_job_run_list b on a.job_waiting = b.job_name
        left join (
                select max(mth_day_no) mth_day_no from dwh_ctrl.t24_holiday__fu where is_holiday = 'W' and mth_day_no <= %s::date
        ) c on 1=1
        where a.job_name = %s
    '''
    try:
        rows = PostgresHook(postgres_conn_id=CTRL_CONN_ID).get_records(sql_query, parameters=(logical_date, logical_date, job_name))
        table_names = {row[0]: row[1] for row in rows}
        print(f"table_name_json: {table_names}")
        return table_names
    except Exception:
        print(traceback.format_exc())
        print("Error: Something happen when execute SELECT sql, please check!")
        return {}


def get_pre_last_working_day(business_date):
    """Ngày làm việc liền trước business_date: lịch dwh_ctrl.t24_holiday__fu (is_holiday = 'W');
    lịch chưa có ngày nào trước đó thì lấy ngày thứ Hai đến thứ Sáu liền trước."""
    sql_query = '''
        select to_char(max(mth_day_no), 'YYYY-MM-DD')
        from dwh_ctrl.t24_holiday__fu
        where is_holiday = 'W' and mth_day_no < %s::date
    '''
    row = PostgresHook(postgres_conn_id=CTRL_CONN_ID).get_first(sql_query, parameters=(business_date,))
    if row and row[0]:
        print(f"pre_last_wk_day theo lịch t24_holiday__fu: {row[0]}")
        return row[0]
    day = date.fromisoformat(business_date) - timedelta(days=1)
    while day.weekday() >= 5:
        day -= timedelta(days=1)
    print(f"Lịch t24_holiday__fu chưa có ngày trước {business_date}, lấy ngày thứ Hai-thứ Sáu liền trước: {day}")
    return day.isoformat()
