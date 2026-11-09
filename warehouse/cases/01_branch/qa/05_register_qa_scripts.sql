-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 01_branch: đăng ký test case QA vào dwh_ref.csv_ma_automation_script__mnp

delete from dwh_ref.csv_ma_automation_script__mnp where testcase_id like 'TC01_%';

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC01_BRANCH_INTF_COUNT_01', 'linhvt', 'branch_intf', 'DWH-101', 'branch_code', 'Số đơn vị T24 ở đích bằng số đơn vị nguồn đủ điều kiện', 'Count nguồn và đích của nhánh T24', 'branch_intf_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - branch_intf: số đơn vị T24 ở đích phải bằng số đơn vị nguồn đủ điều kiện.
   Nguồn đủ điều kiện = có trong BANK.COMPANY của ngày chạy, có dòng tên (m = 1, s = 1)
   cùng ngày và có bản ghi COMPANY còn hiệu lực. Không tính dòng mặc định ZZZZZZZZZ. */
with src as (
    select count(*) as n
    from dwh_stag_eod.stg_raw_t24_bank_company__mnp tvc
    where tvc.tf_partition_date = '#business_date#'
      and exists (select 1
                  from dwh_stag_eod.stg_raw_t24_bank_company_details__mnp d
                  where d.id = tvc.id and d.m = 1 and d.s = 1
                    and d.tf_partition_date = '#business_date#')
      and exists (select 1
                  from raw_eod.t24_company__s2 c
                  where c.company_code = tvc.id
                    and c.tf_created_at <= '#business_date#'
                    and c.tf_updated_at > '#business_date#')
),
tgt as (
    select count(*) as n
    from dwh_intf.branch_intf
    where business_date = '#business_date#'
      and src_sys_code = 'T24_BANK_COMPANY'
      and branch_code <> 'ZZZZZZZZZ'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC01_BRANCH_INTF_DUP_01', 'linhvt', 'branch_intf', 'DWH-101', 'branch_code, src_sys_code', 'Mỗi đơn vị của một hệ thống nguồn chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'branch_intf_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - branch_intf: trong một business date, mỗi (branch_code, src_sys_code) chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select branch_code, src_sys_code
    from dwh_intf.branch_intf
    where business_date = '#business_date#'
    group by branch_code, src_sys_code
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC01_BRANCH_INTF_DETAIL_01', 'linhvt', 'branch_intf', 'DWH-101', '13 cột trừ branch_name', 'Mã book, vùng, tỉnh/thành và các cột lấy thẳng đúng theo BRD', 'Detail so hai chiều nguồn và đích', 'branch_intf_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - branch_intf: QA tự dựng lại 13 cột từ nguồn theo BRD rồi so hai chiều với đích.
   Một dòng lệch ở bất kỳ cột nào cũng làm test fail. Tên chi nhánh kiểm ở DETAIL_02. */
with exp as (
    select tvc.id                                  as branch_code
         , tvc.from_date                           as value_date
         , tvc.to_date                             as actual_end_date
         , tvc.segment                             as division
         , tvc.main_branch_code                    as main_branch_code
         , tc.mnemonic                             as book_code
         , tcm.mnemonic                            as main_book_code
         , tvc.region_khcn_code                    as retail_region_code
         , coalesce(cv.cl_nm, tvc.region_khcn_name) as retail_region_name
         , tvc.status                              as branch_status
         , tvc.region                              as geo_zone
         , upper(tvc.branch_type)                  as branch_type
         , case when length(tvc.code_province) = 1 then '0' || tvc.code_province
                else tvc.code_province end         as provin_code
         , upper(pv.province_name)                 as provin_name
    from dwh_stag_eod.stg_raw_t24_bank_company__mnp tvc
    join dwh_stag_eod.stg_raw_t24_bank_company_details__mnp d
      on d.id = tvc.id and d.m = 1 and d.s = 1
     and d.tf_partition_date = '#business_date#'
    join raw_eod.t24_company__s2 tc
      on tc.company_code = tvc.id
     and tc.tf_created_at <= '#business_date#' and tc.tf_updated_at > '#business_date#'
    left join raw_eod.t24_company__s2 tcm
      on tcm.company_code = tvc.main_branch_code
     and tcm.tf_created_at <= '#business_date#' and tcm.tf_updated_at > '#business_date#'
    left join dwh_stag_eod.stg_raw_t24_bank_province_details__mnp pv
      on pv.id = tvc.code_province and pv.province_name is not null
     and pv.tf_partition_date = '#business_date#'
    left join dwh_ref.csv_cv__mnp cv
      on cv.cl_code = tvc.region_khcn_code and cv.cl_scm_id in ('209', '265', '266')
     and cv.tf_partition_date = '#business_date#'
    where tvc.tf_partition_date = '#business_date#'
),
act as (
    select branch_code, value_date, actual_end_date, division, main_branch_code, book_code, main_book_code
         , retail_region_code, retail_region_name, branch_status, geo_zone, branch_type, provin_code, provin_name
    from dwh_intf.branch_intf
    where business_date = '#business_date#'
      and src_sys_code = 'T24_BANK_COMPANY'
      and branch_code <> 'ZZZZZZZZZ'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC01_BRANCH_INTF_DETAIL_02', 'linhvt', 'branch_intf', 'DWH-101', 'branch_name', 'Tên ghép từ các dòng tên theo thứ tự m rồi s', 'Detail tên chi nhánh', 'branch_intf_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - branch_intf.branch_name: tên là các dòng tên của đơn vị ghép lại bằng dấu cách,
   theo thứ tự m rồi s, cắt còn 64 ký tự. */
with exp as (
    select d.id as branch_code
         , string_agg(d.branch_name, ' ' order by d.m, d.s) as branch_name
    from dwh_stag_eod.stg_raw_t24_bank_company_details__mnp d
    where d.tf_partition_date = '#business_date#'
    group by d.id
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from dwh_intf.branch_intf a
left join exp e on e.branch_code = a.branch_code
where a.business_date = '#business_date#'
  and a.src_sys_code = 'T24_BANK_COMPANY'
  and a.branch_code <> 'ZZZZZZZZZ'
  and coalesce(a.branch_name, '') <> coalesce(left(e.branch_name, 64), '')$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC01_BI_BRANCH_INFO_COUNT_01', 'linhvt', 'bi_branch_info_intf__mnp', 'DWH-101', 'branch_id', 'Số dòng layer 2 bằng số chi nhánh T24 của branch_intf', 'Count interface L1 và layer 2', 'bi_branch_info_intf__mnp_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - bi_branch_info_intf__mnp: số dòng layer 2 phải bằng số chi nhánh T24 của branch_intf
   cùng ngày, không tính dòng mặc định ZZZZZZZZZ và không tính hệ thống nguồn khác. */
with src as (
    select count(*) as n
    from dwh_intf.branch_intf
    where business_date = '#business_date#'
      and src_sys_code = 'T24_BANK_COMPANY'
      and branch_code <> 'ZZZZZZZZZ'
),
tgt as (
    select count(*) as n
    from bi_intf.bi_branch_info_intf__mnp
    where tf_partition_date = '#business_date#'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC01_BI_BRANCH_INFO_DUP_01', 'linhvt', 'bi_branch_info_intf__mnp', 'DWH-101', 'branch_id', 'Mỗi chi nhánh chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'bi_branch_info_intf__mnp_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - bi_branch_info_intf__mnp: trong một tf_partition_date, mỗi branch_id chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select branch_id
    from bi_intf.bi_branch_info_intf__mnp
    where tf_partition_date = '#business_date#'
    group by branch_id
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC01_BI_BRANCH_INFO_DETAIL_01', 'linhvt', 'bi_branch_info_intf__mnp', 'DWH-101', '11 cột lấy từ branch_intf', 'Mã, tên, nhóm, miền, tỉnh/thành, cờ đã đóng đúng theo BRD', 'Detail so hai chiều L1 và layer 2', 'bi_branch_info_intf__mnp_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - bi_branch_info_intf__mnp: các cột lấy thẳng hoặc biến đổi đơn giản từ branch_intf
   (mã, tên, nhóm, miền, loại, tỉnh/thành bỏ tiền tố "TP ", khối, cờ đã đóng). So hai chiều. */
with exp as (
    select br.book_code                                as branch_code
         , br.branch_code                              as branch_id
         , br.branch_name                              as branch_name
         , br.main_book_code                           as branch_group_code
         , br.main_branch_code                         as branch_group_id
         , br.geo_zone                                 as region_code
         , br.branch_type                              as branch_type
         , replace(br.provin_name, 'TP ', '')          as city_code
         , br.division                                 as division
         , case when br.actual_end_date < '#business_date#' then '1' end as is_delete
         , br.src_sys_code                             as src_sys_code
    from dwh_intf.branch_intf br
    where br.business_date = '#business_date#'
      and br.src_sys_code = 'T24_BANK_COMPANY'
      and br.branch_code <> 'ZZZZZZZZZ'
),
act as (
    select branch_code, branch_id, branch_name, branch_group_code, branch_group_id, region_code
         , branch_type, city_code, division, rtrim(is_delete) as is_delete, src_sys_code
    from bi_intf.bi_branch_info_intf__mnp
    where tf_partition_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC01_BI_BRANCH_INFO_DETAIL_02', 'linhvt', 'bi_branch_info_intf__mnp', 'DWH-101', 'retail_zone_id, retail_zone_name, region_new_name', 'Chuẩn hóa mã vùng và tên vùng bán lẻ', 'Detail quy tắc vùng bán lẻ', 'bi_branch_info_intf__mnp_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - bi_branch_info_intf__mnp: quy tắc chuẩn hóa vùng bán lẻ.
   retail_zone_id   : mã trống -> OTH; mã 2 ký tự (R1) -> thêm số 0 (R01); còn lại giữ nguyên.
   retail_zone_name : tên trống -> VUNG KHAC; thiếu tiền tố "VUNG " thì thêm; nếu sau khi chuẩn hóa
                      dài đúng 6 ký tự (VUNG 1) -> thêm số 0 (VUNG 01); còn lại giữ nguyên tên gốc.
   region_new_name  : R1-R6 -> BAC; R7-R11 -> NAM; còn lại trống. */
with src as (
    select br.branch_code as branch_id
         , br.retail_region_code as code
         , br.retail_region_name as name
         , case when br.retail_region_name like 'VUNG %' then br.retail_region_name
                else 'VUNG ' || trim(replace(br.retail_region_name, 'VUNG', '')) end as norm_name
    from dwh_intf.branch_intf br
    where br.business_date = '#business_date#'
      and br.src_sys_code = 'T24_BANK_COMPANY'
      and br.branch_code <> 'ZZZZZZZZZ'
),
exp as (
    select branch_id
         , case when code is null then 'OTH'
                when length(code) = 2 then replace(code, 'R', 'R0')
                else code end as retail_zone_id
         , case when name is null then 'VUNG KHAC'
                when length(norm_name) = 6 then replace(norm_name, 'VUNG ', 'VUNG 0')
                else name end as retail_zone_name
         , case when replace(code, 'R0', 'R') in ('R1', 'R2', 'R3', 'R4', 'R5', 'R6') then 'BAC'
                when replace(code, 'R0', 'R') in ('R7', 'R8', 'R9', 'R10', 'R11') then 'NAM'
           end as region_new_name
    from src
),
act as (
    select branch_id, retail_zone_id, retail_zone_name, region_new_name
    from bi_intf.bi_branch_info_intf__mnp
    where tf_partition_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC01_BI_BRANCH_INFO_DETAIL_03', 'linhvt', 'bi_branch_info_intf__mnp', 'DWH-101', 'zone_code_new, zone_name_new_vn, zone_name_new, zone_type, hub_af_flag', 'Tra khu vực RBD từ file MA của đúng ngày chạy', 'Detail các cột tra từ nguồn phụ', 'bi_branch_info_intf__mnp_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - bi_branch_info_intf__mnp: các cột tra từ file MA khu vực RBD của đúng ngày chạy.
   Chi nhánh không có trong file thì cả 5 cột để trống. Tên khu vực không dấu (zone_name_new)
   phải cùng độ dài với tên có dấu và chỉ gồm ký tự ASCII. */
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from bi_intf.bi_branch_info_intf__mnp t
left join bi_ref.csv_ma_rbd_branch_area__mnp ba
  on ba.branch_id = t.branch_id
 and ba.tf_partition_date = '#business_date#'
where t.tf_partition_date = '#business_date#'
  and (   coalesce(t.zone_code_new, '')    <> coalesce(ba.area_code, '')
       or coalesce(t.zone_name_new_vn, '') <> coalesce(ba.area_name, '')
       or coalesce(t.zone_type, '')        <> coalesce(ba.branch_type, '')
       or coalesce(t.hub_af_flag, '')      <> coalesce(ba.hub_af, '')
       or length(coalesce(t.zone_name_new, '')) <> length(coalesce(ba.area_name, ''))
       or coalesce(t.zone_name_new, '') !~ '^[ -~]*$'
      )$qa$, null, 'daily', '1', '50', localtimestamp, current_date - 1);
