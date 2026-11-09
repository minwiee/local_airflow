-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 04_card: đăng ký test case QA vào dwh_ref.csv_ma_automation_script__mnp

delete from dwh_ref.csv_ma_automation_script__mnp where testcase_id like 'TC04_%';

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC04_CARD_INTF_COUNT_01', 'linhvt', 'card_intf', 'DWH-104', 'uniq_id_in_src_sys', 'Số dòng ở đích bằng số thẻ Way4 đủ điều kiện của ngày chạy', 'Count nguồn và đích', 'card_intf_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - card_intf: số dòng ở đích phải bằng số thẻ Way4 đủ điều kiện của ngày chạy.
   Thẻ đủ điều kiện theo yêu cầu:
   - là bản ghi thẻ (CON_CAT = 'C') đang hiệu lực (AMND_STATE = 'A'), BASE_RELATION để trống,
     số thẻ không bắt đầu bằng 60000, 111111, 999999 hoặc 70;
   - ngày mở không sau ngày chạy;
   - hợp đồng thẻ cha có trong bản chụp cùng ngày và hợp lệ: CON_CAT = 'A', AMND_STATE = 'A',
     BASE_RELATION để trống, PCAT = 'C', chưa hết hiệu lực trước ngày chạy;
   - sản phẩm của thẻ đang hiệu lực và tên không chứa RELATION.
   Đếm theo thẻ (dùng exists) nên nếu đích bị nhân đôi dòng thì test này cũng fail. */
with src as (
    select count(*) as n
    from raw_eod.way4_acnt_contract__mnp c
    where c.tf_partition_date = '#business_date#'
      and c.con_cat = 'C'
      and c.amnd_state = 'A'
      and c.base_relation is null
      and c.contract_number_mask not like '60000%'
      and c.contract_number_mask not like '111111%'
      and c.contract_number_mask not like '999999%'
      and c.contract_number_mask not like '70%'
      and c.date_open <= '#business_date#'
      and exists (select 1
                  from raw_eod.way4_acnt_contract__mnp h
                  where h.id = c.acnt_contract__oid
                    and h.tf_partition_date = '#business_date#'
                    and h.con_cat = 'A'
                    and h.amnd_state = 'A'
                    and h.base_relation is null
                    and h.pcat = 'C'
                    and (h.date_expire is null or h.date_expire >= '#business_date#'))
      and exists (select 1
                  from raw_eod.way4_appl_product__mnp p
                  where p.internal_code = c.product
                    and p.tf_partition_date = '#business_date#'
                    and p.amnd_state = 'A'
                    and upper(p.name) not like '%RELATION%')
),
tgt as (
    select count(*) as n
    from dwh_intf.card_intf
    where business_date = '#business_date#'
      and src_sys_code = 'WAY4_ACNT_CONTRACT'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC04_CARD_INTF_DUP_01', 'linhvt', 'card_intf', 'DWH-104', 'uniq_id_in_src_sys, src_sys_code', 'Mỗi thẻ chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'card_intf_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - card_intf: trong một business date, mỗi thẻ (uniq_id_in_src_sys) của một hệ thống
   nguồn chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select uniq_id_in_src_sys, src_sys_code
    from dwh_intf.card_intf
    where business_date = '#business_date#'
    group by uniq_id_in_src_sys, src_sys_code
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC04_CARD_INTF_DETAIL_01', 'linhvt', 'card_intf', 'DWH-104', 'card_nbr, contract_nbr, prd_card_code, limit_amt, card_open_date, src_info, src_sys_code', 'Số thẻ, số hợp đồng thẻ, id sản phẩm, hạn mức và các cột lấy thẳng đúng theo nguồn', 'Detail so hai chiều nguồn và đích', 'card_intf_dag đã success', 'missing_in_target = 0 và not_in_source = 0', $qa$/* DETAIL - card_intf: QA tự dựng lại 8 cột lấy thẳng từ nguồn rồi so hai chiều với đích:
   id thẻ, số thẻ, số hợp đồng thẻ (lấy ở bản ghi hợp đồng cha), id sản phẩm (tra theo mã sản phẩm),
   hạn mức (trống thì là 0), ngày mở, thông tin nguồn phát hành, mã hệ thống nguồn.
   Tập thẻ kỳ vọng là tập thẻ đủ điều kiện như test COUNT_01.
   Một dòng lệch ở bất kỳ cột nào, thiếu hay thừa, đều làm test fail. */
with exp as (
    select c.id::varchar(64)                 as uniq_id_in_src_sys
         , c.contract_number_mask            as card_nbr
         , h.contract_number_mask            as contract_nbr
         , p.id::varchar(64)                 as prd_card_code
         , coalesce(c.auth_limit_amount, 0)  as limit_amt
         , c.date_open                       as card_open_date
         , c.add_info_04                     as src_info
         , 'WAY4_ACNT_CONTRACT'              as src_sys_code
    from raw_eod.way4_acnt_contract__mnp c
    join raw_eod.way4_acnt_contract__mnp h
      on h.id = c.acnt_contract__oid
     and h.tf_partition_date = '#business_date#'
     and h.con_cat = 'A' and h.amnd_state = 'A'
     and h.base_relation is null and h.pcat = 'C'
     and (h.date_expire is null or h.date_expire >= '#business_date#')
    join raw_eod.way4_appl_product__mnp p
      on p.internal_code = c.product
     and p.tf_partition_date = '#business_date#'
     and p.amnd_state = 'A'
     and upper(p.name) not like '%RELATION%'
    where c.tf_partition_date = '#business_date#'
      and c.con_cat = 'C' and c.amnd_state = 'A' and c.base_relation is null
      and c.contract_number_mask not like '60000%'
      and c.contract_number_mask not like '111111%'
      and c.contract_number_mask not like '999999%'
      and c.contract_number_mask not like '70%'
      and c.date_open <= '#business_date#'
),
act as (
    select uniq_id_in_src_sys, card_nbr, contract_nbr, prd_card_code, limit_amt
         , card_open_date, src_info, src_sys_code
    from dwh_intf.card_intf
    where business_date = '#business_date#'
),
missing_in_target as (select * from exp except select * from act),
not_in_source     as (select * from act except select * from exp)
select (select count(*) from missing_in_target) as missing_in_target
     , (select count(*) from not_in_source)     as not_in_source
     , case when (select count(*) from missing_in_target) = 0
             and (select count(*) from not_in_source) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC04_CARD_INTF_DETAIL_02', 'linhvt', 'card_intf', 'DWH-104', 'card_type, prim_card_flag, card_status', 'Loại thẻ theo tên nhóm sản phẩm, cờ thẻ chính theo tên sản phẩm, trạng thái sản xuất theo bảng mã', 'Detail ba cột phân loại', 'card_intf_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - card_intf: ba cột phân loại, QA tự suy lại từ nguồn cho từng dòng ở đích.
   card_type      : theo TÊN NHÓM sản phẩm (phiên bản nhóm còn hiệu lực tại ngày chạy:
                    tf_created_at <= ngày chạy < tf_updated_at). Tên có chữ CREDIT -> CREDIT-CARD;
                    có chữ DEBIT hoặc đúng bằng ISSUING -> DEBIT-CARD; còn lại để trống.
   prim_card_flag : theo TÊN SẢN PHẨM. Trong hai chuỗi PRIN và SUPP, chuỗi nào xuất hiện trước
                    thì quyết định: PRIN -> YES; SUPP hoặc không có chuỗi nào -> NO.
   card_status    : mã trạng thái sản xuất (phân biệt chữ hoa, chữ thường) đổi sang tên rồi viết hoa;
                    mã không có trong danh sách -> để trống.
   Không phân biệt hoa thường khi tìm CREDIT, DEBIT, ISSUING, PRIN, SUPP.
   Dòng ở đích không tìm thấy thẻ nguồn cũng tính là lệch. */
with ma_san_xuat as (
    select 'C' as ma, 'TO CLOSE' as ten union all
    select 'L', 'LOCKED' union all
    select 'M', 'MARKED' union all
    select 'N', 'TO REQUEST' union all
    select 'O', 'LOCKED FOR ONLINE' union all
    select 'R', 'READY' union all
    select 'S', 'SENT' union all
    select 'T', 'MARKED APPLET' union all
    select 'W', 'WAITING FOR RESPONSE' union all
    select 'Y', 'NOT TO MARK' union all
    select 'm', 'TO MARK' union all
    select 'w', 'WAITING FOR SUBS'
),
exp as (
    select c.id::varchar(64) as uniq_id_in_src_sys
         , case when position('CREDIT' in upper(g.name)) > 0 then 'CREDIT-CARD'
                when position('DEBIT' in upper(g.name)) > 0 or upper(g.name) = 'ISSUING' then 'DEBIT-CARD'
           end as card_type
         , case when position('PRIN' in upper(p.name)) > 0
                 and (position('SUPP' in upper(p.name)) = 0
                      or position('PRIN' in upper(p.name)) < position('SUPP' in upper(p.name)))
                then 'YES' else 'NO' end as prim_card_flag
         , m.ten as card_status
    from raw_eod.way4_acnt_contract__mnp c
    join raw_eod.way4_appl_product__mnp p
      on p.internal_code = c.product
     and p.tf_partition_date = '#business_date#'
     and p.amnd_state = 'A'
    left join raw_eod.way4_appl_pr_group__s2 g
      on g.id = p.appl_pr_group__id
     and g.tf_created_at <= '#business_date#'
     and g.tf_updated_at > '#business_date#'
    left join ma_san_xuat m
      on m.ma = c.production_status
    where c.tf_partition_date = '#business_date#'
      and c.con_cat = 'C' and c.amnd_state = 'A'
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from dwh_intf.card_intf a
left join exp e on e.uniq_id_in_src_sys = a.uniq_id_in_src_sys
where a.business_date = '#business_date#'
  and (   e.uniq_id_in_src_sys is null
       or coalesce(a.card_type, '#')      <> coalesce(e.card_type, '#')
       or coalesce(a.prim_card_flag, '#') <> coalesce(e.prim_card_flag, '#')
       or coalesce(a.card_status, '#')    <> coalesce(e.card_status, '#')
      )$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-dwh-prd-db', 'postgres', 'TC04_CARD_INTF_DETAIL_03', 'linhvt', 'card_intf', 'DWH-104', 'status_name, actual_end_date, exp_date', 'Trạng thái và ngày kết thúc có quy tắc riêng cho thẻ hết hiệu lực đúng ngày D+1, hạn thẻ là ngày cuối tháng', 'Detail trạng thái và các cột ngày', 'card_intf_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - card_intf: trạng thái và các cột ngày, QA tự suy lại từ nguồn cho từng dòng ở đích.
   Gọi D là ngày chạy. Thẻ "sắp đóng" = ngày hết hiệu lực trên Way4 đúng bằng D+1 và mở trước D.
   status_name     : thẻ sắp đóng -> giữ trạng thái của chính thẻ đó ở card_intf ngày D-1
                     (không có dòng ngày D-1 -> để trống); thẻ khác -> tên trạng thái trong danh mục
                     của ngày D (chỉ lấy dòng danh mục AMND_STATE = 'A').
   actual_end_date : thẻ sắp đóng -> để trống; thẻ khác -> ngày hết hiệu lực trên Way4.
   exp_date        : hạn in trên thẻ dạng YYMM -> ngày cuối của tháng đó (năm 20YY);
                     trống hoặc '0000' -> để trống.
   QA tự tính ngày cuối tháng (ngày 01 của tháng + 1 tháng - 1 ngày), không gọi hàm public.last_day mà dev dùng.
   Dòng ở đích không tìm thấy thẻ nguồn cũng tính là lệch. */
with src as (
    select c.id::varchar(64) as uniq_id_in_src_sys
         , c.contr_status
         , c.date_expire
         , c.card_expire
         , case when c.date_expire = date '#business_date#' + 1
                 and c.date_open < date '#business_date#' then 1 else 0 end as sap_dong
    from raw_eod.way4_acnt_contract__mnp c
    where c.tf_partition_date = '#business_date#'
      and c.con_cat = 'C' and c.amnd_state = 'A'
),
exp as (
    select s.uniq_id_in_src_sys
         , case when s.sap_dong = 1 then prv.status_name else st.name end as status_name
         , case when s.sap_dong = 1 then null else s.date_expire end      as actual_end_date
         , case when s.card_expire is null or s.card_expire = '0000' then null
                else (date_trunc('month', to_date('20' || s.card_expire || '01', 'YYYYMMDD'))
                      + interval '1 month' - interval '1 day')::date
           end as exp_date
    from src s
    left join raw_eod.way4_contr_status__mnp st
      on st.id = s.contr_status
     and st.amnd_state = 'A'
     and st.tf_partition_date = '#business_date#'
    left join dwh_intf.card_intf prv
      on prv.uniq_id_in_src_sys = s.uniq_id_in_src_sys
     and prv.business_date = date '#business_date#' - 1
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from dwh_intf.card_intf a
left join exp e on e.uniq_id_in_src_sys = a.uniq_id_in_src_sys
where a.business_date = '#business_date#'
  and (   e.uniq_id_in_src_sys is null
       or coalesce(a.status_name, '#') <> coalesce(e.status_name, '#')
       or coalesce(a.actual_end_date, date '1900-01-01') <> coalesce(e.actual_end_date, date '1900-01-01')
       or coalesce(a.exp_date, date '1900-01-01')        <> coalesce(e.exp_date, date '1900-01-01')
      )$qa$, null, 'daily', '1', '50', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC04_BI_CARD_INFO_COUNT_01', 'linhvt', 'bi_card_info_intf__mnp', 'DWH-104', 'uniq_id_in_src_sys', 'Số dòng layer 2 bằng số thẻ của card_intf trừ các thẻ bị loại theo quy tắc cứng', 'Count interface L1 và layer 2', 'bi_card_info_intf__mnp_dag đã success', 'source_rows = target_rows và lớn hơn 0', $qa$/* COUNT - bi_card_info_intf__mnp: số dòng layer 2 phải bằng số thẻ Way4 của card_intf cùng ngày,
   trừ các thẻ bị loại theo quy tắc cứng của khối BI. Một thẻ bị loại khi đủ cả 3 điều kiện:
   - thông tin nguồn phát hành có chữ MOBIPHONE (không phân biệt hoa thường). Nếu chuỗi bắt đầu
     bằng dấu gạch dưới thì bỏ hết dấu gạch dưới trước khi xét;
   - tên sản phẩm (tra ở prd_intf của ngày chạy, nguồn WAY4_APPL_PRODUCT) có chữ MC2;
   - thẻ mở trước ngày 2014-01-01. */
with l1 as (
    select ci.uniq_id_in_src_sys
         , ci.prd_card_code
         , ci.card_open_date
         , case when left(ci.src_info, 1) = '_' then replace(ci.src_info, '_', '')
                else ci.src_info end as nguon_phat_hanh
    from dwh_intf.card_intf ci
    where ci.business_date = '#business_date#'
      and ci.src_sys_code = 'WAY4_ACNT_CONTRACT'
),
src as (
    select count(*) as n
    from l1
    where not (    upper(coalesce(l1.nguon_phat_hanh, '')) like '%MOBIPHONE%'
               and coalesce(l1.card_open_date, date '2400-01-01') < date '2014-01-01'
               and exists (select 1
                           from dwh_intf.prd_intf p
                           where p.uniq_id_in_src_sys = l1.prd_card_code
                             and p.src_sys_code = 'WAY4_APPL_PRODUCT'
                             and p.business_date = '#business_date#'
                             and upper(p.prd_name) like '%MC2%'))
),
tgt as (
    select count(*) as n
    from bi_intf.bi_card_info_intf__mnp
    where tf_partition_date = '#business_date#'
)
select src.n as source_rows
     , tgt.n as target_rows
     , src.n - tgt.n as diff
     , case when src.n = tgt.n and tgt.n > 0 then 'pass' else 'fail' end as test_result
from src cross join tgt$qa$, null, 'daily', '1', '90', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC04_BI_CARD_INFO_DUP_01', 'linhvt', 'bi_card_info_intf__mnp', 'DWH-104', 'uniq_id_in_src_sys', 'Mỗi thẻ chỉ có một dòng mỗi ngày', 'Duplicate theo khóa nghiệp vụ', 'bi_card_info_intf__mnp_dag đã success', 'duplicate_keys = 0', $qa$/* DUPLICATE - bi_card_info_intf__mnp: trong một tf_partition_date, mỗi thẻ (uniq_id_in_src_sys)
   chỉ có một dòng. */
select count(*) as duplicate_keys
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from (
    select uniq_id_in_src_sys
    from bi_intf.bi_card_info_intf__mnp
    where tf_partition_date = '#business_date#'
    group by uniq_id_in_src_sys
    having count(*) > 1
) d$qa$, null, 'daily', '1', '80', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC04_BI_CARD_INFO_DETAIL_01', 'linhvt', 'bi_card_info_intf__mnp', 'DWH-104', 'card_nbr, card_status, phys_card_status, card_limit_amt, card_open_date, originl_date_exp, actual_date_exp', '7 cột lấy từ card_intf, có đổi tên cột, đổi ngày mở 2014-04-09 và viết hạn thẻ dạng YYYYMM', 'Detail từng dòng layer 2 với thẻ ở L1', 'bi_card_info_intf__mnp_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - bi_card_info_intf__mnp: 7 cột lấy từ card_intf, so từng dòng layer 2 với thẻ cùng id ở L1.
   Chú ý tên cột đổi giữa hai lớp:
   card_nbr         = card_nbr của L1
   card_status      = status_name của L1 (tên trạng thái Way4)
   phys_card_status = card_status của L1 (trạng thái thẻ vật lý)
   card_limit_amt   = limit_amt của L1
   card_open_date   = card_open_date của L1, riêng ngày 2014-04-09 đổi thành 2014-04-10
   originl_date_exp = tháng của exp_date, viết dạng YYYYMM
   actual_date_exp  = actual_end_date của L1
   Dòng layer 2 không tìm thấy thẻ ở L1 cũng tính là lệch. */
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from bi_intf.bi_card_info_intf__mnp t
left join dwh_intf.card_intf ci
  on ci.business_date = '#business_date#'
 and ci.src_sys_code = 'WAY4_ACNT_CONTRACT'
 and ci.uniq_id_in_src_sys::numeric(23,5) = t.uniq_id_in_src_sys
where t.tf_partition_date = '#business_date#'
  and (   ci.uniq_id_in_src_sys is null
       or coalesce(t.card_nbr, '#')         <> coalesce(ci.card_nbr, '#')
       or coalesce(t.card_status, '#')      <> coalesce(ci.status_name, '#')
       or coalesce(t.phys_card_status, '#') <> coalesce(ci.card_status, '#')
       or coalesce(t.card_limit_amt, -1)    <> coalesce(ci.limit_amt, -1)
       or coalesce(t.card_open_date, date '1900-01-01')
          <> coalesce(case when ci.card_open_date = date '2014-04-09' then date '2014-04-10'
                           else ci.card_open_date end, date '1900-01-01')
       or coalesce(t.originl_date_exp, '#') <> coalesce(to_char(ci.exp_date, 'YYYYMM'), '#')
       or coalesce(t.actual_date_exp, date '1900-01-01') <> coalesce(ci.actual_end_date, date '1900-01-01')
      )$qa$, null, 'daily', '1', '70', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC04_BI_CARD_INFO_DETAIL_02', 'linhvt', 'bi_card_info_intf__mnp', 'DWH-104', 'card_prd_name, bi_prd_type, bi_prd_group', 'Tên sản phẩm tra từ prd_intf, loại thẻ BI theo đầu số thẻ, nhóm thẻ BI theo tên sản phẩm và nhóm sản phẩm', 'Detail tên sản phẩm và phân loại BI', 'bi_card_info_intf__mnp_dag đã success', 'mismatched_rows = 0', $qa$/* DETAIL - bi_card_info_intf__mnp: tên sản phẩm và hai cột phân loại BI, QA tự suy lại cho từng dòng.
   card_prd_name : prd_name tra ở prd_intf theo id sản phẩm của thẻ (prd_card_code ở L1), chỉ lấy dòng
                   nguồn WAY4_APPL_PRODUCT của đúng ngày chạy; không tìm thấy -> để trống.
   bi_prd_type   : số thẻ bắt đầu bằng 3, 4, 5 hoặc 62 -> 02.International Card; còn lại -> 01.Local Card.
   bi_prd_group  : tên sản phẩm hoặc tên nhóm sản phẩm (prd_group_name của prd_intf) có chữ CREDIT
                   -> 01.Credit Card; nếu không thì: có chữ DEBIT, hoặc nhóm đúng bằng ISSUING, hoặc số
                   thẻ bắt đầu bằng 5 -> 02.Debit Card; còn lại để trống. Không phân biệt hoa thường.
   Dòng layer 2 không tìm thấy thẻ ở L1 cũng tính là lệch. */
with exp as (
    select ci.uniq_id_in_src_sys::numeric(23,5) as uniq_id_in_src_sys
         , p.prd_name as card_prd_name
         , case when substring(ci.card_nbr, 1, 1) in ('3', '4', '5')
                  or substring(ci.card_nbr, 1, 2) = '62' then '02.International Card'
                else '01.Local Card' end as bi_prd_type
         , case when position('CREDIT' in upper(coalesce(p.prd_name, ''))) > 0
                  or position('CREDIT' in upper(coalesce(p.prd_group_name, ''))) > 0 then '01.Credit Card'
                when position('DEBIT' in upper(coalesce(p.prd_name, ''))) > 0
                  or position('DEBIT' in upper(coalesce(p.prd_group_name, ''))) > 0
                  or upper(coalesce(p.prd_group_name, '')) = 'ISSUING'
                  or substring(ci.card_nbr, 1, 1) = '5' then '02.Debit Card'
           end as bi_prd_group
    from dwh_intf.card_intf ci
    left join dwh_intf.prd_intf p
      on p.uniq_id_in_src_sys = ci.prd_card_code
     and p.src_sys_code = 'WAY4_APPL_PRODUCT'
     and p.business_date = '#business_date#'
    where ci.business_date = '#business_date#'
      and ci.src_sys_code = 'WAY4_ACNT_CONTRACT'
)
select count(*) as mismatched_rows
     , case when count(*) = 0 then 'pass' else 'fail' end as test_result
from bi_intf.bi_card_info_intf__mnp t
left join exp e on e.uniq_id_in_src_sys = t.uniq_id_in_src_sys
where t.tf_partition_date = '#business_date#'
  and (   e.uniq_id_in_src_sys is null
       or coalesce(t.card_prd_name, '#') <> coalesce(e.card_prd_name, '#')
       or coalesce(t.bi_prd_type, '#')   <> coalesce(e.bi_prd_type, '#')
       or coalesce(t.bi_prd_group, '#')  <> coalesce(e.bi_prd_group, '#')
      )$qa$, null, 'daily', '1', '60', localtimestamp, current_date - 1);

insert into dwh_ref.csv_ma_automation_script__mnp (connection_id, connection_type, testcase_id, qa_pic, intf_name, jira_number, column_check, rule_overview, test_summary, pre_condition, expected_result, testscript, business_date, dwh_frequency, active_rule, priority, tf_etl_at, tf_partition_date)
values ('postgres-bi-prd-db', 'postgres', 'TC04_BI_CARD_INFO_DETAIL_03', 'linhvt', 'bi_card_info_intf__mnp', 'DWH-104', 'uniq_id_in_src_sys', 'Thẻ MOBIPHONE có sản phẩm MC2 mở trước 2014 không được lên layer 2; mọi thẻ khác phải có', 'Detail so tập id thẻ hai chiều', 'bi_card_info_intf__mnp_dag đã success', 'wrongly_present = 0 và wrongly_missing = 0', $qa$/* DETAIL - bi_card_info_intf__mnp: quy tắc loại thẻ của khối BI, so tập id thẻ theo hai chiều.
   Thẻ bị loại khi đủ cả 3 điều kiện: thông tin nguồn phát hành có chữ MOBIPHONE (chuỗi bắt đầu bằng
   dấu gạch dưới thì bỏ hết dấu gạch dưới trước khi xét), tên sản phẩm có chữ MC2, mở trước 2014-01-01.
   wrongly_present : thẻ có ở layer 2 nhưng lẽ ra phải bị loại, hoặc không có ở L1.
   wrongly_missing : thẻ L1 không thuộc diện bị loại nhưng thiếu ở layer 2. */
with l1 as (
    select ci.uniq_id_in_src_sys::numeric(23,5) as id
         , ci.prd_card_code
         , ci.card_open_date
         , case when left(ci.src_info, 1) = '_' then replace(ci.src_info, '_', '')
                else ci.src_info end as nguon_phat_hanh
    from dwh_intf.card_intf ci
    where ci.business_date = '#business_date#'
      and ci.src_sys_code = 'WAY4_ACNT_CONTRACT'
),
exp_keys as (
    select l1.id
    from l1
    where not (    upper(coalesce(l1.nguon_phat_hanh, '')) like '%MOBIPHONE%'
               and coalesce(l1.card_open_date, date '2400-01-01') < date '2014-01-01'
               and exists (select 1
                           from dwh_intf.prd_intf p
                           where p.uniq_id_in_src_sys = l1.prd_card_code
                             and p.src_sys_code = 'WAY4_APPL_PRODUCT'
                             and p.business_date = '#business_date#'
                             and upper(p.prd_name) like '%MC2%'))
),
act_keys as (
    select uniq_id_in_src_sys as id
    from bi_intf.bi_card_info_intf__mnp
    where tf_partition_date = '#business_date#'
),
wrongly_present as (select id from act_keys except select id from exp_keys),
wrongly_missing as (select id from exp_keys except select id from act_keys)
select (select count(*) from wrongly_present) as wrongly_present
     , (select count(*) from wrongly_missing) as wrongly_missing
     , case when (select count(*) from wrongly_present) = 0
             and (select count(*) from wrongly_missing) = 0 then 'pass' else 'fail' end as test_result$qa$, null, 'daily', '1', '50', localtimestamp, current_date - 1);
