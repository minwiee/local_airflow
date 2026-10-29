/*
*----------------------------------------------------------------------*
* Program code  : repay_acty_intf
* Mô tả         : Model giữ chỗ của Airflow local. repay_acty_intf do DAG khác dựng (ngoài
*                 phạm vi bộ tài liệu); dữ liệu của nó được nạp sẵn từ bộ dữ liệu test
*                 (cases/03_loan/data/source). File này chỉ để ref('repay_acty_intf') của các model
*                 trong phạm vi phân giải được: cấu hình (schema, materialized) lấy theo
*                 schema.yml. Không có DAG nào chọn model này; nếu chạy tay thì model
*                 không nạp thêm dòng nào.
* Created by    : tools/build_dbt_project.py
*----------------------------------------------------------------------*
*/

select * from {{ this }} where false
