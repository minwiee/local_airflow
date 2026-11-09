-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 03_loan: đăng ký test case QA vào dwh_ref.csv_ma_automation_script__mnp

delete from dwh_ref.csv_ma_automation_script__mnp where testcase_id like 'TC03_%';

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC03_LOAN_CONTRACT_INTF_COUNT_01', 'linhvt', 'loan_contract_intf', 'DWH-103', 'contract_nbr', 'Số hợp đồng ở đích bằng số hợp đồng vay đủ điều kiện ở nguồn', 'Count nguồn và đích', 'loan_contract_intf_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - loan_contract_intf: số hợp đồng ở đích phải bằng số hợp đồng vay đủ điều kiện ở nguồn.
   Hợp đồng đủ điều kiện = có trong bảng LD của ngày chạy, category được file MA xếp loại T24-LOAN-LD
   trong ngày chạy (tiền gửi T24-DEP-LD bị loại), và tổng số dư GL của hợp đồng trong ngày chạy khác 0.
   Số dư GL của hợp đồng = các dòng phân hệ LD cộng các dòng nợ quá hạn của nó (phân hệ PD, số PDLD...
   tính về số LD...), không tính tài khoản SBV.9995 và SBV.9996. Hợp đồng PD độc lập (PDPD...) giữ nguyên số. */
with gl as (
    select case when mud_code = 'PD' and left(ctr_no, 4) <> 'PDPD'
                then right(ctr_no, length(ctr_no) - 2)
                else ctr_no end as contract_no
         , sum(deal_bal_lcy) as balance
    from dwh_ref.tfm_re_crf_sbv__mnp
    where tf_partition_date = '#business_date#'
      and mud_code in ('LD', 'PD')
      and desc_3 not in ('SBV.9995', 'SBV.9996')
    group by 1
),
src as (
    select count(distinct ld.contract_no_) as n
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    where ld.tf_partition_date = '#business_date#'
      and exists (select 1
                  from dwh_ref.csv_ma_map_cgy_ar_tp__mnp m
                  where m.category = ld.category and m.ar_tp = 'T24-LOAN-LD'
                    and m.tf_partition_date = '#business_date#')
      and exists (select 1
                  from gl
                  where gl.contract_no = ld.contract_no_ and gl.balance <> 0)
),
tgt as (
    select count(*) as n
    from dwh_intf.loan_contract_intf
    where business_date = '#business_date#'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC03_LOAN_CONTRACT_INTF_DUP_01', 'linhvt', 'loan_contract_intf', 'DWH-103', 'contract_nbr', 'Mỗi hợp đồng chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'loan_contract_intf_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - loan_contract_intf: trong một business date, mỗi contract_nbr chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select contract_nbr
    from dwh_intf.loan_contract_intf
    where business_date = '#business_date#'
    group by contract_nbr
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC03_LOAN_CONTRACT_INTF_DETAIL_01', 'linhvt', 'loan_contract_intf', 'DWH-103', '10 cột: khách hàng, category, loại tiền, ngày hiệu lực, kỳ hạn, tài khoản trả nợ, số ngày quá hạn, dư nợ gốc', 'Tập hợp đồng, các cột lấy thẳng và dư nợ gốc đúng theo BRD', 'Detail so hai chiều nguồn và đích', 'loan_contract_intf_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - loan_contract_intf: các cột lấy thẳng từ hợp đồng LD và dư nợ gốc.
   QA tự dựng lại tập hợp đồng đủ điều kiện (như test COUNT) cùng 10 cột dưới đây rồi so hai chiều với đích.
   Một dòng thiếu, thừa hoặc lệch ở bất kỳ cột nào cũng làm test fail.
   - value_date lấy từ phần đầu hợp đồng (chuỗi YYYYMMDD đổi sang kiểu ngày).
   - cust_code, cate_code, ccy_code, term, hai tài khoản trả nợ và số ngày quá hạn chỉ có khi hợp đồng có dòng
     chi tiết (m = 1, s = 1) của ngày chạy. Thiếu dòng đó thì hợp đồng vẫn lên interface nhưng các cột này để trống.
   - outs_prin_amt = số tiền của dòng chi tiết (m = 1, s = 1), trống thì tính là 0, làm tròn 2 số lẻ;
     riêng category 21062 và 21063 luôn bằng 0.
   Lãi suất kiểm ở DETAIL_02, ngày đáo hạn kiểm ở DETAIL_03. */
with gl as (
    select case when mud_code = 'PD' and left(ctr_no, 4) <> 'PDPD'
                then right(ctr_no, length(ctr_no) - 2)
                else ctr_no end as contract_no
         , sum(deal_bal_lcy) as balance
    from dwh_ref.tfm_re_crf_sbv__mnp
    where tf_partition_date = '#business_date#'
      and mud_code in ('LD', 'PD')
      and desc_3 not in ('SBV.9995', 'SBV.9996')
    group by 1
),
univ as (
    select distinct ld.contract_no_, ld.category, ld.customer_id, ld.currency, ld.value_date, ld.term
         , ld.prin_liq_acct, ld.int_liq_acct, ld.no_ovd_days
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    where ld.tf_partition_date = '#business_date#'
      and exists (select 1
                  from dwh_ref.csv_ma_map_cgy_ar_tp__mnp m
                  where m.category = ld.category and m.ar_tp = 'T24-LOAN-LD'
                    and m.tf_partition_date = '#business_date#')
      and exists (select 1
                  from gl
                  where gl.contract_no = ld.contract_no_ and gl.balance <> 0)
),
exp as (
    select u.contract_no_                                               as contract_nbr
         , to_date(u.value_date, 'YYYYMMDD')                            as value_date
         , case when d.contract_no_ is not null then u.customer_id end   as cust_code
         , case when d.contract_no_ is not null then u.category end      as cate_code
         , case when d.contract_no_ is not null then u.currency end      as ccy_code
         , case when d.contract_no_ is not null then u.term end          as term
         , case when d.contract_no_ is not null then u.prin_liq_acct end as prin_repay_acct_nbr
         , case when d.contract_no_ is not null then u.int_liq_acct end  as inst_repay_acct_nbr
         , case when d.contract_no_ is not null then u.no_ovd_days end   as nbr_ovd_day
         , case when d.contract_no_ is null then null
                when u.category in ('21062', '21063') then 0
                else round(coalesce(d.amount, 0), 2) end                 as outs_prin_amt
    from univ u
    left join raw_eod.t24_ld_loans_and_depo_details__mnp d
      on d.contract_no_ = u.contract_no_ and d.m = 1 and d.s = 1
     and d.tf_partition_date = '#business_date#'
),
act as (
    select contract_nbr, value_date, cust_code, cate_code, ccy_code, term
         , prin_repay_acct_nbr, inst_repay_acct_nbr, nbr_ovd_day, outs_prin_amt
    from dwh_intf.loan_contract_intf
    where business_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC03_LOAN_CONTRACT_INTF_DETAIL_02', 'linhvt', 'loan_contract_intf', 'DWH-103', 'inst_rate_type, inst_rate, inst_reset_freq', 'Loại lãi suất, lãi suất và tần suất điều chỉnh đúng quy tắc', 'Detail quy tắc lãi suất', 'loan_contract_intf_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - loan_contract_intf: quy tắc lãi suất.
   inst_rate_type  : FIXED khi loại lãi suất của hợp đồng (int_rate_type) là 1 và loại lãi suất tham chiếu
                     để trống hoặc là "Lai suat co dinh"; mọi trường hợp khác là FLOATING.
   inst_rate       : loại 1 = lãi suất của dòng chi tiết; loại 2 = lãi suất cộng biên độ; giá trị trống tính là 0;
                     loại khác (kể cả trống) thì để trống. Làm tròn 5 số lẻ.
   inst_reset_freq : tần suất điều chỉnh lãi suất viết hoa và bỏ một số 0 đứng đầu (03m -> 3M); riêng 0M giữ nguyên.
   Hợp đồng không có dòng chi tiết (m = 1, s = 1) của ngày chạy thì cả ba cột để trống.
   Test duyệt từng dòng của đích và so với giá trị QA tự tính từ nguồn. */
with src as (
    select ld.contract_no_
         , case when ld.int_rate_type = '1'
                 and coalesce(ld.int_ref_type, 'Lai suat co dinh') = 'Lai suat co dinh' then 'FIXED'
                else 'FLOATING' end as exp_rate_type
         , round(case ld.int_rate_type
                     when '1' then coalesce(d.interest_rate, 0)
                     when '2' then coalesce(d.interest_rate, 0) + coalesce(ld.interest_spread, 0)
                 end, 5) as exp_rate
         , case when ld.rate_change_fre = '0M' then '0M'
                else upper(regexp_replace(ld.rate_change_fre, '^0', '')) end as exp_reset_freq
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    join raw_eod.t24_ld_loans_and_depo_details__mnp d
      on d.contract_no_ = ld.contract_no_ and d.m = 1 and d.s = 1
     and d.tf_partition_date = '#business_date#'
    where ld.tf_partition_date = '#business_date#'
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from dwh_intf.loan_contract_intf a
left join src s on s.contract_no_ = a.contract_nbr
where a.business_date = '#business_date#'
  and (   case when a.inst_rate_type is null and s.exp_rate_type is null then 0
               when a.inst_rate_type = s.exp_rate_type then 0 else 1 end = 1
       or case when a.inst_rate is null and s.exp_rate is null then 0
               when a.inst_rate = s.exp_rate then 0 else 1 end = 1
       or case when a.inst_reset_freq is null and s.exp_reset_freq is null then 0
               when a.inst_reset_freq = s.exp_reset_freq then 0 else 1 end = 1
      )$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC03_LOAN_CONTRACT_INTF_DETAIL_03', 'linhvt', 'loan_contract_intf', 'DWH-103', 'mat_date', 'Ngày đáo hạn được kiểm tra hợp lệ trước khi đổi sang kiểu ngày', 'Detail ngày đáo hạn', 'loan_contract_intf_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - loan_contract_intf.mat_date: ngày đáo hạn cuối (chuỗi YYYYMMDD trên T24) sau khi kiểm tra hợp lệ.
   - Chuỗi trống                                                          -> mat_date trống.
   - Chuỗi là một ngày hợp lệ trên lịch                                    -> đúng ngày đó.
   - Ngày không hợp lệ của tháng 2 (30/02, hoặc 29/02 của năm không nhuận) -> mat_date trống.
   - Ngày không hợp lệ ở các trường hợp khác (31/04, tháng 13...)          -> 1900-01-02.
   Hợp đồng không có dòng chi tiết (m = 1, s = 1) của ngày chạy thì mat_date trống.
   QA không chép lại công thức năm nhuận của dev mà hỏi lịch của cơ sở dữ liệu:
   ngày cuối tháng = ngày 01 của tháng + 1 tháng - 1 ngày. */
with src as (
    select ld.contract_no_
         , ld.fin_mat_date                  as f
         , substring(ld.fin_mat_date, 5, 2) as mm
         , substring(ld.fin_mat_date, 7, 2) as dd
    from raw_eod.t24_ld_loans_and_depo__mnp ld
    join raw_eod.t24_ld_loans_and_depo_details__mnp d
      on d.contract_no_ = ld.contract_no_ and d.m = 1 and d.s = 1
     and d.tf_partition_date = '#business_date#'
    where ld.tf_partition_date = '#business_date#'
),
cal as (
    select contract_no_, f, mm, dd
         , case when mm between '01' and '12'
                then to_char(to_date(substring(f, 1, 6) || '01', 'YYYYMMDD') + interval '1 month - 1 day', 'DD')
           end as last_dd
    from src
),
exp as (
    select contract_no_
         , case when f is null then null
                when mm between '01' and '12' and dd between '01' and last_dd then to_date(f, 'YYYYMMDD')
                when mm = '02' then null
                else date '1900-01-02' end as exp_mat_date
    from cal
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from dwh_intf.loan_contract_intf a
left join exp e on e.contract_no_ = a.contract_nbr
where a.business_date = '#business_date#'
  and case when a.mat_date is null and e.exp_mat_date is null then 0
           when a.mat_date = e.exp_mat_date then 0 else 1 end = 1$qa$, null, 'daily', '1', '50', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC03_BI_LEND_REPAY_INFO_COUNT_01', 'linhvt', 'bi_lend_repay_info_intf__fa', 'DWH-103', 'repay_acty_code', 'Số dòng layer 2 bằng số giao dịch trả nợ hợp lệ của repay_acty_intf', 'Count nguồn phụ và layer 2', 'bi_lend_repay_info_intf__fa_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - bi_lend_repay_info_intf__fa: số dòng layer 2 phải bằng số giao dịch trả nợ của ngày chạy trong
   repay_acty_intf, không tính giao dịch của category 21059 và giao dịch không xác định được category
   (cate_code trống). Giao dịch của hợp đồng không có trong loan_contract_intf vẫn được tính. */
with src as (
    select count(*) as n
    from dwh_intf.repay_acty_intf
    where business_date = '#business_date#'
      and cate_code is not null
      and cate_code <> '21059'
),
tgt as (
    select count(*) as n
    from bi_intf.bi_lend_repay_info_intf__fa
    where tf_partition_date = '#business_date#'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC03_BI_LEND_REPAY_INFO_DUP_01', 'linhvt', 'bi_lend_repay_info_intf__fa', 'DWH-103', 'business_date, repay_acty_code', 'Mỗi giao dịch trả nợ chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'bi_lend_repay_info_intf__fa_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - bi_lend_repay_info_intf__fa: trong một tf_partition_date, mỗi (business_date, repay_acty_code)
   chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select business_date, repay_acty_code
    from bi_intf.bi_lend_repay_info_intf__fa
    where tf_partition_date = '#business_date#'
    group by business_date, repay_acty_code
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC03_BI_LEND_REPAY_INFO_DETAIL_01', 'linhvt', 'bi_lend_repay_info_intf__fa', 'DWH-103', '8 cột chép từ giao dịch trả nợ', 'Mã giao dịch, khách hàng, loại tiền, ngày trả và ba số tiền giữ nguyên như repay_acty_intf', 'Detail so hai chiều nguồn phụ và layer 2', 'bi_lend_repay_info_intf__fa_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - bi_lend_repay_info_intf__fa: các cột chép thẳng từ giao dịch trả nợ (mã giao dịch, ngày chạy,
   khách hàng, loại tiền, ngày trả, tổng tiền, phần gốc, phần lãi). So hai chiều với các giao dịch hợp lệ
   của repay_acty_intf (category có giá trị và khác 21059).
   Ba cột tiền mang hậu tố _LCY nhưng giữ nguyên số tiền của giao dịch, không quy đổi sang nội tệ. */
with exp as (
    select r.repay_acty_code
         , r.business_date
         , r.cust_code
         , r.ccy_code::varchar(10) as ccy_code
         , r.repay_date
         , r.repay_amt as repay_amt_lcy
         , r.prin_amt  as prin_amt_lcy
         , r.inst_amt  as inst_amt_lcy
    from dwh_intf.repay_acty_intf r
    where r.business_date = '#business_date#'
      and r.cate_code is not null
      and r.cate_code <> '21059'
),
act as (
    select repay_acty_code, business_date, cust_code, ccy_code, repay_date
         , repay_amt_lcy, prin_amt_lcy, inst_amt_lcy
    from bi_intf.bi_lend_repay_info_intf__fa
    where tf_partition_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC03_BI_LEND_REPAY_INFO_DETAIL_02', 'linhvt', 'bi_lend_repay_info_intf__fa', 'DWH-103', 'contract_nbr, nbr_of_ovd_day', 'Đổi số PDLD về số hợp đồng LD; số ngày quá hạn chỉ có với giao dịch trả nợ quá hạn', 'Detail đổi số hợp đồng và số ngày quá hạn', 'bi_lend_repay_info_intf__fa_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - bi_lend_repay_info_intf__fa: số hợp đồng và số ngày quá hạn.
   contract_nbr   : giao dịch trả nợ quá hạn của hợp đồng LD mang số PDLD...; layer 2 phải trả về số hợp đồng LD
                    (bỏ hai ký tự PD ở đầu). Các số khác (LD..., PDPD...) giữ nguyên.
   nbr_of_ovd_day : chỉ có với giao dịch trả nợ quá hạn (số gốc bắt đầu bằng PDLD): bằng số ngày quá hạn của
                    hợp đồng LD đó trong loan_contract_intf cùng ngày chạy. Giao dịch khác để trống.
   Test duyệt từng dòng của đích, tìm giao dịch gốc theo mã giao dịch. */
with src as (
    select r.repay_acty_code
         , r.contract_nbr as raw_contract
         , case when r.contract_nbr like 'PDLD%' then substring(r.contract_nbr, 3)
                else r.contract_nbr end as exp_contract
    from dwh_intf.repay_acty_intf r
    where r.business_date = '#business_date#'
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from bi_intf.bi_lend_repay_info_intf__fa t
left join src s
  on s.repay_acty_code = t.repay_acty_code
left join dwh_intf.loan_contract_intf l
  on l.business_date = '#business_date#'
 and l.contract_nbr = s.exp_contract
 and s.raw_contract like 'PDLD%'
where t.tf_partition_date = '#business_date#'
  and (   case when t.contract_nbr is null and s.exp_contract is null then 0
               when t.contract_nbr = s.exp_contract then 0 else 1 end = 1
       or case when t.nbr_of_ovd_day is null and l.nbr_ovd_day is null then 0
               when t.nbr_of_ovd_day = l.nbr_ovd_day then 0 else 1 end = 1
      )$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC03_BI_LEND_REPAY_INFO_DETAIL_03', 'linhvt', 'bi_lend_repay_info_intf__fa', 'DWH-103', 'prin_repay_acct, inst_repay_acct', 'Tài khoản trả nợ tra từ loan_contract_intf của đúng ngày chạy', 'Detail các cột tra từ interface L1', 'bi_lend_repay_info_intf__fa_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - bi_lend_repay_info_intf__fa: tài khoản trả gốc (prin_repay_acct) và trả lãi (inst_repay_acct).
   Hai tài khoản lấy từ loan_contract_intf của ĐÚNG ngày chạy, tìm theo số hợp đồng LD của giao dịch
   (số PDLD... tính về LD...). Hợp đồng không có trong loan_contract_intf ngày chạy thì hai cột để trống,
   kể cả khi ngày hôm trước hợp đồng còn trong interface.
   Chưa xét giao dịch của hợp đồng thấu chi quá hạn (ovd_od_intf): ngoài phạm vi DWH-103.
   Test duyệt từng dòng của đích, tìm giao dịch gốc theo mã giao dịch. */
with src as (
    select r.repay_acty_code
         , case when r.contract_nbr like 'PDLD%' then substring(r.contract_nbr, 3)
                else r.contract_nbr end as loan_contract
    from dwh_intf.repay_acty_intf r
    where r.business_date = '#business_date#'
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from bi_intf.bi_lend_repay_info_intf__fa t
left join src s
  on s.repay_acty_code = t.repay_acty_code
left join dwh_intf.loan_contract_intf l
  on l.business_date = '#business_date#'
 and l.contract_nbr = s.loan_contract
where t.tf_partition_date = '#business_date#'
  and (   case when t.prin_repay_acct is null and l.prin_repay_acct_nbr is null then 0
               when t.prin_repay_acct = l.prin_repay_acct_nbr then 0 else 1 end = 1
       or case when t.inst_repay_acct is null and l.inst_repay_acct_nbr is null then 0
               when t.inst_repay_acct = l.inst_repay_acct_nbr then 0 else 1 end = 1
      )$qa$, null, 'daily', '1', '50', localtimestamp, current_date - 1);
