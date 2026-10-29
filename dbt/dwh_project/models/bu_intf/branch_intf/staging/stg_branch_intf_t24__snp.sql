/*
*----------------------------------------------------------------------*
* Program code  : stg_branch_intf_t24__snp
* Program name  : Staging của BRANCH_INTF từ nguồn T24
* Mô tả         : Đơn vị có trong BANK.COMPANY của ngày chạy và có bản ghi COMPANY còn
*                 hiệu lực; tên ghép từ các dòng của BANK.COMPANY.DETAILS theo thứ tự m
*                 rồi s; tỉnh/thành từ BANK.PROVINCE.DETAILS; vùng bán lẻ từ file MA csv_cv.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-101 Tạo mới
*                 2026-10-23 ducnm DWH-101 Chuyển sang cú pháp PostgreSQL (string_agg, length)
*                 2026-10-23 ducnm DWH-101 Khai báo tbls_data_date cho macro get_data_date_for_table
*                 2026-10-23 ducnm DWH-101 Ép kiểu cả biểu thức PROVIN_CODE sang VARCHAR(64): vế '0' ||
*                 trước đây ra varchar không độ dài, dbt (on_schema_change = fail) báo lệch kiểu với
*                 dwh_intf.branch_intf
*----------------------------------------------------------------------*
*/

{% set eod_shared_src = "eod_shared" %}
{% set dwh_ref_src = "dwh_ref" %}
{% set dwh_staging_src = "dwh_staging" %}
{% set tbls_data_date = var('tbls_data_date') %}

with tvcd_addr as (
    select
        id
        , string_agg(tvcd.branch_name, ' ' order by cast(m as int), cast(s as int)) branch_name
    from {{ source(dwh_staging_src, 'raw_t24_bank_company_details') }} tvcd
    where tf_partition_date::DATE = '{{ var("business_date") }}'::DATE
    group by id
)
select
    to_date('{{ var("business_date") }}', 'YYYY-MM-DD') as BUSINESS_DATE
    , {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }}::TIMESTAMP as PPN_DATE
    , tvc.ID::VARCHAR(32) as BRANCH_CODE
    , 'T24_BANK_COMPANY'::VARCHAR(64) as SRC_SYS_CODE
    , tvc.FROM_DATE::DATE as VALUE_DATE
    , tvc.TO_DATE::DATE as ACTUAL_END_DATE
    , tvcd_addr.BRANCH_NAME::VARCHAR(64) as BRANCH_NAME
    , tvc.SEGMENT::VARCHAR(32) as DIVISION
    , tvc.MAIN_BRANCH_CODE::VARCHAR(32) as MAIN_BRANCH_CODE
    , tc.MNEMONIC::VARCHAR(32) as BOOK_CODE
    , tc_main.MNEMONIC::VARCHAR(32) as MAIN_BOOK_CODE
    , tvc.REGION_KHCN_CODE::VARCHAR(32) as RETAIL_REGION_CODE
    , coalesce(csv_cv.CL_NM, tvc.REGION_KHCN_NAME)::VARCHAR(64) as RETAIL_REGION_NAME
    , tvc.STATUS::VARCHAR(64) as BRANCH_STATUS
    , tvc.REGION::VARCHAR(32) as GEO_ZONE
    , upper(tvc.BRANCH_TYPE)::VARCHAR(64) as BRANCH_TYPE
    , case when length(tvc.CODE_PROVINCE) = 1 then '0' || tvc.CODE_PROVINCE
        else tvc.CODE_PROVINCE end::VARCHAR(64) as PROVIN_CODE
    , upper(tvpd.PROVINCE_NAME)::VARCHAR(64) as PROVIN_NAME
from {{ source(dwh_staging_src, 'raw_t24_bank_company') }} tvc
join {{ source(dwh_staging_src, 'raw_t24_bank_company_details') }} tvcd
on tvc.id = tvcd.id
and tvcd.m = 1
and tvcd.s = 1
and tvcd.tf_partition_date::DATE = '{{ var("business_date") }}'::DATE
join {{ source(eod_shared_src, 'raw_t24_company') }} tc
on tvc.id = tc.company_code
and tc.tf_created_at <= '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_company") }}'::DATE
and tc.tf_updated_at > '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_company") }}'::DATE
left join {{ source(eod_shared_src, 'raw_t24_company') }} tc_main
on tc_main.company_code = tvc.main_branch_code
and tc_main.tf_created_at <= '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_company") }}'::DATE
and tc_main.tf_updated_at > '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_company") }}'::DATE
left join tvcd_addr
on tvc.id = tvcd_addr.id
left join {{ source(dwh_staging_src, 'raw_t24_bank_province_details') }} tvpd
on tvc.code_province = tvpd.id
and tvpd.province_name is not null
and tvpd.tf_partition_date::DATE = '{{ var("business_date") }}'::DATE
left join {{ source(dwh_ref_src, 'raw_csv_cv') }} csv_cv on tvc.REGION_KHCN_CODE = (CASE WHEN csv_cv.CL_SCM_ID IN ('209','265','266') THEN csv_cv.CL_CODE ELSE NULL END)
and csv_cv.tf_partition_date::DATE = '{{ var("business_date") }}'::DATE
where tvc.tf_partition_date::DATE = '{{ var("business_date") }}'::DATE
