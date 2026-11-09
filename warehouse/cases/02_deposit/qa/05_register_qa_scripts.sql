-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 02_deposit: đăng ký test case QA vào dwh_ref.csv_ma_automation_script__mnp

delete from dwh_ref.csv_ma_automation_script__mnp where testcase_id like 'TC02_%';

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC02_DEPO_INTF_COUNT_01', 'linhvt', 'depo_intf', 'DWH-102', 'contract_nbr', 'Số dòng ở đích bằng số hợp đồng tiền gửi LD đủ điều kiện ở nguồn', 'Count nguồn và đích', 'depo_intf_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - depo_intf: số dòng ở đích phải bằng số hợp đồng tiền gửi LD đủ điều kiện ở nguồn.
   Đủ điều kiện = có trong bản chụp LD của ngày chạy; category được file MA map của đúng ngày chạy
   xếp là tiền gửi (ar_tp = T24-DEP-LD); trạng thái CUR hoặc LIQ; ngày hiệu lực <= ngày chạy
   <= ngày đáo hạn. Nguồn đếm theo số hợp đồng (distinct), vì mỗi hợp đồng chỉ được một dòng ở đích. */
with src as (
    select count(distinct ld.contract_no_) as n
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    where ld.tf_partition_date = '#business_date#'
      and ld.status in ('CUR', 'LIQ')
      and to_date(ld.value_date, 'YYYYMMDD')   <= '#business_date#'
      and to_date(ld.fin_mat_date, 'YYYYMMDD') >= '#business_date#'
      and exists (select 1
                  from dwh_ref.csv_ma_map_cgy_ar_tp__mnp m
                  where m.category = ld.category
                    and m.ar_tp = 'T24-DEP-LD'
                    and m.tf_partition_date = '#business_date#')
),
tgt as (
    select count(*) as n
    from dwh_intf.depo_intf
    where business_date = '#business_date#'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC02_DEPO_INTF_DUP_01', 'linhvt', 'depo_intf', 'DWH-102', 'contract_nbr', 'Mỗi hợp đồng chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'depo_intf_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - depo_intf: trong một business date, mỗi contract_nbr chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select contract_nbr
    from dwh_intf.depo_intf
    where business_date = '#business_date#'
    group by contract_nbr
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC02_DEPO_INTF_DETAIL_01', 'linhvt', 'depo_intf', 'DWH-102', 'cust_code, ccy_code, mgmt_branch_code, cate_code, value_date, notion_mat_date, inst_rate, inst_pmt_method', 'Khách hàng, loại tiền, đơn vị, category, hai mốc ngày, lãi suất và phương thức trả lãi đúng theo BRD', 'Detail so hai chiều nguồn và đích', 'depo_intf_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - depo_intf: QA tự dựng lại 8 cột lấy thẳng từ nguồn theo BRD rồi so hai chiều với đích.
   cust_code, ccy_code, mgmt_branch_code, cate_code : khách hàng, loại tiền, đơn vị quản lý, category của hợp đồng LD.
   value_date, notion_mat_date : ngày hiệu lực, ngày đáo hạn (nguồn lưu chuỗi YYYYMMDD).
   inst_rate       : lãi suất của dòng chi tiết (m = 1, s = 1) cùng ngày; không có dòng đó thì trống.
   inst_pmt_method : int_paymt_method = 2 -> DAU KY; mọi giá trị khác, kể cả trống -> CUOI KY.
   Một dòng lệch ở bất kỳ cột nào cũng làm test fail. Trạng thái, tất toán, số dư kiểm ở DETAIL_02;
   kỳ hạn kiểm ở DETAIL_03. */
with elig as (
    select ld.*
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    where ld.tf_partition_date = '#business_date#'
      and ld.status in ('CUR', 'LIQ')
      and to_date(ld.value_date, 'YYYYMMDD')   <= '#business_date#'
      and to_date(ld.fin_mat_date, 'YYYYMMDD') >= '#business_date#'
      and exists (select 1
                  from dwh_ref.csv_ma_map_cgy_ar_tp__mnp m
                  where m.category = ld.category
                    and m.ar_tp = 'T24-DEP-LD'
                    and m.tf_partition_date = '#business_date#')
),
exp as (
    select e.contract_no_                        as contract_nbr
         , e.customer_id                         as cust_code
         , e.currency                            as ccy_code
         , e.co_code                             as mgmt_branch_code
         , e.category                            as cate_code
         , to_date(e.value_date, 'YYYYMMDD')     as value_date
         , to_date(e.fin_mat_date, 'YYYYMMDD')   as notion_mat_date
         , cast(d.interest_rate as numeric(8,5)) as inst_rate
         , case when e.int_paymt_method = '2' then 'DAU KY' else 'CUOI KY' end as inst_pmt_method
    from elig e
    left join raw_eod.t24_ld_loans_and_depo_details__mnp d
      on d.contract_no_ = e.contract_no_ and d.m = 1 and d.s = 1
     and d.tf_partition_date = '#business_date#'
),
act as (
    select contract_nbr, cust_code, ccy_code, mgmt_branch_code, cate_code, value_date, notion_mat_date
         , inst_rate, inst_pmt_method
    from dwh_intf.depo_intf
    where business_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC02_DEPO_INTF_DETAIL_02', 'linhvt', 'depo_intf', 'DWH-102', 'acct_seprt_type, close_date, depo_close_type, close_amt_fcy', 'Trạng thái, ngày tất toán, loại tất toán và số dư (hợp đồng tất toán lấy số dư ngày làm việc trước)', 'Detail so hai chiều quy tắc trạng thái và tất toán', 'depo_intf_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - depo_intf: quy tắc trạng thái và tất toán. QA tự tính từ nguồn rồi so hai chiều với đích.
   acct_seprt_type : hợp đồng LD ở trạng thái LIQ -> CLOSE; còn lại -> CUR.
   close_date      : hợp đồng LIQ -> ngày chạy; còn lại trống.
   depo_close_type : chỉ có với hợp đồng LIQ: ngày chạy < ngày đáo hạn -> MAT_EARLY (tất toán trước hạn);
                     ngày chạy >= ngày đáo hạn -> MAT.
   close_amt_fcy   : hợp đồng còn hiệu lực -> số tiền dòng chi tiết (m = 1, s = 1) của ngày chạy;
                     hợp đồng LIQ -> số tiền của ngày làm việc liền trước (hôm tất toán số dư đã về 0).
   Ngày làm việc liền trước: QA lấy partition gần nhất trước ngày chạy của bảng chi tiết LD
   (T24 chỉ sinh dữ liệu vào ngày làm việc). */
with prev_day as (
    select max(tf_partition_date) as d
    from raw_eod.t24_ld_loans_and_depo_details__mnp
    where tf_partition_date < '#business_date#'
),
elig as (
    select ld.contract_no_
         , ld.status
         , to_date(ld.fin_mat_date, 'YYYYMMDD') as mat_date
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    where ld.tf_partition_date = '#business_date#'
      and ld.status in ('CUR', 'LIQ')
      and to_date(ld.value_date, 'YYYYMMDD')   <= '#business_date#'
      and to_date(ld.fin_mat_date, 'YYYYMMDD') >= '#business_date#'
      and exists (select 1
                  from dwh_ref.csv_ma_map_cgy_ar_tp__mnp m
                  where m.category = ld.category
                    and m.ar_tp = 'T24-DEP-LD'
                    and m.tf_partition_date = '#business_date#')
),
exp as (
    select e.contract_no_ as contract_nbr
         , case when e.status = 'LIQ' then 'CLOSE' else 'CUR' end as acct_seprt_type
         , case when e.status = 'LIQ' then cast('#business_date#' as date) end as close_date
         , case when e.status = 'LIQ' then
                case when cast('#business_date#' as date) < e.mat_date then 'MAT_EARLY' else 'MAT' end
           end as depo_close_type
         , case when e.status = 'LIQ' then prv.amount else tdy.amount end as close_amt_fcy
    from elig e
    left join raw_eod.t24_ld_loans_and_depo_details__mnp tdy
      on tdy.contract_no_ = e.contract_no_ and tdy.m = 1 and tdy.s = 1
     and tdy.tf_partition_date = '#business_date#'
    left join raw_eod.t24_ld_loans_and_depo_details__mnp prv
      on prv.contract_no_ = e.contract_no_ and prv.m = 1 and prv.s = 1
     and prv.tf_partition_date = (select d from prev_day)
),
act as (
    select contract_nbr, acct_seprt_type, close_date, depo_close_type, close_amt_fcy
    from dwh_intf.depo_intf
    where business_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC02_DEPO_INTF_DETAIL_03', 'linhvt', 'depo_intf', 'DWH-102', 'term', 'Kỳ hạn: dưới 28 ngày tính theo tuần (W), từ 28 ngày tính theo tháng làm tròn (M)', 'Detail quy tắc kỳ hạn', 'depo_intf_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - depo_intf.term: kỳ hạn tính từ ngày hiệu lực đến ngày đáo hạn của hợp đồng LD.
   Dưới 28 ngày : số tuần = số ngày chia 7 lấy phần nguyên, ra 0 thì tính là 1; ghi kèm chữ W (ví dụ 3W).
   Từ 28 ngày   : số tháng giữa hai ngày, làm tròn về số nguyên gần nhất; ghi kèm chữ M (ví dụ 12M).
   Số tháng theo quy ước months_between: hai ngày cùng "ngày trong tháng" hoặc cùng là ngày cuối tháng
   thì chẵn tháng; nếu không, phần lẻ = chênh lệch ngày / 31.
   Số tháng tính bằng hàm dùng chung public.months_between (common/sql/03_functions.sql);
   số ngày = ngày đáo hạn trừ ngày hiệu lực. */
with src as (
    select ld.contract_no_
         , to_date(ld.value_date, 'YYYYMMDD')   as val_date
         , to_date(ld.fin_mat_date, 'YYYYMMDD') as mat_date
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    where ld.tf_partition_date = '#business_date#'
),
exp as (
    select contract_no_
         , case when (mat_date - val_date) < 28
                then cast(greatest((mat_date - val_date) / 7, 1) as varchar(10)) || 'W'
                else cast(cast(round(public.months_between(mat_date, val_date)) as integer) as varchar(10)) || 'M'
           end as term
    from src
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from dwh_intf.depo_intf a
left join exp e on e.contract_no_ = a.contract_nbr
where a.business_date = '#business_date#'
  and coalesce(a.term, '') <> coalesce(e.term, '')$qa$, null, 'daily', '1', '50', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC02_BI_DEPO_INFO_COUNT_01', 'linhvt', 'bi_depo_info_intf__mnp', 'DWH-102', 'contract_nbr', 'Số dòng layer 2 bằng số hợp đồng còn mở của depo_intf', 'Count interface L1 và layer 2', 'bi_depo_info_intf__mnp_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - bi_depo_info_intf__mnp: số dòng layer 2 phải bằng số hợp đồng còn mở của depo_intf cùng ngày.
   Hợp đồng tất toán trong ngày (acct_seprt_type = CLOSE, không phân biệt hoa thường) không được lên layer 2. */
with src as (
    select count(*) as n
    from dwh_intf.depo_intf
    where business_date = '#business_date#'
      and upper(coalesce(acct_seprt_type, 'N/A')) <> 'CLOSE'
),
tgt as (
    select count(*) as n
    from bi_intf.bi_depo_info_intf__mnp
    where tf_partition_date = '#business_date#'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC02_BI_DEPO_INFO_DUP_01', 'linhvt', 'bi_depo_info_intf__mnp', 'DWH-102', 'contract_nbr', 'Mỗi hợp đồng chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'bi_depo_info_intf__mnp_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - bi_depo_info_intf__mnp: trong một tf_partition_date, mỗi contract_nbr chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select contract_nbr
    from bi_intf.bi_depo_info_intf__mnp
    where tf_partition_date = '#business_date#'
    group by contract_nbr
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC02_BI_DEPO_INFO_DETAIL_01', 'linhvt', 'bi_depo_info_intf__mnp', 'DWH-102', '9 cột lấy từ depo_intf và tf_source_system', 'Các cột lấy thẳng từ depo_intf đúng theo BRD, chỉ gồm hợp đồng còn mở', 'Detail so hai chiều L1 và layer 2', 'bi_depo_info_intf__mnp_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - bi_depo_info_intf__mnp: các cột lấy thẳng từ depo_intf của cùng ngày
   (khách hàng, loại tiền, category, ngày đáo hạn, lãi suất, số dư, trạng thái; eff_date là value_date
   đổi tên). Chỉ hợp đồng còn mở mới có ở layer 2 và nguồn ghi nhận phải là DEPO_INTF. So hai chiều. */
with exp as (
    select d.contract_nbr
         , d.cust_code
         , d.ccy_code
         , d.cate_code
         , d.value_date      as eff_date
         , d.notion_mat_date
         , d.inst_rate
         , d.close_amt_fcy
         , d.acct_seprt_type
         , 'DEPO_INTF'       as tf_source_system
    from dwh_intf.depo_intf d
    where d.business_date = '#business_date#'
      and upper(coalesce(d.acct_seprt_type, 'N/A')) <> 'CLOSE'
),
act as (
    select contract_nbr, cust_code, ccy_code, cate_code, eff_date, notion_mat_date
         , inst_rate, close_amt_fcy, acct_seprt_type, tf_source_system
    from bi_intf.bi_depo_info_intf__mnp
    where tf_partition_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC02_BI_DEPO_INFO_DETAIL_02', 'linhvt', 'bi_depo_info_intf__mnp', 'DWH-102', 'prd_group_name, bi_term', 'Nhóm sản phẩm tra từ file MA của đúng ngày chạy và kỳ hạn BI tính theo bậc số ngày', 'Detail quy tắc nhóm sản phẩm và kỳ hạn BI', 'bi_depo_info_intf__mnp_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - bi_depo_info_intf__mnp: nhóm sản phẩm và kỳ hạn BI.
   prd_group_name : nhóm của category trong file MA csv_partb_product của đúng ngày chạy; không có thì trống.
   bi_term (tháng): chỉ tính khi nhóm là 2. TERM DEPOSIT (không phân biệt hoa thường), theo số ngày n
                    từ ngày hiệu lực đến ngày đáo hạn:
                      n <= 10 -> 0.25;  11-17 -> 0.5;  18-27 -> 0.75;  28-45 -> 1;
                      46-365  -> n / 30 làm tròn;
                      n >= 366 -> n * 12 / 365 làm tròn, riêng kết quả 12 hoặc 13 thì ghi 13.
                    Nhóm khác hoặc không có nhóm -> trống.
   bi_term lưu dạng chuỗi; số chữ số thập phân của chuỗi phụ thuộc scale của giá trị số ('0.25', '1', '13'),
   nên so theo giá trị số. n = ngày đáo hạn trừ ngày hiệu lực (ngày trừ ngày ra số ngày). */
with act as (
    select t.contract_nbr
         , t.prd_group_name
         , t.bi_term
         , (t.notion_mat_date - t.eff_date) as n
         , p.prd_group
    from bi_intf.bi_depo_info_intf__mnp t
    left join bi_ref.csv_partb_product__mnp p
      on p.prd_code = t.cate_code
     and p.tf_partition_date = '#business_date#'
    where t.tf_partition_date = '#business_date#'
),
chk as (
    select a.*
         , case when upper(a.prd_group) = '2. TERM DEPOSIT' then
                case when a.n <= 10  then 0.25
                     when a.n <= 17  then 0.5
                     when a.n <= 27  then 0.75
                     when a.n <= 45  then 1
                     when a.n <= 365 then round(a.n / 30.0)
                     when round(a.n * 12 / 365.0) in (12, 13) then 13
                     else round(a.n * 12 / 365.0)
                end
           end as exp_bi_term
    from act a
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from chk
where coalesce(prd_group_name, '') <> coalesce(prd_group, '')
   or coalesce(cast(bi_term as numeric(10,2)), -1) <> coalesce(exp_bi_term, -1)$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);
