/*
*----------------------------------------------------------------------*
* Model name    : tfm_bi_card_info__mnp
* Program name  : Transform BI Card Information Multi Snapshot
* Mô tả         : BI_PRODUCT_TYPE theo đầu số thẻ; BI_PRODUCT_GROUP theo tên sản phẩm, tên
*                 nhóm sản phẩm và đầu số thẻ; ngày mở 2014-04-09 đổi thành 2014-04-10.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-104 Tạo mới
*                 2026-10-23 ducnm DWH-104 Chuyển sang cú pháp PostgreSQL (coalesce)
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}

with cte_acnt_contract as (
    select
        a.*
        , case when left(A.CARD_NBR,1) in ('3', '4', '5') then '02.International Card'
        when left(A.CARD_NBR,2) in ('62')  then '02.International Card'
                else '01.Local Card' end BI_PRODUCT_TYPE
        , case
            when  upper(A.CARD_PRD_NAME) LIKE '%CREDIT%' or upper(coalesce(A.PRODUCT_GROUP,''))  like '%CREDIT%' then '01.Credit Card'
     	    when  upper(A.CARD_PRD_NAME) LIKE '%DEBIT%' or upper(A.PRODUCT_GROUP) like '%DEBIT%' or upper(coalesce(A.PRODUCT_GROUP,'')) ='ISSUING'
      	        or (A.CARD_NBR LIKE '5%' AND (upper(coalesce(A.PRODUCT_GROUP,'GIATRINULL'))  not like '%CREDIT%' and coalesce(upper(A.CARD_PRD_NAME),'GIATRINULL') NOT LIKE '%CREDIT%'))
      	        then '02.Debit Card'
        end BI_PRODUCT_GROUP
    from {{ref('stg_bi_card_info__snp')}} a
)
select
    a.UNIQ_ID_IN_SRC_SYS::varchar(64) as UNIQ_ID_IN_SRC_SYS
    , a.CARD_NBR::varchar(64) as CARD_NBR
    , a.CARD_STATUS::varchar(64) as CARD_STATUS
    , a.CARD_LIMIT_AMT::numeric(23,5) as CARD_LIMIT_AMT
    , a.CARD_OPEN_DATE::date as CARD_OPEN_DATE
    , a.ORIGINL_DATE_EXP::varchar(6) as ORIGINL_DATE_EXP
    , a.ACTUAL_DATE_EXP::date as ACTUAL_DATE_EXP
    , a.CARD_TYPE::varchar(256) as CARD_PRD_NAME
    , a.PHYS_CARD_STATUS::varchar(64) as PHYS_CARD_STATUS
    , a.BI_PRD_TYPE::varchar(64) as BI_PRD_TYPE
    , a.BI_PRD_GROUP::varchar(64) as BI_PRD_GROUP
    , a.TF_SOURCE_SYSTEM::varchar(64) as TF_SOURCE_SYSTEM
    , a.TF_ETL_AT::timestamp as TF_ETL_AT
    , a.TF_RUN_ID::varchar(128) as TF_RUN_ID
    , a.TF_PARTITION_DATE::date as TF_PARTITION_DATE
    , a.TF_SOURCING_AT::TIMESTAMP AS TF_SOURCING_AT
  from (
select
    a.UNIQ_ID_IN_SRC_SYS::varchar(64) as UNIQ_ID_IN_SRC_SYS                                               --ACNT_CONTRACT_ID      /CARD_ID
    , nullif(a.CARD_NBR,'')::varchar(64) as CARD_NBR                                                        --CARD_NUMBER           /CARD_NBR
    , a.CARD_STATUS::varchar(64) as CARD_STATUS                                                             --CARD_STATUS           /CARD_STATUS
    , a.CARD_LIMIT_AMT::numeric(23,5) as CARD_LIMIT_AMT                                                     --CARD_LIMIT            /CARD_LIMIT_AMT
    , a.CARD_OPEN_DATE::date as CARD_OPEN_DATE                                                              --CARD_OPEN_DATE
    , nullif(a.ORIGINL_DATE_EXP,'')::varchar(6) as ORIGINL_DATE_EXP                                            --ORG_DATE_EXPIRE       /CARD_EXP_DATE
    , a.ACTUAL_DATE_EXP::date as ACTUAL_DATE_EXP                                                            --ACTUAL_DATE_EXPIRE
    , nullif(a.CARD_PRD_NAME,'')::varchar(256) as CARD_TYPE                                             --CARD_TYPE             /CARD_PRD_NAME
    , nullif(a.PHYS_CARD_STATUS,'')::varchar(64) as PHYS_CARD_STATUS                                         --PRODUCTION_STATUS     / PHYS_CARD_STATUS
    , a.BI_PRODUCT_TYPE::varchar(64) as BI_PRD_TYPE                                                  --BI_PRD_TYPE
    , a.BI_PRODUCT_GROUP::varchar(64) as BI_PRD_GROUP                                                --BI_PRD_GROUP      /BI_PRD_GROUP
    , a.SRC_SYS_CODE::varchar(64) as TF_SOURCE_SYSTEM                                                --SRC_STM_CODE
    , '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT
    , '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID
    , '{{ var("business_date") }}' ::date as TF_PARTITION_DATE
    , NULL::TIMESTAMP AS TF_SOURCING_AT
from cte_acnt_contract a
  ) a
