/*
*----------------------------------------------------------------------*
* Model name    : stg_bi_card__snp
* Program name  : Staging nhánh thẻ của BI Card Info Interface
* Mô tả         : Thẻ Way4 của card_intf ngày chạy; tra tên sản phẩm và tên nhóm sản phẩm
*                 ở prd_intf.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-104 Tạo mới
*----------------------------------------------------------------------*
*/

select
	ci.UNIQ_ID_IN_SRC_SYS::varchar(64) --id
	, substring(to_char(ci.EXP_DATE,'yyyyMMdd'),1,6)::varchar(6) as CARD_EXP
	, pi.PRD_NAME::varchar(128) as CARD_TYPE
	, ci.LIMIT_AMT::numeric(23,5) as ACCOUNT_LIMIT
	, ci.CARD_NBR::varchar(64) as CONTRACT_NBR
	, ci.STATUS_NAME::varchar(64) as CONTRACT_STATUS
	, cast('C' as varchar(8)) as CON_CAT
	, ci.ACTUAL_END_DATE::date --DATE_EXPIRE
	, case
		when cast(ci.CARD_OPEN_DATE as date) = '2014-04-09' then cast('2014-04-10' as date)
		else cast(ci.CARD_OPEN_DATE as date)
	end::date as DATE_OPEN
	, ci.CARD_STATUS::varchar(128) as PRODUCTION_STATUS
	, pi.PRD_GROUP_NAME::varchar(64) PRODUCT_GROUP
	, case when position('_' in ci.SRC_INFO) = 1 then replace(ci.SRC_INFO,'_','') else ci.SRC_INFO end::varchar(256) as SOURCE_INFO
	, {{ gen_tf_cols_by_table_type('snp', 'CARD_INTF') }}
from {{ ref('card_intf') }} ci
left join  {{ ref('prd_intf') }} pi
	on ci.PRD_CARD_CODE = pi.UNIQ_ID_IN_SRC_SYS
		and pi.SRC_SYS_CODE = 'WAY4_APPL_PRODUCT'
		and pi.BUSINESS_DATE = '{{ var("business_date") }}'
where ci.SRC_SYS_CODE = 'WAY4_ACNT_CONTRACT'
    and ci.business_date = '{{ var("business_date") }}'
