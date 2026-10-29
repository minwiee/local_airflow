/*
*----------------------------------------------------------------------*
* Program code  : tfm_bi_depo_prfl__mnp
* Program name  : Transform BI Deposit Profile Multi Snapshot
* Mô tả         : Nhóm sản phẩm tra từ file MA csv_partb_product của ngày chạy; kỳ hạn BI
*                 (bi_term) tính theo bậc số ngày. Bảng vẫn chứa hợp đồng tất toán trong
*                 ngày; việc loại chúng nằm ở bi_depo_info_intf__mnp. BI_TERM là số ép sang
*                 VARCHAR(10), khi kiểm thử phải so theo giá trị số.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-102 Tạo mới
*                 2026-10-23 ducnm DWH-102 Chuyển sang cú pháp PostgreSQL (trừ hai ngày ra số ngày)
*----------------------------------------------------------------------*
*/

{% set bi_ref_src = "bi_ref" %}

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}

with depo_intf as (
select   depo.CONTRACT_NBR AS CONTRACT_NBR
	, depo.CUST_CODE AS CUST_CODE
	, depo.CCY_CODE AS CCY_CODE
	, depo.NOTION_MAT_DATE AS NOTION_MAT_DATE
	, depo.INST_RATE AS INST_RATE
	, depo.CLOSE_AMT_FCY AS CLOSE_AMT_FCY
	,depo.ACCT_SEPRT_TYPE AS ACCT_SEPRT_TYPE
	,ma_prd.PRD_GROUP AS PRD_GROUP_NAME
	, CASE
 	WHEN upper(ma_prd.PRD_GROUP) = '2. TERM DEPOSIT' THEN
 	CASE
  	WHEN (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date) <= 10 THEN 0.25
  	WHEN (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date) BETWEEN 11 AND 17 THEN 0.5
  	WHEN (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date) BETWEEN 18 AND 27 THEN 0.75
  	WHEN (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date) BETWEEN 28 AND 45 THEN 1
  	WHEN (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date) BETWEEN 46 AND 365 THEN ROUND(1.0 * (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date)/ 30, 0)
  	WHEN (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date) >= 366 THEN
   	CASE
    WHEN ROUND(1.0 * (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date)* 12 / 365, 0) BETWEEN 12 AND 13 THEN 13
    ELSE ROUND(1.0 * (depo.NOTION_MAT_DATE::date - depo.VALUE_DATE::date)* 12 / 365, 0)
   END
 	END
	END as  BI_TERM
	, depo.CATE_CODE
	, depo.VALUE_DATE as EFF_DATE
from {{ ref( 'depo_intf' ) }}  depo
left join {{ source(bi_ref_src,'raw_csv_partb_product') }} ma_prd  ON ma_prd.PRD_CODE  = depo.CATE_CODE and  ma_prd.TF_PARTITION_DATE  = '{{ var("business_date") }}'::date
where depo.business_date = '{{ var("business_date") }}'::date
/*and depo.acct_seprt_type <> 'CLOSE'*/
)
select
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
	,  {{ gen_tf_cols_by_table_type('mnp', 'DEPO_INTF') }}
from  DEPO_INTF depo
