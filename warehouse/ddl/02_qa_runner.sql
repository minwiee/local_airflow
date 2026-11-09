-- ---------------------------------------------------------------------------
-- DWH - chạy test QA ở môi trường dev
-- ---------------------------------------------------------------------------
-- Hàm dwh_ctrl.run_qa_automation chạy kịch bản test theo cùng quy trình với DAG
-- qa_automation_result_intf_dag:
--   1. Đọc kịch bản đang bật trong dwh_ref.csv_ma_automation_script__mnp.
--   2. Chỉ chạy khi dwh_ctrl.log_etl_table đã có dòng success của <intf_name>_dag
--      cho business date đó (giống bước check_table_ready của DAG).
--   3. Thay #business_date# trong script rồi chạy; lấy cột test_result của dòng đầu.
--      Không có dòng nào = fail; script lỗi = 'sql error' kèm failure_reason.
--   4. Ghi kết quả vào dwh_intf.qa_automation_result_intf.
-- Điểm khác DAG: hàm nhận business date qua tham số và chạy lại được nhiều lần
-- trong ngày (DAG tự tính ngày theo dwh_frequency và mỗi kịch bản active_rule = 1
-- chỉ chạy một lần mỗi ngày).
--
-- Cách dùng:
--   select * from dwh_ctrl.run_qa_automation('2026-09-30');          -- tất cả kịch bản
--   select * from dwh_ctrl.run_qa_automation('2026-09-30', 'TC01%'); -- lọc theo testcase_id
-- ---------------------------------------------------------------------------
set client_encoding to 'UTF8';

create or replace function dwh_ctrl.run_qa_automation(p_business_date date, p_testcase_like text default '%')
returns table (out_testcase_id varchar, out_intf_name varchar, out_test_result varchar, out_failure_reason varchar)
language plpgsql
as $fn$
declare
    r         record;
    v_script  text;
    v_result  text;
    v_reason  text;
    v_ready   integer;
    v_start   timestamp;
begin
    for r in
        select s.*
        from dwh_ref.csv_ma_automation_script__mnp s
        where s.active_rule in ('1', '2')
          and s.testcase_id like p_testcase_like
        order by s.priority desc, s.intf_name, s.testcase_id
    loop
        -- check_table_ready: interface phải chạy xong và success cho ngày cần test
        select count(*) into v_ready
        from dwh_ctrl.log_etl_table l
        where l.data_date = p_business_date
          and lower(l.job_name) = lower(trim(r.intf_name)) || '_dag'
          and l.status_name = 'success'
          and l.project_name = 'dwh';

        if v_ready <> 1 then
            raise notice 'Table not ready: %, %, %', r.intf_name, r.testcase_id, p_business_date;
            continue;
        end if;

        v_script := replace(r.testscript, '#business_date#', to_char(p_business_date, 'YYYY-MM-DD'));
        v_script := regexp_replace(v_script, ';\s*$', '');
        v_start  := clock_timestamp();
        v_result := null;
        v_reason := null;

        begin
            execute 'select lower(trim(q.test_result::text)) from (' || chr(10) || v_script || chr(10) || ') q limit 1'
               into v_result;
            if v_result is null then
                v_result := 'fail';
            end if;
        exception when others then
            v_result := 'sql error';
            v_reason := right(sqlerrm, 2048);
        end;

        insert into dwh_intf.qa_automation_result_intf (
            business_date, start_time, end_time, testcase_id, qa_pic, intf_name, jira_number, column_check,
            rule_overview, test_summary, pre_condition, expected_result, testscript, test_result,
            connection_id, failure_reason, tf_partition_date)
        values (
            p_business_date, v_start, clock_timestamp(), r.testcase_id, r.qa_pic, r.intf_name, r.jira_number, r.column_check,
            r.rule_overview, r.test_summary, r.pre_condition, r.expected_result, v_script, v_result,
            lower(r.connection_id), v_reason, current_date - 1);

        out_testcase_id    := r.testcase_id;
        out_intf_name      := r.intf_name;
        out_test_result    := v_result;
        out_failure_reason := v_reason;
        return next;
    end loop;
end
$fn$;
