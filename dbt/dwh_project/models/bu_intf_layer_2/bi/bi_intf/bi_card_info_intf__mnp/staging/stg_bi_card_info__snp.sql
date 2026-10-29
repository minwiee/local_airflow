/*
*----------------------------------------------------------------------*
* Model name    : stg_bi_card_info__snp
* Program name  : Staging thông tin thẻ của BI Card Info Interface
* Mô tả         : Đổi tên cột (STATUS_NAME thành CARD_STATUS, CARD_STATUS thành
*                 PHYS_CARD_STATUS) và áp quy tắc loại thẻ của khối BI: thông tin nguồn có
*                 MOBIPHONE, tên sản phẩm có MC2 và mở trước 2014-01-01.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-104 Tạo mới
*                 2026-10-23 ducnm DWH-104 Chuyển sang cú pháp PostgreSQL (coalesce)
*----------------------------------------------------------------------*
*/

select
	c.UNIQ_ID_IN_SRC_SYS::varchar(64) as UNIQ_ID_IN_SRC_SYS --ACNT_CONTRACT_ID
	, c.CONTRACT_NBR::varchar(64)	as CARD_NBR --CARD_NUMBER
	, c.CONTRACT_STATUS::varchar(64)	as	CARD_STATUS
	, c.ACCOUNT_LIMIT::numeric(23,5) as CARD_LIMIT_AMT	--CARD_LIMIT
	, c.DATE_OPEN::date 	as	CARD_OPEN_DATE
	, c.CARD_EXP::varchar(6) as ORIGINL_DATE_EXP --ORG_DATE_EXPIRE
	, c.ACTUAL_END_DATE::date as ACTUAL_DATE_EXP --	ACTUAL_DATE_EXPIRE
	, c.CARD_TYPE::varchar(128) as CARD_PRD_NAME --CARD_TYPE
	, c.PRODUCTION_STATUS::varchar(128) as PHYS_CARD_STATUS --PRODUCTION_STATUS
	, c.PRODUCT_GROUP::varchar(64) as PRODUCT_GROUP
	, c.SOURCE_INFO::varchar(256) as SRC_INFO --SOURCE_INFO
	, c.TF_SOURCE_SYSTEM::varchar(64) as SRC_SYS_CODE -- SRC_STM_CODE
	, c.CON_CAT::varchar(8) as CON_CAT
	, {{ gen_tf_cols_by_table_type('snp', 'CARD_INTF') }}
from (
	select c1.UNIQ_ID_IN_SRC_SYS
		, c1.PRODUCT_GROUP
		, c1.CONTRACT_NBR
		, c1.CONTRACT_STATUS
		, c1.ACCOUNT_LIMIT
		, c1.DATE_OPEN
		, c1.CARD_EXP
		, c1.ACTUAL_END_DATE
		, c1.CARD_TYPE
		, c1.PRODUCTION_STATUS
		, c1.SOURCE_INFO
		, c1.TF_SOURCE_SYSTEM
		, c1.CON_CAT
	from {{ ref('stg_bi_card__snp')}} c1
) c
where not (upper(coalesce(c.SOURCE_INFO,'')) like '%MOBIPHONE%'
		and upper(coalesce(c.CARD_TYPE,'')) like '%MC2%'
		and coalesce(C.DATE_OPEN,'2400-01-01')::date < '2014-01-01'::date)
