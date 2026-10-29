/*
*----------------------------------------------------------------------*
* Program code  : bi_lend_repay_info_intf__fa
* Program name  : BI Lending Repay Information Interface Fact Append
* Mô tả         : Giao dịch trả nợ trong ngày (repay_acty_intf) có category khác 21059; số
*                 PDLD đổi về số LD; tài khoản trả nợ và số ngày quá hạn tra từ
*                 loan_contract_intf của đúng ngày chạy. pre_hook xóa dữ liệu của
*                 business_date trước khi nạp lại.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-103 Tạo mới
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}
with tb1 as (
  select
  	CASE WHEN LEFT(CONTRACT_NBR, 4)  = 'PDLD' THEN REPLACE(CONTRACT_NBR, 'PD', '') ELSE  CONTRACT_NBR  END as CONTRACT_NBR_1
  , CCY_CODE
  , REPAY_DATE
  , CONTRACT_NBR
  , CUST_CODE
  ,  REPAY_AMT
  ,  PRIN_AMT
  ,  INST_AMT
  ,  REPAY_ACTY_CODE
  from {{ ref('repay_acty_intf') }}
  where business_date = '{{ var("business_date") }}'
  AND CATE_CODE != '21059'
)
select
	  rai.CONTRACT_NBR_1::VARCHAR(64) CONTRACT_NBR
	, rai.CCY_CODE::VARCHAR(10) CCY_CODE
	, rai.REPAY_DATE::DATE  REPAY_DATE
	, rai.REPAY_AMT::NUMERIC(23 , 5) REPAY_AMT_LCY
	, rai.PRIN_AMT::NUMERIC(23 , 5) PRIN_AMT_LCY
	, rai.INST_AMT::NUMERIC(23 , 5) INST_AMT_LCY
	, LCI.PRIN_REPAY_ACCT_NBR::VARCHAR(64)  PRIN_REPAY_ACCT
	, LCI.INST_REPAY_ACCT_NBR::VARCHAR(64) INST_REPAY_ACCT
	, (CASE WHEN LEFT(RAI.CONTRACT_NBR, 4)  = 'PDLD' THEN LCI.NBR_OVD_DAY ELSE NULL END)::INTEGER NBR_OF_OVD_DAY
	, '{{ var("business_date") }}'::date BUSINESS_DATE
	, rai.CUST_CODE::VARCHAR(64)  CUST_CODE
  , REPAY_ACTY_CODE::VARCHAR(128) REPAY_ACTY_CODE
  , {{ gen_tf_cols_by_table_type('fa', 'REPAY_ACTY_INTF') }}
from tb1 rai
left join {{ ref('loan_contract_intf') }} lci ON LCI.CONTRACT_NBR = rai.CONTRACT_NBR_1
		AND LCI.BUSINESS_DATE = '{{ var("business_date") }}'
where 1=1
