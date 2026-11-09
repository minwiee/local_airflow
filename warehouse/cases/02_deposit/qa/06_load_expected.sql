-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 02_deposit: nạp kết quả mong đợi vào schema qa_expected

drop table if exists qa_expected.bi_intf__bi_depo_info_intf__mnp;
create table qa_expected.bi_intf__bi_depo_info_intf__mnp (contract_nbr text, cust_code text, ccy_code text, notion_mat_date text, inst_rate text, close_amt_fcy text, acct_seprt_type text, prd_group_name text, bi_term text, cate_code text, eff_date text, tf_sourcing_at text, tf_run_id text, tf_partition_date text, tf_source_system text);
-- tf_partition_date = 2026-09-29: 13 dòng
insert into qa_expected.bi_intf__bi_depo_info_intf__mnp (contract_nbr, cust_code, ccy_code, notion_mat_date, inst_rate, close_amt_fcy, acct_seprt_type, prd_group_name, bi_term, cate_code, eff_date, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('LD2610000101', '1000001', 'VND', '2027-01-15', '5.00000', '120000000.00000', 'CUR', '2. Term Deposit', '12', '21017', '2026-01-15', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000102', '1000002', 'USD', '2027-09-30', '3.50000', '5000.00000', 'CUR', '2. Term Deposit', '24', '21014', '2025-09-30', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000104', '1000004', 'VND', '2026-09-30', '3.00000', '30000000.00000', 'CUR', '2. Term Deposit', '0.75', '21017', '2026-09-03', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000105', '1000005', 'VND', '2026-10-03', '2.00000', '15000000.00000', 'CUR', '2. Term Deposit', '0.25', '21017', '2026-09-28', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000106', '1000001', 'VND', '2027-01-16', '5.50000', '200000000.00000', 'CUR', '2. Term Deposit', '13', '21012', '2026-01-15', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000107', '1000006', 'VND', '2026-11-20', '4.50000', '45000000.00000', 'CUR', '2. Term Deposit', '3', '21019', '2026-08-20', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000108', '1000007', 'VND', '2027-01-01', '4.80000', '60000000.00000', 'CUR', '3. Others', null, '21030', '2026-07-01', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000201', '1000008', 'VND', '2026-09-30', '5.00000', '50000000.00000', 'CUR', '2. Term Deposit', '6', '21017', '2026-03-30', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000202', '1000009', 'VND', '2026-10-01', '4.80000', '80000000.00000', 'CUR', '2. Term Deposit', '3', '21018', '2026-07-01', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000302', '1000011', 'VND', '2026-12-31', '10.00000', '300000000.00000', 'CUR', null, null, '21060', '2026-01-01', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000305', '1000014', 'VND', '2026-09-29', '4.10000', '35000000.00000', 'CUR', '2. Term Deposit', '3', '21017', '2026-06-29', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000306', '1000015', 'VND', '2026-12-29', '4.60000', '70000000.00000', 'CUR', '2. Term Deposit', '9', '21017', '2026-03-29', null, 'prod', '2026-09-29', 'DEPO_INTF'),
  ('LD2610000307', '1000019', 'VND', '2026-09-29', '3.80000', '40000000.00000', 'CUR', '2. Term Deposit', '1', '21014', '2026-08-29', null, 'prod', '2026-09-29', 'DEPO_INTF');
-- tf_partition_date = 2026-09-30: 8 dòng
insert into qa_expected.bi_intf__bi_depo_info_intf__mnp (contract_nbr, cust_code, ccy_code, notion_mat_date, inst_rate, close_amt_fcy, acct_seprt_type, prd_group_name, bi_term, cate_code, eff_date, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('LD2610000101', '1000001', 'VND', '2027-01-15', '5.20000', '100000000.00000', 'CUR', '2. Term Deposit', '12', '21017', '2026-01-15', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000102', '1000002', 'USD', '2027-09-30', '3.50000', '5000.00000', 'CUR', '2. Term Deposit', '24', '21014', '2025-09-30', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000103', '1000003', 'VND', '2026-10-28', '4.00000', '20000000.00000', 'CUR', '2. Term Deposit', '1', '21018', '2026-09-30', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000104', '1000004', 'VND', '2026-09-30', '3.00000', '30000000.00000', 'CUR', '2. Term Deposit', '0.75', '21017', '2026-09-03', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000105', '1000005', 'VND', '2026-10-03', null, null, 'CUR', '2. Term Deposit', '0.25', '21017', '2026-09-28', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000106', '1000001', 'VND', '2027-01-16', '5.50000', '200000000.00000', 'CUR', '2. Term Deposit', '13', '21012', '2026-01-15', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000107', '1000006', 'VND', '2026-11-20', '4.50000', '45000000.00000', 'CUR', null, null, '21019', '2026-08-20', null, 'prod', '2026-09-30', 'DEPO_INTF'),
  ('LD2610000108', '1000007', 'VND', '2027-01-01', '4.80000', '60000000.00000', 'CUR', '3. Others', null, '21030', '2026-07-01', null, 'prod', '2026-09-30', 'DEPO_INTF');

drop table if exists qa_expected.dwh_intf__depo_intf;
create table qa_expected.dwh_intf__depo_intf (business_date text, contract_nbr text, cust_code text, ccy_code text, mgmt_branch_code text, cate_code text, close_date text, inst_rate text, inst_pmt_method text, depo_close_type text, close_amt_fcy text, notion_mat_date text, term text, acct_seprt_type text, value_date text);
-- business_date = 2026-09-29: 16 dòng
insert into qa_expected.dwh_intf__depo_intf (business_date, contract_nbr, cust_code, ccy_code, mgmt_branch_code, cate_code, close_date, inst_rate, inst_pmt_method, depo_close_type, close_amt_fcy, notion_mat_date, term, acct_seprt_type, value_date) values
  ('2026-09-29', 'LD2610000101', '1000001', 'VND', 'VN0010102', '21017', null, '5.00000', 'CUOI KY', null, '120000000.00000', '2027-01-15', '12M', 'CUR', '2026-01-15'),
  ('2026-09-29', 'LD2610000102', '1000002', 'USD', 'VN0010204', '21014', null, '3.50000', 'DAU KY', null, '5000.00000', '2027-09-30', '24M', 'CUR', '2025-09-30'),
  ('2026-09-29', 'LD2610000104', '1000004', 'VND', 'VN0010102', '21017', null, '3.00000', 'CUOI KY', null, '30000000.00000', '2026-09-30', '3W', 'CUR', '2026-09-03'),
  ('2026-09-29', 'LD2610000105', '1000005', 'VND', 'VN0010305', '21017', null, '2.00000', 'CUOI KY', null, '15000000.00000', '2026-10-03', '1W', 'CUR', '2026-09-28'),
  ('2026-09-29', 'LD2610000106', '1000001', 'VND', 'VN0010102', '21012', null, '5.50000', 'DAU KY', null, '200000000.00000', '2027-01-16', '12M', 'CUR', '2026-01-15'),
  ('2026-09-29', 'LD2610000107', '1000006', 'VND', 'VN0010204', '21019', null, '4.50000', 'CUOI KY', null, '45000000.00000', '2026-11-20', '3M', 'CUR', '2026-08-20'),
  ('2026-09-29', 'LD2610000108', '1000007', 'VND', 'VN0010103', '21030', null, '4.80000', 'CUOI KY', null, '60000000.00000', '2027-01-01', '6M', 'CUR', '2026-07-01'),
  ('2026-09-29', 'LD2610000201', '1000008', 'VND', 'VN0010102', '21017', null, '5.00000', 'CUOI KY', null, '50000000.00000', '2026-09-30', '6M', 'CUR', '2026-03-30'),
  ('2026-09-29', 'LD2610000202', '1000009', 'VND', 'VN0010204', '21018', null, '4.80000', 'CUOI KY', null, '80000000.00000', '2026-10-01', '3M', 'CUR', '2026-07-01'),
  ('2026-09-29', 'LD2610000302', '1000011', 'VND', 'VN0010305', '21060', null, '10.00000', 'CUOI KY', null, '300000000.00000', '2026-12-31', '12M', 'CUR', '2026-01-01'),
  ('2026-09-29', 'LD2610000305', '1000014', 'VND', 'VN0010103', '21017', null, '4.10000', 'CUOI KY', null, '35000000.00000', '2026-09-29', '3M', 'CUR', '2026-06-29'),
  ('2026-09-29', 'LD2610000306', '1000015', 'VND', 'VN0010102', '21017', null, '4.60000', 'CUOI KY', null, '70000000.00000', '2026-12-29', '9M', 'CUR', '2026-03-29'),
  ('2026-09-29', 'LD2610000307', '1000019', 'VND', 'VN0010204', '21014', null, '3.80000', 'CUOI KY', null, '40000000.00000', '2026-09-29', '1M', 'CUR', '2026-08-29'),
  ('2026-09-29', 'LD2610000401', '1000016', 'VND', 'VN0010204', '21017', '2026-09-29', '5.00000', 'CUOI KY', 'MAT', '90000000.00000', '2026-09-29', '6M', 'CLOSE', '2026-03-29'),
  ('2026-09-29', 'LD2610000402', '1000017', 'VND', 'VN0010103', '21012', '2026-09-29', '0.20000', 'CUOI KY', 'MAT_EARLY', null, '2026-12-29', '3M', 'CLOSE', '2026-09-29'),
  ('2026-09-29', 'LD2610000403', '1000018', 'VND', 'VN0010305', '21017', '2026-09-29', '0.20000', 'CUOI KY', 'MAT_EARLY', '0.00000', '2026-11-28', '3M', 'CLOSE', '2026-08-28');
-- business_date = 2026-09-30: 10 dòng
insert into qa_expected.dwh_intf__depo_intf (business_date, contract_nbr, cust_code, ccy_code, mgmt_branch_code, cate_code, close_date, inst_rate, inst_pmt_method, depo_close_type, close_amt_fcy, notion_mat_date, term, acct_seprt_type, value_date) values
  ('2026-09-30', 'LD2610000101', '1000001', 'VND', 'VN0010102', '21017', null, '5.20000', 'CUOI KY', null, '100000000.00000', '2027-01-15', '12M', 'CUR', '2026-01-15'),
  ('2026-09-30', 'LD2610000102', '1000002', 'USD', 'VN0010204', '21014', null, '3.50000', 'DAU KY', null, '5000.00000', '2027-09-30', '24M', 'CUR', '2025-09-30'),
  ('2026-09-30', 'LD2610000103', '1000003', 'VND', 'VN0010103', '21018', null, '4.00000', 'CUOI KY', null, '20000000.00000', '2026-10-28', '1M', 'CUR', '2026-09-30'),
  ('2026-09-30', 'LD2610000104', '1000004', 'VND', 'VN0010102', '21017', null, '3.00000', 'CUOI KY', null, '30000000.00000', '2026-09-30', '3W', 'CUR', '2026-09-03'),
  ('2026-09-30', 'LD2610000105', '1000005', 'VND', 'VN0010305', '21017', null, null, 'CUOI KY', null, null, '2026-10-03', '1W', 'CUR', '2026-09-28'),
  ('2026-09-30', 'LD2610000106', '1000001', 'VND', 'VN0010102', '21012', null, '5.50000', 'DAU KY', null, '200000000.00000', '2027-01-16', '12M', 'CUR', '2026-01-15'),
  ('2026-09-30', 'LD2610000107', '1000006', 'VND', 'VN0010204', '21019', null, '4.50000', 'CUOI KY', null, '45000000.00000', '2026-11-20', '3M', 'CUR', '2026-08-20'),
  ('2026-09-30', 'LD2610000108', '1000007', 'VND', 'VN0010103', '21030', null, '4.80000', 'CUOI KY', null, '60000000.00000', '2027-01-01', '6M', 'CUR', '2026-07-01'),
  ('2026-09-30', 'LD2610000201', '1000008', 'VND', 'VN0010102', '21017', '2026-09-30', '5.00000', 'CUOI KY', 'MAT', '50000000.00000', '2026-09-30', '6M', 'CLOSE', '2026-03-30'),
  ('2026-09-30', 'LD2610000202', '1000009', 'VND', 'VN0010204', '21018', '2026-09-30', '0.50000', 'CUOI KY', 'MAT_EARLY', '80000000.00000', '2026-10-01', '3M', 'CLOSE', '2026-07-01');

