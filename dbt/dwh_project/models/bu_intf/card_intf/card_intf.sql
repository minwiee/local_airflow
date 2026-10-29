/*
*----------------------------------------------------------------------*
* Program code  : card_intf
* Program name  : Card interface (L1)
* Mô tả         : Thẻ Way4 từ stg_card_intf_way4__snp: đổi mã trạng thái sản xuất sang tên,
*                 suy loại thẻ và cờ thẻ chính, tính hạn in trên thẻ. Thẻ hết hiệu lực đúng
*                 D+1 và mở trước D lấy STATUS_NAME của phân vùng D-1 của chính card_intf
*                 (card_prv). Chỉ lấy thẻ có hợp đồng thẻ cha hợp lệ (exists arxcl).
*                 pre_hook xóa dữ liệu của business_date trước khi nạp lại.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-104 Tạo mới
*                 2026-10-23 ducnm DWH-104 Chuyển sang cú pháp PostgreSQL (coalesce)
*----------------------------------------------------------------------*
*/
{% set eod_shared_src = "eod_shared" %}
{% set tbls_data_date = var('tbls_data_date') %}
{{
    config(
        pre_hook = "delete from {{ this }} where BUSINESS_DATE = '{{var('business_date')}}'"
    )
}}
select
    '{{var('business_date')}}'::date as BUSINESS_DATE,
    {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }}::TIMESTAMP AS PPN_DATE,
    card.PYMTC_CODE::varchar(64) as CARD_NBR,
    card.AR_CODE::varchar(64) as CONTRACT_NBR,
    card.PD_CARD_CODE::varchar(64) as PRD_CARD_CODE,
    card.LMT_AMT::numeric(23,5) as LIMIT_AMT,
    card.CARD_TP::varchar(64) as CARD_TYPE,
    case when card.DATE_EXPIRE::date = '{{var('business_date')}}'::date + 1 and card.DATE_OPEN::date < '{{var('business_date')}}'::date then card_prv.STATUS_NAME
        else card.LC_ST_NM::varchar(64) end::VARCHAR(64) as STATUS_NAME,
    card.PHYS_CARD_ST::varchar(128) as CARD_STATUS,
    card.PRIM_CARD_F::varchar(10) as PRIM_CARD_FLAG,
    card.EFF_FM_DT::date as CARD_OPEN_DATE,
    card.EXP_DT::date as EXP_DATE,
    'WAY4_ACNT_CONTRACT'::VARCHAR(64) AS SRC_SYS_CODE,
    card.UNQ_ID_IN_SRC_STM::varchar(64) as UNIQ_ID_IN_SRC_SYS,
    card.EFF_TO_DT::date as ACTUAL_END_DATE,
    card.SRC_INF::varchar(256) as SRC_INFO
from {{ ref('stg_card_intf_way4__snp') }} card
left join {{ this }} card_prv
    on card.UNQ_ID_IN_SRC_STM = card_prv.UNIQ_ID_IN_SRC_SYS
    and card_prv.BUSINESS_DATE = '{{var('business_date')}}'::date - 1
where
    card.TF_PARTITION_DATE = cast('{{var('business_date')}}' as date)
    and exists (select 1 from {{ source(eod_shared_src, 'raw_way4_acnt_contract') }} arxcl
    where arxcl.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_acnt_contract") }}'::date
        and arxcl.CON_CAT= 'A'
        AND arxcl.AMND_STATE = 'A'
        AND arxcl.BASE_RELATION IS NULL
        AND arxcl.PCAT='C'
        and coalesce(arxcl.DATE_EXPIRE,'2400-01-01')::DATE >= '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_way4_acnt_contract") }}'::date --hđ còn hiệu lực or đóng trong ngày dữ liệu
        and card.AR_STM_NBR = arxcl.ID::varchar(64)
        )
    and card.CARD_OPN_DT <= '{{var('business_date')}}'::date
