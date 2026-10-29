/*
*----------------------------------------------------------------------*
* Program code  : loan_contract_intf
* Program name  : Interface hợp đồng vay (L1)
* Mô tả         : Tập hợp đồng lấy từ stg_ar_x_cl_pst_t24_loan__snp, LEFT JOIN thuộc tính
*                 qua ba CTE ld_prfl, ld_acm, ld_add theo số hợp đồng; thiếu dòng chi tiết
*                 thì thuộc tính để trống, hợp đồng vẫn lên interface. Ba CTE dùng SELECT
*                 DISTINCT. Khối kiểm tra ngày đáo hạn ép năm sang số bằng ::int.
*                 pre_hook xóa dữ liệu của business_date trước khi nạp lại.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-103 Tạo mới
*                 2026-10-23 ducnm DWH-103 Chuyển sang cú pháp PostgreSQL (coalesce)
*----------------------------------------------------------------------*
*/

{% set eod_shared_src = "eod_shared" %}
{% set tbls_data_date = var('tbls_data_date') %}

{{
    config(
        pre_hook = "delete from {{ this }} where business_date = '{{ var('business_date') }}'"
    )
}}

-- CTE ld: phần đầu hợp đồng LD của ngày chạy, kèm ngày đáo hạn đã kiểm tra hợp lệ
with ld as
(
select
  ld.contract_no_
, ld.tf_partition_date
, ld.category
, LD.NO_OVD_DAYS
, CASE WHEN ld.FIN_MAT_DATE IS NULL THEN NULL
			WHEN substring(ld.FIN_MAT_DATE, 5, 2) IN ('01', '03', '05', '07', '08', '10', '12')
				AND substring(ld.FIN_MAT_DATE, 7, 2) BETWEEN '01' AND '31' THEN DATE(TO_DATE(ld.FIN_MAT_DATE, 'YYYYMMDD'))
			WHEN substring(ld.FIN_MAT_DATE, 5, 2) IN ('04', '06', '09', '11')
				AND substring(ld.FIN_MAT_DATE, 7, 2) BETWEEN '01' AND '30' THEN DATE(TO_DATE(ld.FIN_MAT_DATE, 'YYYYMMDD'))
			WHEN substring(ld.FIN_MAT_DATE, 5, 2) = '02' THEN
				CASE WHEN substring(ld.FIN_MAT_DATE, 7, 2) BETWEEN '01' AND '28' THEN DATE(TO_DATE(ld.FIN_MAT_DATE, 'YYYYMMDD'))
				WHEN substring(ld.FIN_MAT_DATE, 7, 2) = '29' THEN
					CASE

						WHEN (MOD(substring(trim(ld.FIN_MAT_DATE), 1, 4)::int, 4) = 0
						AND MOD(substring(trim(ld.FIN_MAT_DATE), 1, 4)::int, 100) <> 0)
						OR (MOD(substring(trim(ld.FIN_MAT_DATE), 1, 4)::int, 100) = 0
						AND MOD(substring(trim(ld.FIN_MAT_DATE), 1, 4)::int, 400) = 0) THEN DATE(TO_DATE(ld.FIN_MAT_DATE, 'YYYYMMDD'))
					END
				END
			ELSE DATE(TO_DATE('19000102', 'YYYYMMDD')) end as fin_mat_date
from {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
where ld.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'
)
-- CTE ld_prfl: thuộc tính hợp đồng (dư nợ gốc, lãi suất, kỳ hạn, tần suất điều chỉnh, tài khoản trả lãi)
, ld_prfl as
(
select distinct
      ld.contract_no_::VARCHAR(256) as AR_CODE
    , ld.VALUE_DATE::date as EFF_DT
    , coalesce(case when ld.category in ('21062','21063') then 0
                else ldd.amount end,0)::NUMERIC(23 , 5) as OUSTADING_AMT
    , CAST(ROUND(
    CASE
        WHEN LD.INT_RATE_TYPE = '1' THEN coalesce(LDD.INTEREST_RATE, 0)
        WHEN LD.INT_RATE_TYPE = '2' THEN coalesce(LDD.INTEREST_RATE, 0) + coalesce(LD.INTEREST_SPREAD, 0)
    END, 5) AS NUMERIC(8, 5)) AS INT_RATE
    , ld.TERM::VARCHAR(20) as STM_TERM
    , case when substring(ld.rate_change_fre,1,1) = '0' and ld.rate_change_fre <> '0M' then upper(substring(ld.rate_change_fre,2))::VARCHAR(32) else upper(ld.rate_change_fre)::VARCHAR(32) end as INT_RATE_RSET_TBND
    , ld.INT_LIQ_ACCT::VARCHAR(32) as INT_LQD_AC_AR_CODE
from {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
join {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo_details') }} ldd on ld.contract_no_ = ldd.contract_no_ and ldd.m = 1 and ldd.s = 1 and ldd.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo_details") }}'
where ld.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'
)
-- CTE ld_acm: ngày đáo hạn và số ngày quá hạn
, ld_acm as
(
select distinct
      ld.contract_no_::VARCHAR(256) as UNQ_ID_IN_SRC_STM
    , ld.FIN_MAT_DATE as NTNL_MAT_DT
    , LD.NO_OVD_DAYS::INT as NBR_ODUE_DAY
from ld
join {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo_details') }} ldd on ld.contract_no_ = ldd.contract_no_ and ldd.m = 1 and ldd.s = 1 and ldd.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo_details") }}'
)
-- CTE ld_add: khách hàng, category, loại tiền, tài khoản trả gốc, loại lãi suất
, ld_add as
(
select distinct
      ld.contract_no_::VARCHAR(256) as UNQ_ID_IN_SRC_STM
    , ld.PRIN_LIQ_ACCT::VARCHAR(32) as PNP_LQD_AC_AR_CODE
    , LD.CATEGORY::VARCHAR(64) as CGY_CODE
    , LD.CURRENCY::VARCHAR(64) as CCY_CODE
    , LD.CUSTOMER_ID::VARCHAR(64) as PRIM_CST_CODE
    , case when ld.INT_RATE_TYPE = '1' and coalesce(ld.int_ref_type,'Lai suat co dinh') = 'Lai suat co dinh' then 'FIXED'
        else 'FLOATING' end::VARCHAR(64) as RATE_VAR
from {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo') }} ld
join {{ source(eod_shared_src, 'raw_t24_ld_loans_and_depo_details') }} ldd on ld.contract_no_ = ldd.contract_no_ and ldd.m = 1 and ldd.s = 1 and ldd.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo_details") }}'
where ld.tf_partition_date = '{{ get_data_date_for_table( tbls_data_date, eod_shared_src, "raw_t24_ld_loans_and_depo") }}'
)
select
  to_date('{{ var("business_date") }}', 'yyyy-mm-dd') as business_date
, {{ dbt_date.convert_timezone("current_timestamp", "asia/ho_chi_minh") }}::timestamp as ppn_date
, ar_loan.unq_id_in_src_stm::VARCHAR(32) contract_nbr
, ld_add.prim_cst_code::varchar(64) cust_code
, ld_add.cgy_code::varchar(20) cate_code
, ld_add.ccy_code::varchar(3) ccy_code
, Case when ar_loan.unq_id_in_src_stm like 'PDPD%' then ld_prfl.EFF_DT else ar_loan.EFF_DT end::date value_date
, ld_acm.ntnl_mat_dt::date mat_date
, ld_prfl.stm_term::varchar(20) as term
, case when ar_loan.unq_id_in_src_stm like 'PDPD%' then 'FIXED' else ld_add.rate_var end::varchar(64) inst_rate_type
, ld_prfl.int_rate::numeric(8,5) inst_rate
, ld_prfl.int_rate_rset_tbnd::varchar(64) as inst_reset_freq
, ld_prfl.oustading_amt::NUMERIC(18,2) outs_prin_amt
, ld_add.pnp_lqd_ac_ar_code::varchar(64) prin_repay_acct_nbr
, ld_prfl.int_lqd_ac_ar_code::VARCHAR(64) inst_repay_acct_nbr
, ld_acm.nbr_odue_day::integer nbr_ovd_day
from {{ ref('stg_ar_x_cl_pst_t24_loan__snp') }} ar_loan
left join ld_prfl on ar_loan.unq_id_in_src_stm = ld_prfl.ar_code
left join ld_acm on ar_loan.unq_id_in_src_stm = ld_acm.unq_id_in_src_stm
left join ld_add on ar_loan.unq_id_in_src_stm = ld_add.unq_id_in_src_stm
