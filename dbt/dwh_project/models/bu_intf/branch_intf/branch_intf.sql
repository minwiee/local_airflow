/*
*----------------------------------------------------------------------*
* Program code  : branch_intf
* Program name  : Interface chi nhánh (L1)
* Mô tả         : Ghép dòng chi nhánh mặc định (vw_init_branch_intf_sap) với các đơn vị
*                 T24 (stg_branch_intf_t24__snp). Dòng của hệ thống nguồn khác do luồng
*                 riêng nạp và được giữ nguyên. pre_hook xóa dòng T24 của business_date
*                 trước khi nạp lại.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-101 Tạo mới
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{ this }} where BUSINESS_DATE = '{{ var('business_date') }}' and case when '{{ var('model_branch') }}' in ('T24_BANK_HH_COMPANY', 'T24_BANK_COMPANY', 'WAY4_F_I', 'CSV_MA_VIRTUAL_BRANCH') then SRC_SYS_CODE = '{{ var('model_branch') }}' else true end"
    )
}}

select * from {{ ref('vw_init_branch_intf_sap') }}
union all
select * from {{ ref('stg_branch_intf_t24__snp') }}
