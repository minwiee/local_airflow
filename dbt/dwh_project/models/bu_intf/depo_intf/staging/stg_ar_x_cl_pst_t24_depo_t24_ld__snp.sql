/*
*----------------------------------------------------------------------*
* Program code  : stg_ar_x_cl_pst_t24_depo_t24_ld__snp
* Program name  : Staging xác định hợp đồng LD nào là tiền gửi, kèm trạng thái và các mốc ngày
* Mô tả         : Category phải là T24-DEP-LD trong file MA map category của ngày chạy.
*                 value_date và fin_mat_date của nguồn là chuỗi YYYYMMDD nên được ép kiểu
*                 date; act_end_dt luôn trống với nguồn LD.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-102 Tạo mới
*----------------------------------------------------------------------*
*/

{% set dwh_ref_src = "dwh_ref" %}
{% set eod_shared_src = "eod_shared" %}
{% set tbls_data_date = var('tbls_data_date') %}

Select DISTINCT
	ld.VALUE_DATE::date eff_dt,
	CASE WHEN ld.STATUS in ('LIQ') THEN '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'::DATE ELSE null end::date end_dt,
	null::date act_end_dt,
	ld.FIN_MAT_DATE::date est_end_dt,
	CASE WHEN ld.STATUS in ('LIQ') THEN 'CLOSE' ELSE 'CUR' END::VARCHAR(256) sub_ar_cl_code,
	ld.CATEGORY::VARCHAR(64)						AS CGY_CODE,
	ld.CONTRACT_NO_::VARCHAR(50) unq_id_in_src_stm,
	{{ gen_tf_cols_by_table_type('snp', 'T24_LD_LOANS_AND_DEPO') }}
FROM
{{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
JOIN {{ source(dwh_ref_src, 'raw_csv_ma_map_cgy_ar_tp') }} cgy ON ld.CATEGORY = cgy.CATEGORY AND cgy.AR_TP = 'T24-DEP-LD'
AND cgy.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, dwh_ref_src, "raw_csv_ma_map_cgy_ar_tp") }}'::DATE
WHERE ld.tf_partition_date  = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'::DATE
AND ld.STATUS in ('CUR', 'LIQ') AND
CAST (ld.VALUE_DATE AS date)  <= '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'::DATE
 AND CAST (ld.FIN_MAT_DATE AS date)>='{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'::DATE
