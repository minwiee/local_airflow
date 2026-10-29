/*
*----------------------------------------------------------------------*
* Program code  : depo_intf
* Program name  : Interface tiền gửi có kỳ hạn (L1)
* Mô tả         : Hợp đồng tiền gửi T24 LD, ghép hai nhánh bằng UNION ALL:
*                 (1) hợp đồng còn hiệu lực tại ngày chạy;
*                 (2) hợp đồng tất toán trong ngày, số dư lấy của ngày làm việc trước
*                     (biến pre_last_wk_day do DAG truyền vào).
*                 Vế ELSE của TERM dành cho nguồn MM, chưa có dữ liệu trong phạm vi DWH-102.
*                 pre_hook xóa dữ liệu của business_date trước khi nạp lại.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-102 Tạo mới
*                 2026-10-23 ducnm DWH-102 Chuyển sang cú pháp PostgreSQL (coalesce, trừ hai ngày,
*                 case, hàm public.months_between)
*----------------------------------------------------------------------*
*/

{% set eod_shared_src = "eod_shared" %}
{% set pre_last_wk_day = var('pre_last_wk_day') %}

{{
    config(
        pre_hook = "delete from {{ this }} where BUSINESS_DATE = '{{ var('business_date') }}'"
    )
}}

with ar_depo_t24_prfl_prv AS (
	Select  DISTINCT
		ld.CONTRACT_NO_::VARCHAR(64)					AS DEP_AR_NBR,
		ldd.AMOUNT::DECIMAL(23,5)						AS CLS_BAL_AMT_FCY
	FROM
	{{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
	LEFT JOIN {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo_details') }} ldd ON ld.CONTRACT_NO_ = ldd.CONTRACT_NO_
	AND ldd.tf_partition_date  = CAST('{{ pre_last_wk_day }}' AS DATE)
	AND ldd.M = 1 AND ldd.S = 1
	WHERE ld.tf_partition_date  = CAST('{{ pre_last_wk_day }}' AS DATE)
)

/* tập hợp đồng hiệu lực */
SELECT DISTINCT
		'{{ var('business_date') }}'::DATE 					AS BUSINESS_DATE,
		{{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }}::TIMESTAMP AS PPN_DATE,
		ar_depo.UNQ_ID_IN_SRC_STM::VARCHAR(64)				AS CONTRACT_NBR,
		ar_depo_acm.CST_CODE::VARCHAR(64)					AS CUST_CODE,
		ar_depo_acm.CCY_CODE::VARCHAR(64)					AS CCY_CODE,
		ar_depo_intf.MGT_OU_CODE::VARCHAR(64)				AS MGMT_BRANCH_CODE,
		ar_depo.CGY_CODE::VARCHAR(64)						AS CATE_CODE,
		coalesce(ar_depo.END_DT,ar_depo.ACT_END_DT)::DATE		AS CLOSE_DATE,
		ar_depo_acm.INT_RATE::DECIMAL(8,5)					AS INST_RATE,
		ar_depo_intf.INT_PYMT_MTH::VARCHAR(20)				AS INST_PMT_METHOD,
		CASE WHEN ar_depo.end_dt = '{{ var("business_date") }}' THEN
			CASE WHEN '{{ var("business_date") }}'  <  ar_depo.EST_END_DT THEN 	'MAT_EARLY'
				WHEN  '{{ var("business_date") }}' >=  ar_depo.EST_END_DT THEN 	'MAT'
				else 'MAT'
			END
		END::VARCHAR(10) DEPO_CLOSE_TYPE,
		ar_depo_intf.CLS_BAL_AMT_FCY::DECIMAL(23,5)			AS CLOSE_AMT_FCY,
		ar_depo.EST_END_DT::DATE							AS NOTION_MAT_DATE,
		CASE WHEN ar_depo.TF_SOURCE_SYSTEM IN ('T24_ACCOUNT','T24_LD_LOANS_AND_DEPO')
		THEN
			CASE WHEN (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)< 28
	 			THEN (CASE (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)/7 WHEN 0 THEN 1 ELSE (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)/7 END)|| 'W'
	 			ELSE CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) || 'M'
			END
		ELSE
			CASE WHEN (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)< 28  THEN (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)|| 'D'
			     WHEN CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) >120 AND CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) < 123 THEN '120M'
	 			ELSE CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) || 'M'
			END
		END::VARCHAR(32)									AS TERM,
		CASE WHEN ar_depo.SUB_AR_CL_CODE != 'ZERO_INT' THEN ar_depo.SUB_AR_CL_CODE
				  ELSE
			  		CASE WHEN ar_depo_intf.CLS_BAL_AMT_FCY<> 0 THEN 'ZERO_INT_CLSBAL'
						 ELSE 'ZERO_INT'
					END
		END::VARCHAR(32)									AS ACCT_SEPRT_TYPE,
		ar_depo.EFF_DT::DATE								AS VALUE_DATE
FROM
{{ ref('stg_ar_x_cl_pst_t24_depo_t24_ld__snp') }} ar_depo
left join {{ ref('stg_ar_depo_t24_ld_prfl__snp') }} ar_depo_intf on ar_depo_intf.DEP_AR_NBR = ar_depo.unq_id_in_src_stm
and ar_depo_intf.tf_partition_date = '{{ var("business_date") }}'
left join {{ ref('stg_ar_depo_t24_ld_prfl__snp') }} ar_depo_acm on ar_depo_acm.DEP_AR_NBR = ar_depo.unq_id_in_src_stm
and ar_depo_acm.tf_partition_date = '{{ var("business_date") }}'
{# bản gốc còn điều kiện hiệu lực của snapshot đứng trước điều kiện dưới đây:
   where '{{ var("business_date") }}' >= ar_depo.dbt_valid_from and  '{{ var("business_date") }}' < coalesce(ar_depo.dbt_valid_to,'2400-01-01') #}
where coalesce(ar_depo.end_dt,'2400-01-01') > '{{ var("business_date") }}'

UNION ALL
/* tập hợp đồng đóng  tại  ngày của nguồn ld */
SELECT
		'{{ var('business_date') }}'::DATE 					AS BUSINESS_DATE,
		{{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }}::TIMESTAMP AS PPN_DATE,
		ar_depo.UNQ_ID_IN_SRC_STM::VARCHAR(64)				AS CONTRACT_NBR,
		ar_depo_acm.CST_CODE::VARCHAR(64)					AS CUST_CODE,
		ar_depo_acm.CCY_CODE::VARCHAR(64)					AS CCY_CODE,
		ar_depo_intf.MGT_OU_CODE::VARCHAR(64)				AS MGMT_BRANCH_CODE,
		ar_depo.CGY_CODE::VARCHAR(64)						AS CATE_CODE,
		coalesce(ar_depo.END_DT,ar_depo.ACT_END_DT)::DATE		AS CLOSE_DATE,
		ar_depo_acm.INT_RATE::DECIMAL(8,5)					AS INST_RATE,
		ar_depo_intf.INT_PYMT_MTH::VARCHAR(20)				AS INST_PMT_METHOD,
		CASE WHEN ar_depo.end_dt = '{{ var("business_date") }}' THEN
			CASE WHEN '{{ var("business_date") }}'  <  ar_depo.EST_END_DT THEN 	'MAT_EARLY'
				WHEN  '{{ var("business_date") }}' >=  ar_depo.EST_END_DT THEN 	'MAT'
				else 'MAT'
			END
		END::VARCHAR(10) DEPO_CLOSE_TYPE,
		ar_depo_intf_prv.CLS_BAL_AMT_FCY::DECIMAL(23,5)		AS CLOSE_AMT_FCY,
		ar_depo.EST_END_DT::DATE							AS NOTION_MAT_DATE,
		CASE WHEN ar_depo.TF_SOURCE_SYSTEM IN ('T24_LD_LOANS_AND_DEPO')
		THEN
			CASE WHEN (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)< 28
	 			THEN (CASE (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)/7 WHEN 0 THEN 1 ELSE (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)/7 END)|| 'W'
	 			ELSE CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) || 'M'
			END
		ELSE
			CASE WHEN (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)< 28  THEN (ar_depo.EST_END_DT::date - ar_depo.EFF_DT::date)|| 'D'
			     WHEN CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) >120 AND CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) < 123 THEN '120M'
	 			ELSE CAST(ROUND(public.months_between(ar_depo.EST_END_DT::date, ar_depo.EFF_DT::date)) AS INTEGER) || 'M'
			END
		END::VARCHAR(32)									AS TERM,
		ar_depo.SUB_AR_CL_CODE::VARCHAR(32)								AS ACCT_SEPRT_TYPE,
		ar_depo.EFF_DT::DATE								AS VALUE_DATE
FROM
{{ ref('stg_ar_x_cl_pst_t24_depo_t24_ld__snp') }} ar_depo
left join {{ ref('stg_ar_depo_t24_ld_prfl__snp') }} ar_depo_intf on ar_depo_intf.DEP_AR_NBR = ar_depo.unq_id_in_src_stm
AND ar_depo_intf.tf_partition_date = '{{ var("business_date") }}'
{# bản gốc: left join ar_depo_t24_prfl__mnp ar_depo_intf_prv on ar_depo_intf_prv.DEP_AR_NBR = ar_depo.unq_id_in_src_stm
           AND ar_depo_intf_prv.tf_partition_date = CAST('{{ pre_last_wk_day }}' AS DATE) #}
left join ar_depo_t24_prfl_prv ar_depo_intf_prv on ar_depo_intf_prv.DEP_AR_NBR = ar_depo.unq_id_in_src_stm
left join {{ ref('stg_ar_depo_t24_ld_prfl__snp') }} ar_depo_acm on ar_depo_acm.DEP_AR_NBR = ar_depo.unq_id_in_src_stm
and ar_depo_acm.tf_partition_date = '{{ var("business_date") }}'
where ar_depo.end_dt = '{{ var("business_date") }}'
AND ar_depo.TF_SOURCE_SYSTEM IN ('T24_LD_LOANS_AND_DEPO')
