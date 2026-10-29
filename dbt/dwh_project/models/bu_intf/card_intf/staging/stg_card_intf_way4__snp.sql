/*
*----------------------------------------------------------------------*
* Program code  : stg_card_intf_way4__snp
* Program name  : Staging của CARD_INTF từ nguồn Way4
* Mô tả         : Thẻ (CON_CAT = 'C') đang hiệu lực của ngày chạy, nối hợp đồng thẻ cha,
*                 sản phẩm, nhóm sản phẩm (bảng lịch sử, lấy phiên bản còn hiệu lực) và
*                 danh mục trạng thái bằng id của Way4. Đưa thêm DATE_OPEN, DATE_EXPIRE để
*                 card_intf áp quy tắc D+1.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-104 Tạo mới
*                 2026-10-23 ducnm DWH-104 Chuyển sang cú pháp PostgreSQL (coalesce, case, hàm
*                 public.last_day)
*----------------------------------------------------------------------*
*/

{% set eod_shared_src = "eod_shared" %}
{% set tbls_data_date = var('tbls_data_date') %}

select
    acnt.ID::varchar(256) as UNQ_ID_IN_SRC_STM,
    DATE(public.last_day(TO_DATE(case when ACNT.CARD_EXPIRE is not null and ACNT.CARD_EXPIRE <> '0000'
                        then '20'||ACNT.CARD_EXPIRE||'01'else null end,'YYYYMMDD')
        ))::DATE AS EXP_DT,
    acnt.DATE_OPEN::date as CARD_OPN_DT,
    card_w4.SOURCE_INFO::VARCHAR(256) AS SRC_INF,
    UPPER(card_w4.PRODUCTION_STATUS)::VARCHAR(128) as  PHYS_CARD_ST,
    acnt.contract_number_mask::VARCHAR(64) AS PYMTC_CODE, --mã thẻ
    hd.contract_number_mask::VARCHAR(64) as AR_CODE, --mã hd thẻ
    case when acnt.DATE_EXPIRE::date = '{{var('business_date')}}'::date + 1 and acnt.DATE_OPEN::date < '{{var('business_date')}}'::date then null
        else acnt.DATE_EXPIRE end::date as EFF_TO_DT,
    acnt.DATE_OPEN::DATE AS EFF_FM_DT,
    ap.id::VARCHAR(64) as PD_CARD_CODE,
    CASE WHEN UPPER(pr.name) LIKE '%CREDIT%' THEN 'CREDIT-CARD'
         WHEN  UPPER(pr.NAME) LIKE '%DEBIT%' OR UPPER(pr.NAME) = 'ISSUING' THEN 'DEBIT-CARD' END::varchar(64) CARD_TP,
    CASE WHEN regexp_substr(upper(AP.NAME), 'PRIN|SUPP', 1, 1) = 'PRIN' THEN 'YES' ELSE 'NO' END::varchar(10) PRIM_CARD_F,
    coalesce(card_w4.ACCOUNT_LIMIT,0)::numeric(23,5) as LMT_AMT,
    hd.ID::varchar(64) AS AR_STM_NBR,
    wcs.NAME::varchar(64) as LC_ST_NM,
    acnt.DATE_OPEN::date as DATE_OPEN,
    acnt.DATE_EXPIRE::date as DATE_EXPIRE,
    {{gen_tf_cols_by_table_type('mnp','WAY4_ACNT_CONTRACT')}}

from (
        select
        *
        from {{ source(eod_shared_src, 'raw_way4_acnt_contract') }} acnt
        where
            acnt.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_acnt_contract") }}'::date
            AND acnt.AMND_STATE = 'A'
            AND ACNT.CON_CAT ='C'
            AND ACNT.Base_relation is NULL
            AND ACNT.contract_number_mask NOT LIKE '60000%'
            AND ACNT.contract_number_mask NOT LIKE '111111%'
            AND ACNT.contract_number_mask NOT LIKE '999999%'
            AND ACNT.contract_number_mask NOT LIKE '70%'
 )  acnt
inner join {{ source(eod_shared_src, 'raw_way4_acnt_contract') }} hd
    on acnt.ACNT_CONTRACT__OID = hd.ID AND hd.AMND_STATE = 'A' and hd.CON_CAT = 'A'
    and hd.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_acnt_contract") }}'::date
inner join {{ source(eod_shared_src, 'raw_way4_appl_product') }} ap
    on acnt.PRODUCT = ap.internal_code and ap.AMND_STATE = 'A'
    and ap.tf_partition_date =  '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_appl_product") }}'::date
left join {{ source(eod_shared_src, 'raw_way4_appl_pr_group') }} pr
    on ap.APPL_PR_GROUP__ID = pr.id and pr.tf_created_at  <= '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_appl_product") }}'::date
    and pr.tf_updated_at > '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_appl_product") }}'::date
left join {{ source(eod_shared_src, 'raw_way4_contr_status') }} wcs
    on acnt.CONTR_STATUS = wcs.ID and wcs.AMND_STATE = 'A'
    and wcs.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_contr_status") }}'::date
left join ( -- thay đổi logic sang bang thay the tbl_w4_acnt_contract
        select
            acnt.id,
            acnt.add_info_04 as SOURCE_INFO,
            case acnt.PRODUCTION_STATUS
                    when 'C' then 'To Close'
                    when 'L' then 'Locked'
                    when 'M' then 'Marked'
                    when 'N' then 'To Request'
                    when 'O' then 'Locked for Online'
                    when 'R' then 'Ready'
                    when 'S' then 'Sent'
                    when 'T' then 'Marked Applet'
                    when 'W' then 'Waiting for Response'
                    when 'Y' then 'Not to Mark'
                    when 'm' then 'To Mark'
                    when 'w' then 'Waiting for Subs'
            end as PRODUCTION_STATUS,
            acnt.AUTH_LIMIT_AMOUNT as ACCOUNT_LIMIT,
            acnt.con_cat
        from {{ source(eod_shared_src, 'raw_way4_acnt_contract') }} acnt
        where acnt.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_acnt_contract") }}'::date
            AND acnt.AMND_STATE = 'A' and acnt.Base_relation IS  NULL
) card_w4 on acnt.ID = card_w4.ID
WHERE  upper(AP.NAME) not like '%RELATION%'
