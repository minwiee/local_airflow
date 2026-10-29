/*
*----------------------------------------------------------------------*
* Program code  : stg_ar_x_cl_pst_t24_loan__snp
* Program name  : Staging tập hợp đồng vay T24 LD của LOAN_CONTRACT_INTF
* Mô tả         : Model này quyết định hợp đồng nào được lên interface: hợp đồng có trong LD
*                 ngày chạy, category xếp loại T24-LOAN-LD trong file MA của ngày chạy và
*                 tổng số dư GL khác 0 (gồm dòng nợ quá hạn PDLD, bỏ SBV.9995 và SBV.9996).
*                 Dùng SELECT DISTINCT để mỗi hợp đồng chỉ có một dòng.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-103 Tạo mới
*----------------------------------------------------------------------*
*/

{% set dwh_ref_src = "dwh_ref" %}
{% set eod_shared_src = "eod_shared" %}
{% set tbls_data_date = var('tbls_data_date') %}

WITH tfm_re_crf_sbv as
( select
	  CASE WHEN t.mud_code = 'PD' AND SUBSTRING(t.ctr_no,1,4) <> 'PDPD' THEN SUBSTRING(t.ctr_no,3) ELSE t.ctr_no END contract_nbr
	, sum(t.deal_bal_lcy) as src_close_amt_lcy
from {{ ref('tfm_re_crf_sbv__mnp') }} t
where t.mud_code in ('LD','PD')
and t.desc_3 NOT IN ('SBV.9995', 'SBV.9996')
and t.tf_partition_date = '{{ var("business_date") }}'
 GROUP BY  contract_nbr
) , loan_ar as
(
	SELECT ld.CONTRACT_NO_ AS CONTRACT_NO
			, ld.CATEGORY
			, ld.VALUE_DATE
			, 'T24_LD_LOANS_AND_DEPO' AS SRC_STM_ID
			, ld.tf_partition_date::DATE
	FROM {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
	where ld.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'
)
-- (1) Hợp đồng thỏa mãn điều kiện GL và có tổng DEAL_LCY_BALANCE theo LD + PDLD, PDPD lên GL ngày hôm đấy <> 0
SELECT DISTINCT
	ld.VALUE_DATE::date eff_dt,
	ld.CONTRACT_NO::VARCHAR(50) unq_id_in_src_stm,
	'{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    NULL::TIMESTAMP AS TF_SOURCING_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{ var("business_date") }}'::date as TF_PARTITION_DATE,
    ld.SRC_STM_ID::VARCHAR(64) TF_SOURCE_SYSTEM
FROM loan_ar ld
INNER JOIN {{ source(dwh_ref_src, 'raw_csv_ma_map_cgy_ar_tp') }} c ON ld.CATEGORY = c.CATEGORY AND c.AR_TP = 'T24-LOAN-LD' and c.tf_partition_date = '{{ var("business_date") }}'
INNER JOIN tfm_re_crf_sbv CRF ON ld.CONTRACT_NO = CRF.contract_nbr and CRF.src_close_amt_lcy <> 0
