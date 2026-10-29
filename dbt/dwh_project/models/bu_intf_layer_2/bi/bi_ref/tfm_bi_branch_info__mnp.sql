/*
*----------------------------------------------------------------------*
* Program code  : tfm_bi_branch_info__mnp
* Program name  : Transform BI Branch Information Multi Snapshot
* Mô tả         : Chuẩn hóa vùng bán lẻ, miền, cờ đã đóng của chi nhánh T24 trong
*                 branch_intf; tra khu vực RBD từ file MA của đúng ngày chạy.
* Created by    : ducnm
* Change log    : 2026-10-02 ducnm DWH-101 Tạo mới
*----------------------------------------------------------------------*
*/

{{
    config(
        pre_hook = "delete from {{this}} where tf_partition_date = '{{var('business_date')}}'"
    )
}}

{% set bi_ref_src = "bi_ref" %}

select br.book_code::varchar(64) as branch_code
    , br.branch_code::varchar(64) as branch_id
    , br.branch_name::varchar(255) as branch_name
    , br.main_book_code::varchar(64) as branch_group_code
    , br.main_branch_code::varchar(64) as branch_group_id
    , br.geo_zone::varchar(64) as region_code
    , br.branch_type::varchar(64) as branch_type
    , replace(br.provin_name, 'TP ', '')::varchar(64) as city_code
    , case
        when length(br.retail_region_code) = 2 then replace(br.retail_region_code,'R','R0')
        else coalesce(br.retail_region_code,'OTH')
    end::varchar(64) as retail_zone_id
    , case
        when length(
            case
                when br.retail_region_name not like 'VUNG %' then 'VUNG ' || trim(replace(br.retail_region_name, 'VUNG', ''))
                else br.retail_region_name
            end
        ) = 6
            then
                replace (
                    case
                        when br.retail_region_name not like 'VUNG %' then 'VUNG ' || trim(replace(br.retail_region_name, 'VUNG', ''))
                        else br.retail_region_name
                    end
                    , 'VUNG '
                    , 'VUNG 0'
                )
        else
            case
                when br.retail_region_name = 'VUNG1' then 'VUNG 1'
                else coalesce(br.retail_region_name, 'VUNG KHAC')
            end
        end::varchar(255) as retail_zone_name
    , br.division::varchar(64) as division
    , case
        when br.retail_region_code in ('R01','R02','R03','R04','R05','R06','R1','R2','R3','R4','R5','R6') then 'BAC'
        when br.retail_region_code in ('R07','R08','R09','R10','R11','R7','R8','R9') then 'NAM'
        else null
    end::varchar(255) as region_new_name
    , case
        when br.actual_end_date < '{{ var("business_date") }}'::date then '1'
        else null
    end::char(18) as is_delete
    , ba.area_code::varchar(255) as zone_code_new
    , ba.area_name::varchar(255) as zone_name_new_vn
    , {{ translate_vietnamese_accent_macro('ba.area_name') }}::varchar(255) as zone_name_new
    , ba.branch_type::varchar(64) as zone_type
    , ba.hub_af::varchar(64) as hub_af_flag
    , br.src_sys_code::varchar(64) as src_sys_code
    , {{ gen_tf_cols_by_table_type('mnp','BRANCH_INTF') }}
from {{ref('branch_intf')}} BR
left join {{ source(bi_ref_src,'raw_csv_ma_rbd_branch_area') }} ba
    on ba.branch_id = br.branch_code
        and ba.tf_partition_date = '{{ var("business_date") }}'
where 1=1
    and BR.BRANCH_CODE <> 'ZZZZZZZZZ'
    and BR.SRC_SYS_CODE = 'T24_BANK_COMPANY'
    and BR.BUSINESS_DATE = '{{ var("business_date") }}'
