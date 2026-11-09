-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 04_card: nạp kết quả mong đợi vào schema qa_expected

drop table if exists qa_expected.bi_intf__bi_card_info_intf__mnp;
create table qa_expected.bi_intf__bi_card_info_intf__mnp (uniq_id_in_src_sys text, card_nbr text, card_status text, card_limit_amt text, card_open_date text, originl_date_exp text, actual_date_exp text, card_prd_name text, phys_card_status text, bi_prd_type text, bi_prd_group text, tf_source_system text, tf_run_id text, tf_partition_date text);
-- tf_partition_date = 2026-09-29: 4 dòng
insert into qa_expected.bi_intf__bi_card_info_intf__mnp (uniq_id_in_src_sys, card_nbr, card_status, card_limit_amt, card_open_date, originl_date_exp, actual_date_exp, card_prd_name, phys_card_status, bi_prd_type, bi_prd_group, tf_source_system, tf_run_id, tf_partition_date) values
  ('1001.00000', '545400******1001', 'Card OK', '45000000.00000', '2026-03-14', '202812', '2026-10-01', 'MC PLATINUM CREDIT PRIN', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-29'),
  ('1002.00000', '545400******1002', 'Card OK', '20000000.00000', '2026-03-20', '202812', '2028-12-31', 'MC PLATINUM CREDIT SUPP', 'SENT', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-29'),
  ('1007.00000', '545400******1007', 'Card OK', '10000000.00000', '2024-09-15', '202709', null, 'MC PLATINUM CREDIT PRIN', 'TO CLOSE', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-29'),
  ('1012.00000', '412345******1012', 'Card OK', '40000000.00000', '2026-05-05', '202905', '2029-05-31', 'VISA GOLD CREDIT PRIN', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-29');
-- tf_partition_date = 2026-09-30: 16 dòng
insert into qa_expected.bi_intf__bi_card_info_intf__mnp (uniq_id_in_src_sys, card_nbr, card_status, card_limit_amt, card_open_date, originl_date_exp, actual_date_exp, card_prd_name, phys_card_status, bi_prd_type, bi_prd_group, tf_source_system, tf_run_id, tf_partition_date) values
  ('1001.00000', '545400******1001', 'Card OK', '50000000.00000', '2026-03-14', '202812', null, 'MC PLATINUM CREDIT PRIN', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1003.00000', '905555******1003', 'Card OK', '0.00000', '2025-06-10', '202706', '2027-06-30', 'MC2 DEBIT SUPP', 'READY', '01.Local Card', '02.Debit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1004.00000', '905555******1004', 'Card OK', '30000000.00000', '2025-06-10', '202706', '2027-06-30', 'MC2 CREDIT PRIN', 'LOCKED', '01.Local Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1006.00000', '545400******1006', null, '10000000.00000', '2026-08-31', '202908', null, 'MC PLATINUM CREDIT PRIN', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1007.00000', '545400******1007', 'Card Closed', '10000000.00000', '2024-09-15', '202709', '2026-09-30', 'MC PLATINUM CREDIT PRIN', 'TO CLOSE', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1008.00000', '545400******1008', 'Card OK', '15000000.00000', '2026-09-30', '202910', '2026-10-01', 'MC PLATINUM CREDIT PRIN', 'TO REQUEST', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1009.00000', '356789******1009', null, '0.00000', '2025-01-05', null, null, 'JCB CREDIT PRIN', null, '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1010.00000', '453201******1010', 'Card OK', '0.00000', '2025-02-01', null, null, 'VISA PREPAID VIR', 'TO MARK', '02.International Card', null, 'CARD_INTF', 'manual', '2026-09-30'),
  ('1011.00000', '621234******1011', 'Card OK', '0.00000', '2025-03-01', '202711', '2027-11-30', 'OUR IMPRINTER DEBIT', 'MARKED', '02.International Card', '02.Debit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1012.00000', '412345******1012', 'Card OK', '40000000.00000', '2026-05-05', '202905', '2029-05-31', 'VISA GOLD CREDIT PRIN', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1013.00000', '512345******1013', 'Card OK', '80000000.00000', '2026-09-29', '202901', '2029-01-31', null, 'READY', '02.International Card', '02.Debit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1014.00000', '412345******1014', 'Card OK', '80000000.00000', '2026-09-30', '202901', '2029-01-31', null, 'READY', '02.International Card', null, 'CARD_INTF', 'manual', '2026-09-30'),
  ('1015.00000', '545400******1015', 'Card OK', '25000000.00000', '2014-04-10', '202704', '2027-04-30', 'MC PLATINUM CREDIT PRIN', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1017.00000', '905555******1017', 'Card OK', '0.00000', '2014-01-01', '202712', null, 'MC2 DEBIT SUPP', 'READY', '01.Local Card', '02.Debit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1018.00000', '905555******1018', 'Card OK', '0.00000', '2013-12-31', '202712', null, 'MC2 DEBIT SUPP', 'READY', '01.Local Card', '02.Debit Card', 'CARD_INTF', 'manual', '2026-09-30'),
  ('1019.00000', '545400******1019', 'Card OK', '5000000.00000', '2013-06-15', '202706', null, 'MC PLATINUM CREDIT SUPP', 'READY', '02.International Card', '01.Credit Card', 'CARD_INTF', 'manual', '2026-09-30');

drop table if exists qa_expected.dwh_intf__card_intf;
create table qa_expected.dwh_intf__card_intf (business_date text, card_nbr text, contract_nbr text, prd_card_code text, limit_amt text, card_type text, status_name text, card_status text, prim_card_flag text, card_open_date text, exp_date text, src_sys_code text, uniq_id_in_src_sys text, actual_end_date text, src_info text);
-- business_date = 2026-09-29: 4 dòng
insert into qa_expected.dwh_intf__card_intf (business_date, card_nbr, contract_nbr, prd_card_code, limit_amt, card_type, status_name, card_status, prim_card_flag, card_open_date, exp_date, src_sys_code, uniq_id_in_src_sys, actual_end_date, src_info) values
  ('2026-09-29', '545400******1001', 'HD0002001', '301', '45000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-03-14', '2028-12-31', 'WAY4_ACNT_CONTRACT', '1001', '2026-10-01', 'T,AL26001001'),
  ('2026-09-29', '545400******1002', 'HD0002003', '302', '20000000.00000', 'CREDIT-CARD', 'Card OK', 'SENT', 'NO', '2026-03-20', '2028-12-31', 'WAY4_ACNT_CONTRACT', '1002', '2028-12-31', null),
  ('2026-09-29', '545400******1007', 'HD0002001', '301', '10000000.00000', 'CREDIT-CARD', 'Card OK', 'TO CLOSE', 'YES', '2024-09-15', '2027-09-30', 'WAY4_ACNT_CONTRACT', '1007', null, null),
  ('2026-09-29', '412345******1012', 'HD0002001', '310', '40000000.00000', 'DEBIT-CARD', 'Card OK', 'READY', 'YES', '2026-05-05', '2029-05-31', 'WAY4_ACNT_CONTRACT', '1012', '2029-05-31', null);
-- business_date = 2026-09-30: 17 dòng
insert into qa_expected.dwh_intf__card_intf (business_date, card_nbr, contract_nbr, prd_card_code, limit_amt, card_type, status_name, card_status, prim_card_flag, card_open_date, exp_date, src_sys_code, uniq_id_in_src_sys, actual_end_date, src_info) values
  ('2026-09-30', '545400******1001', 'HD0002001', '301', '50000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-03-14', '2028-12-31', 'WAY4_ACNT_CONTRACT', '1001', null, 'T,AL26001001'),
  ('2026-09-30', '905555******1003', 'HD0002002', '303', '0.00000', 'DEBIT-CARD', 'Card OK', 'READY', 'NO', '2025-06-10', '2027-06-30', 'WAY4_ACNT_CONTRACT', '1003', '2027-06-30', null),
  ('2026-09-30', '905555******1004', 'HD0002002', '304', '30000000.00000', 'DEBIT-CARD', 'Card OK', 'LOCKED', 'YES', '2025-06-10', '2027-06-30', 'WAY4_ACNT_CONTRACT', '1004', '2027-06-30', null),
  ('2026-09-30', '545400******1006', 'HD0002001', '301', '10000000.00000', 'CREDIT-CARD', null, 'READY', 'YES', '2026-08-31', '2029-08-31', 'WAY4_ACNT_CONTRACT', '1006', null, null),
  ('2026-09-30', '545400******1007', 'HD0002001', '301', '10000000.00000', 'CREDIT-CARD', 'Card Closed', 'TO CLOSE', 'YES', '2024-09-15', '2027-09-30', 'WAY4_ACNT_CONTRACT', '1007', '2026-09-30', null),
  ('2026-09-30', '545400******1008', 'HD0002001', '301', '15000000.00000', 'CREDIT-CARD', 'Card OK', 'TO REQUEST', 'YES', '2026-09-30', '2029-10-31', 'WAY4_ACNT_CONTRACT', '1008', '2026-10-01', null),
  ('2026-09-30', '356789******1009', 'HD0002002', '307', '0.00000', null, null, null, 'YES', '2025-01-05', null, 'WAY4_ACNT_CONTRACT', '1009', null, null),
  ('2026-09-30', '453201******1010', 'HD0002002', '306', '0.00000', null, 'Card OK', 'TO MARK', 'NO', '2025-02-01', null, 'WAY4_ACNT_CONTRACT', '1010', null, null),
  ('2026-09-30', '621234******1011', 'HD0002002', '305', '0.00000', 'DEBIT-CARD', 'Card OK', 'MARKED', 'YES', '2025-03-01', '2027-11-30', 'WAY4_ACNT_CONTRACT', '1011', '2027-11-30', null),
  ('2026-09-30', '412345******1012', 'HD0002001', '310', '40000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-05-05', '2029-05-31', 'WAY4_ACNT_CONTRACT', '1012', '2029-05-31', null),
  ('2026-09-30', '512345******1013', 'HD0002001', '311', '80000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-09-29', '2029-01-31', 'WAY4_ACNT_CONTRACT', '1013', '2029-01-31', null),
  ('2026-09-30', '412345******1014', 'HD0002001', '311', '80000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-09-30', '2029-01-31', 'WAY4_ACNT_CONTRACT', '1014', '2029-01-31', null),
  ('2026-09-30', '545400******1015', 'HD0002001', '301', '25000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2014-04-09', '2027-04-30', 'WAY4_ACNT_CONTRACT', '1015', '2027-04-30', null),
  ('2026-09-30', '905555******1016', 'HD0002002', '303', '0.00000', 'DEBIT-CARD', 'Card OK', 'READY', 'NO', '2013-12-31', '2027-12-31', 'WAY4_ACNT_CONTRACT', '1016', null, '_MOBI_PHONE'),
  ('2026-09-30', '905555******1017', 'HD0002002', '303', '0.00000', 'DEBIT-CARD', 'Card OK', 'READY', 'NO', '2014-01-01', '2027-12-31', 'WAY4_ACNT_CONTRACT', '1017', null, '_MOBI_PHONE'),
  ('2026-09-30', '905555******1018', 'HD0002002', '303', '0.00000', 'DEBIT-CARD', 'Card OK', 'READY', 'NO', '2013-12-31', '2027-12-31', 'WAY4_ACNT_CONTRACT', '1018', null, 'MOBI_PHONE'),
  ('2026-09-30', '545400******1019', 'HD0002001', '302', '5000000.00000', 'CREDIT-CARD', 'Card OK', 'READY', 'NO', '2013-06-15', '2027-06-30', 'WAY4_ACNT_CONTRACT', '1019', null, 'MOBIPHONE FYF');

