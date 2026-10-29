/*
*----------------------------------------------------------------------*
* Model name    : bi_card_info_intf__mnp
* Program name  : BI Card Info Interface Multi Snapshot
* Mô tả         : Interface layer 2 thẻ cho khối BI: lấy từ tfm_bi_card_info__mnp của đúng
*                 ngày chạy và ép kiểu. pre_hook xóa dữ liệu của business_date trước khi
*                 nạp lại.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-104 Tạo mới
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}

SELECT
    a.uniq_id_in_src_sys::NUMERIC(23, 5) AS UNIQ_ID_IN_SRC_SYS                        --ACNT_CONTRACT_ID
    , a.card_nbr::VARCHAR(64) AS CARD_NBR                                             --CARD_NUMBER
    , a.card_status::VARCHAR(64) AS CARD_STATUS
    , a.card_limit_amt::NUMERIC(23, 5) AS CARD_LIMIT_AMT                              --CARD_LIMIT
    , a.card_open_date::DATE AS CARD_OPEN_DATE                                        --CARD_OPEN_DATE
    , a.ORIGINL_DATE_EXP::VARCHAR(6) AS ORIGINL_DATE_EXP                                 --ORG_DATE_EXPIRE
    , a.actual_date_exp::DATE AS ACTUAL_DATE_EXP                                      --ACTUAL_DATE_EXPIRE
    , a.card_prd_name::VARCHAR(256) AS CARD_PRD_NAME                                  --CARD_TYPE
    , a.phys_card_status::VARCHAR(64) AS PHYS_CARD_STATUS                             --PRODUCTION_STATUS
    , a.bi_prd_type::VARCHAR(64) AS BI_PRD_TYPE                                       --BI_PRD_TYPE
    , a.bi_prd_group::VARCHAR(64) AS BI_PRD_GROUP                                     --BI_PRD_GROUP
    , a.tf_source_system::VARCHAR(64) AS TF_SOURCE_SYSTEM                                         --SRC_STM_CODE
    , '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT
    , '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID
    , '{{ var("business_date") }}'::DATE AS TF_PARTITION_DATE
FROM {{ ref('tfm_bi_card_info__mnp') }} AS a
WHERE a.tf_partition_date = '{{ var("business_date") }}'::DATE
