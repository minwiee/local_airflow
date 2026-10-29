/*
*----------------------------------------------------------------------*
* Program code  : stg_ar_depo_t24_ld_prfl__snp
* Program name  : Staging thuộc tính của hợp đồng LD (khách hàng, loại tiền, đơn vị, lãi suất, số dư)
* Mô tả         : Nối phần đầu hợp đồng với dòng chi tiết (m = 1, s = 1) của cùng ngày.
*                 Staging không lọc category hay trạng thái nên chứa cả hợp đồng vay; việc
*                 chọn hợp đồng tiền gửi nằm ở stg_ar_x_cl_pst_t24_depo_t24_ld__snp.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-102 Tạo mới
*----------------------------------------------------------------------*
*/

{% set eod_shared_src = "eod_shared" %}
{% set tbls_data_date = var('tbls_data_date') %}

Select  DISTINCT
	ld.CONTRACT_NO_::VARCHAR(64)					AS DEP_AR_NBR,
	ld.CUSTOMER_ID::VARCHAR(64)     				AS CST_CODE,
	ld.CURRENCY::VARCHAR(64)						AS CCY_CODE,
	ld.CO_CODE::VARCHAR(64)							AS MGT_OU_CODE,
	ldd.INTEREST_RATE::DECIMAL(8,5)					AS INT_RATE,
	CASE WHEN ld.INT_PAYMT_METHOD = '2' THEN 'DAU KY' ELSE 'CUOI KY' END::VARCHAR(20) 			AS INT_PYMT_MTH,
	ldd.AMOUNT::DECIMAL(23,5)						AS CLS_BAL_AMT_FCY,
	{{ gen_tf_cols_by_table_type('snp', 'T24_LD_LOANS_AND_DEPO') }}
FROM
{{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
LEFT JOIN {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo_details') }} ldd ON ld.CONTRACT_NO_ = ldd.CONTRACT_NO_
AND ldd.tf_partition_date  = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo_details") }}'::DATE
AND ldd.M = 1 AND ldd.S = 1
WHERE ld.tf_partition_date  = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'::DATE
