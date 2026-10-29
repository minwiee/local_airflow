/*
*----------------------------------------------------------------------*
* Program code  : vw_init_branch_intf_sap
* Program name  : Dòng chi nhánh mặc định của BRANCH_INTF
* Mô tả         : View trả về một dòng mã ZZZZZZZZZ để các bảng nối theo mã chi nhánh
*                 luôn có dòng đích.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-101 Tạo mới
*----------------------------------------------------------------------*
*/

select
    to_date('{{ var("business_date") }}', 'YYYY-MM-DD') as business_date
    , {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }}::TIMESTAMP as ppn_date
    , 'ZZZZZZZZZ'::VARCHAR(32) as branch_code
    , 'T24_BANK_COMPANY'::VARCHAR(64) as src_sys_code
    , NULL::DATE as value_date
    , NULL::DATE as actual_end_date
    , 'ZZZZZZZZZ'::VARCHAR(64) as branch_name
    , NULL::VARCHAR(32) as division
    , NULL::VARCHAR(32) as main_branch_code
    , NULL::VARCHAR(32) as book_code
    , NULL::VARCHAR(32) as main_book_code
    , NULL::VARCHAR(32) as retail_region_code
    , NULL::VARCHAR(64) as retail_region_name
    , NULL::VARCHAR(64) as branch_status
    , NULL::VARCHAR(32) as geo_zone
    , NULL::VARCHAR(64) as branch_type
    , NULL::VARCHAR(64) as provin_code
    , NULL::VARCHAR(64) as provin_name
