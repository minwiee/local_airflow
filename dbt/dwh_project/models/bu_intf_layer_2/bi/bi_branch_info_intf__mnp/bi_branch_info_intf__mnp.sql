/*
*----------------------------------------------------------------------*
* Program code  : bi_branch_info_intf__mnp
* Program name  : BI Branch Info Interface Multi Snapshot
* Mô tả         : Interface layer 2 chi nhánh cho khối BI: lấy 1-1 từ
*                 tfm_bi_branch_info__mnp của ngày chạy.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-101 Tạo mới
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}

SELECT
    br.branch_code::VARCHAR(64) AS BRANCH_CODE
    , br.branch_id::VARCHAR(64) AS BRANCH_ID
    , br.branch_name::VARCHAR(255) AS BRANCH_NAME
    , br.branch_group_code::VARCHAR(64) AS BRANCH_GROUP_CODE
    , br.branch_group_id::VARCHAR(64) AS BRANCH_GROUP_ID
    , br.region_code::VARCHAR(64) AS REGION_CODE
    , br.branch_type::VARCHAR(64) AS BRANCH_TYPE
    , br.city_code::VARCHAR(64) AS CITY_CODE
    , br.retail_zone_id::VARCHAR(64) AS RETAIL_ZONE_ID
    , br.retail_zone_name::VARCHAR(255) AS RETAIL_ZONE_NAME
    , br.division::VARCHAR(64) AS DIVISION
    , br.region_new_name::VARCHAR(255) AS REGION_NEW_NAME
    , br.is_delete::CHAR(18) AS IS_DELETE
    , br.zone_code_new::VARCHAR(255) AS ZONE_CODE_NEW
    , br.zone_name_new_vn::VARCHAR(255) AS ZONE_NAME_NEW_VN
    , br.zone_name_new::VARCHAR(255) AS ZONE_NAME_NEW
    , br.zone_type::VARCHAR(64) AS ZONE_TYPE
    , br.hub_af_flag::VARCHAR(64) AS HUB_AF_FLAG
    , br.src_sys_code::VARCHAR(64) AS SRC_SYS_CODE
    , {{ gen_tf_cols_by_table_type('mnp','BRANCH_INTF') }}
FROM {{ ref('tfm_bi_branch_info__mnp') }} AS br
WHERE br.tf_partition_date = '{{ var("business_date") }}'::DATE
