/*
*----------------------------------------------------------------------*
* Program code  : bi_depo_info_intf__mnp
* Program name  : BI Deposit Info Interface Multi Snapshot
* Mô tả         : Interface layer 2 tiền gửi cho khối BI: lấy 1-1 từ tfm_bi_depo_prfl__mnp,
*                 chỉ giữ hợp đồng còn mở. Điều kiện WHERE có vế cho nguồn OD_INTF (thấu
*                 chi), chưa có dữ liệu trong phạm vi DWH-102. Các cột TF_* viết trực tiếp,
*                 TF_RUN_ID là hằng 'prod'.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-102 Tạo mới
*                 2026-10-23 ducnm DWH-102 Chuyển sang cú pháp PostgreSQL (coalesce)
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}
SELECT
    depo.CONTRACT_NBR::VARCHAR(64)  CONTRACT_NBR
	, depo.CUST_CODE::VARCHAR(64)  CUST_CODE
	, depo.CCY_CODE::VARCHAR(32)  CCY_CODE
	, depo.NOTION_MAT_DATE::DATE NOTION_MAT_DATE
	, depo.INST_RATE::NUMERIC(8,5) INST_RATE
	, depo.CLOSE_AMT_FCY::NUMERIC(23,5) CLOSE_AMT_FCY
	, depo.ACCT_SEPRT_TYPE::VARCHAR(64) ACCT_SEPRT_TYPE
	, depo.PRD_GROUP_NAME::VARCHAR(256) PRD_GROUP_NAME
	, depo.BI_TERM::VARCHAR(10) BI_TERM
	, depo.CATE_CODE::VARCHAR(64) CATE_CODE
	, depo.EFF_DATE::DATE EFF_DATE
	, CURRENT_TIMESTAMP::TIMESTAMP AS TF_ETL_AT
    , NULL::TIMESTAMP AS TF_SOURCING_AT
    , 'prod'::VARCHAR(128) AS TF_RUN_ID
    , '{{ var("business_date") }}'::date as TF_PARTITION_DATE
    , depo.tf_source_system::VARCHAR(64) TF_SOURCE_SYSTEM
FROM   {{ ref( 'tfm_bi_depo_prfl__mnp' ) }} depo
where tf_partition_date= '{{ var("business_date") }}'::date
AND ((depo.tf_source_system = 'DEPO_INTF' and coalesce(UPPER(depo.ACCT_SEPRT_TYPE) ,'N/A')<> 'CLOSE') or depo.tf_source_system = 'OD_INTF')
