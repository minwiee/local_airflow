-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 02_deposit: nạp dữ liệu test cho các bảng nguồn
-- Ngày test: 2026-09-29, 2026-09-30. Dữ liệu sinh từ data/source/*.csv; chú thích cuối dòng là tình huống test của dòng đó.


-- ---------------------------------------------------------------------------
-- bi_intf.bi_depo_info_intf__mnp: 6 dòng (ngày 2026-09-28: 2 dòng; ngày 2026-09-29: 2 dòng; ngày 2026-09-30: 2 dòng)
-- ---------------------------------------------------------------------------
truncate table bi_intf.bi_depo_info_intf__mnp;

-- tf_partition_date = 2026-09-28: 2 dòng
insert into bi_intf.bi_depo_info_intf__mnp (contract_nbr, cust_code, ccy_code, notion_mat_date, inst_rate, close_amt_fcy, acct_seprt_type, prd_group_name, bi_term, cate_code, eff_date, tf_etl_at, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('LD2610000101', '1000001', 'VND', '2027-01-15', '5.0', '120000000', 'CUR', '2. Term Deposit', '12', '21017', '2026-01-15', '2026-09-28 23:40:00', null, 'prod', '2026-09-28', 'DEPO_INTF'),  -- S13 ngày 28 không chạy lại - phải còn nguyên
  ('LD2610000401', '1000016', 'VND', '2026-09-29', '5.0', '90000000', 'CUR', '2. Term Deposit', '6', '21017', '2026-03-29', '2026-09-28 23:40:00', null, 'prod', '2026-09-28', 'DEPO_INTF');  -- S14 ngày 28 còn hiệu lực - phải còn nguyên

-- tf_partition_date = 2026-09-29: 2 dòng
insert into bi_intf.bi_depo_info_intf__mnp (contract_nbr, cust_code, ccy_code, notion_mat_date, inst_rate, close_amt_fcy, acct_seprt_type, prd_group_name, bi_term, cate_code, eff_date, tf_etl_at, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('LD2610000101', '1000001', 'VND', '2027-01-15', '4.9', '110000000', 'CUR', '2. Term Deposit', '12', '21017', '2026-01-15', '2026-09-29 21:30:00', null, 'prod', '2026-09-29', 'DEPO_INTF'),  -- S13 dòng cũ của ngày 29 (số dư cũ) - bị pre_hook xóa
  ('LD2610000998', '1000098', 'VND', '2026-12-29', '4.0', '2000000', 'CUR', '2. Term Deposit', '3', '21017', '2026-09-29', '2026-09-29 21:30:00', null, 'prod', '2026-09-29', 'DEPO_INTF');  -- S13 hợp đồng không có ở nguồn - bị pre_hook xóa

-- tf_partition_date = 2026-09-30: 2 dòng
insert into bi_intf.bi_depo_info_intf__mnp (contract_nbr, cust_code, ccy_code, notion_mat_date, inst_rate, close_amt_fcy, acct_seprt_type, prd_group_name, bi_term, cate_code, eff_date, tf_etl_at, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('LD2610000101', '1000001', 'VND', '2027-01-15', '5.0', '120000000', 'CUR', '2. Term Deposit', '12', '21017', '2026-01-15', '2026-09-30 21:30:00', null, 'prod', '2026-09-30', 'DEPO_INTF'),  -- S13 dòng cũ của ngày 30 (số dư cũ) - bị pre_hook xóa
  ('LD2610000999', '1000099', 'VND', '2026-12-30', '4.0', '1000000', 'CUR', '2. Term Deposit', '3', '21017', '2026-09-30', '2026-09-30 21:30:00', null, 'prod', '2026-09-30', 'DEPO_INTF');  -- S13 hợp đồng không có ở nguồn - bị pre_hook xóa

-- ---------------------------------------------------------------------------
-- bi_ref.csv_partb_product__mnp: 23 dòng (ngày 2026-09-29: 12 dòng; ngày 2026-09-30: 11 dòng)
-- ---------------------------------------------------------------------------
truncate table bi_ref.csv_partb_product__mnp;

-- tf_partition_date = 2026-09-29: 12 dòng
insert into bi_ref.csv_partb_product__mnp (prd_code, prd_group, tf_partition_date) values
  ('1001', '1. Current Account', '2026-09-29'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('1002', '1. Current Account', '2026-09-29'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('1005', '1. Current Account', '2026-09-29'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('6601', '2. Term Deposit', '2026-09-29'),  -- không ảnh hưởng kết quả: tiền gửi trên tài khoản
  ('21012', '2. Term Deposit', '2026-09-29'),  -- nhóm tiền gửi có kỳ hạn
  ('21014', '2. Term Deposit', '2026-09-29'),  -- nhóm tiền gửi có kỳ hạn
  ('21017', '2. Term Deposit', '2026-09-29'),  -- nhóm tiền gửi có kỳ hạn
  ('21018', '2. Term Deposit', '2026-09-29'),  -- nhóm tiền gửi có kỳ hạn
  ('21019', '2. Term Deposit', '2026-09-29'),  -- S07 ngày 30 mã này không còn trong file
  ('21020', '2. Term Deposit', '2026-09-29'),  -- không ảnh hưởng kết quả: mã không có hợp đồng
  ('21030', '3. Others', '2026-09-29'),  -- S08 nhóm 3. Others: bi_term trống
  ('21085', '3. Others', '2026-09-29');  -- không ảnh hưởng kết quả: tiền gửi trên phân hệ MM

-- tf_partition_date = 2026-09-30: 11 dòng
insert into bi_ref.csv_partb_product__mnp (prd_code, prd_group, tf_partition_date) values
  ('1001', '1. Current Account', '2026-09-30'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('1002', '1. Current Account', '2026-09-30'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('1005', '1. Current Account', '2026-09-30'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('6601', '2. Term Deposit', '2026-09-30'),  -- không ảnh hưởng kết quả: tiền gửi trên tài khoản
  ('21012', '2. Term Deposit', '2026-09-30'),  -- nhóm tiền gửi có kỳ hạn
  ('21014', '2. Term Deposit', '2026-09-30'),  -- nhóm tiền gửi có kỳ hạn
  ('21017', '2. Term Deposit', '2026-09-30'),  -- nhóm tiền gửi có kỳ hạn
  ('21018', '2. Term Deposit', '2026-09-30'),  -- nhóm tiền gửi có kỳ hạn
  ('21020', '2. Term Deposit', '2026-09-30'),  -- không ảnh hưởng kết quả: mã không có hợp đồng
  ('21030', '3. Others', '2026-09-30'),  -- S08 nhóm 3. Others: bi_term trống
  ('21085', '3. Others', '2026-09-30');  -- không ảnh hưởng kết quả: tiền gửi trên phân hệ MM

-- ---------------------------------------------------------------------------
-- dwh_intf.depo_intf: 7 dòng (ngày 2026-09-28: 3 dòng; ngày 2026-09-29: 2 dòng; ngày 2026-09-30: 2 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_intf.depo_intf;

-- business_date = 2026-09-28: 3 dòng
insert into dwh_intf.depo_intf (business_date, ppn_date, contract_nbr, cust_code, ccy_code, mgmt_branch_code, cate_code, close_date, inst_rate, inst_pmt_method, depo_close_type, close_amt_fcy, notion_mat_date, term, acct_seprt_type, value_date) values
  ('2026-09-28', '2026-09-28 23:10:00', 'LD2610000101', '1000001', 'VND', 'VN0010102', '21017', null, '5.0', 'CUOI KY', null, '120000000', '2027-01-15', '12M', 'CUR', '2026-01-15'),  -- S13 ngày 28 không chạy lại - phải còn nguyên
  ('2026-09-28', '2026-09-28 23:10:00', 'LD2610000401', '1000016', 'VND', 'VN0010204', '21017', null, '5.0', 'CUOI KY', null, '90000000', '2026-09-29', '6M', 'CUR', '2026-03-29'),  -- S14 ngày 28 còn hiệu lực - phải còn nguyên
  ('2026-09-28', '2026-09-28 23:10:00', 'LD2610000403', '1000018', 'VND', 'VN0010305', '21017', '2026-09-28', '0.2', 'CUOI KY', 'MAT_EARLY', '40000000', '2026-11-28', '3M', 'CLOSE', '2026-08-28');  -- S16 đã có dòng CLOSE từ ngày 28 - phải còn nguyên

-- business_date = 2026-09-29: 2 dòng
insert into dwh_intf.depo_intf (business_date, ppn_date, contract_nbr, cust_code, ccy_code, mgmt_branch_code, cate_code, close_date, inst_rate, inst_pmt_method, depo_close_type, close_amt_fcy, notion_mat_date, term, acct_seprt_type, value_date) values
  ('2026-09-29', '2026-09-29 21:00:00', 'LD2610000101', '1000001', 'VND', 'VN0010102', '21017', null, '4.9', 'CUOI KY', null, '110000000', '2027-01-15', '12M', 'CUR', '2026-01-15'),  -- S13 dòng cũ của ngày 29 (số dư cũ) - bị pre_hook xóa
  ('2026-09-29', '2026-09-29 21:00:00', 'LD2610000998', '1000098', 'VND', 'VN0010102', '21017', null, '4.0', 'CUOI KY', null, '2000000', '2026-12-29', '3M', 'CUR', '2026-09-29');  -- S13 hợp đồng không có ở nguồn - bị pre_hook xóa

-- business_date = 2026-09-30: 2 dòng
insert into dwh_intf.depo_intf (business_date, ppn_date, contract_nbr, cust_code, ccy_code, mgmt_branch_code, cate_code, close_date, inst_rate, inst_pmt_method, depo_close_type, close_amt_fcy, notion_mat_date, term, acct_seprt_type, value_date) values
  ('2026-09-30', '2026-09-30 21:00:00', 'LD2610000101', '1000001', 'VND', 'VN0010102', '21017', null, '5.0', 'CUOI KY', null, '120000000', '2027-01-15', '12M', 'CUR', '2026-01-15'),  -- S13 dòng cũ của ngày 30 (số dư cũ) - bị pre_hook xóa
  ('2026-09-30', '2026-09-30 21:00:00', 'LD2610000999', '1000099', 'VND', 'VN0010102', '21017', null, '4.0', 'CUOI KY', null, '1000000', '2026-12-30', '3M', 'CUR', '2026-09-30');  -- S13 hợp đồng không có ở nguồn - bị pre_hook xóa

-- ---------------------------------------------------------------------------
-- dwh_ref.csv_ma_map_cgy_ar_tp__mnp: 26 dòng (ngày 2026-09-29: 13 dòng; ngày 2026-09-30: 13 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_ref.csv_ma_map_cgy_ar_tp__mnp;

-- tf_partition_date = 2026-09-29: 13 dòng
insert into dwh_ref.csv_ma_map_cgy_ar_tp__mnp (category, ar_tp, tf_partition_date) values
  ('1001', 'CST-CRN-AC', '2026-09-29'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('6601', 'CST-TERM-DEP', '2026-09-29'),  -- không ảnh hưởng kết quả: tiền gửi trên tài khoản
  ('21012', 'T24-DEP-LD', '2026-09-29'),  -- category tiền gửi LD
  ('21014', 'T24-DEP-LD', '2026-09-29'),  -- category tiền gửi LD
  ('21017', 'T24-DEP-LD', '2026-09-29'),  -- category tiền gửi LD
  ('21018', 'T24-DEP-LD', '2026-09-29'),  -- S03 category tiền gửi LD
  ('21018', 'T24-DEP-LD', '2026-09-29'),  -- S03 dòng lặp của 21018: không được nhân đôi hợp đồng
  ('21019', 'T24-DEP-LD', '2026-09-29'),  -- S07 category tiền gửi LD
  ('21030', 'T24-DEP-LD', '2026-09-29'),  -- S08 category tiền gửi LD
  ('21050', 'T24-LOAN-LD', '2026-09-29'),  -- S11 category vay
  ('21055', 'T24-LOAN-LD', '2026-09-29'),  -- không ảnh hưởng kết quả: category vay không có hợp đồng
  ('21060', 'T24-DEP-LD', '2026-09-29'),  -- S11 ghi nhầm là tiền gửi (ngày 30 sửa thành vay)
  ('21085', 'T24-DEP-MM', '2026-09-29');  -- không ảnh hưởng kết quả: tiền gửi trên phân hệ MM

-- tf_partition_date = 2026-09-30: 13 dòng
insert into dwh_ref.csv_ma_map_cgy_ar_tp__mnp (category, ar_tp, tf_partition_date) values
  ('1001', 'CST-CRN-AC', '2026-09-30'),  -- không ảnh hưởng kết quả: tài khoản thanh toán
  ('6601', 'CST-TERM-DEP', '2026-09-30'),  -- không ảnh hưởng kết quả: tiền gửi trên tài khoản
  ('21012', 'T24-DEP-LD', '2026-09-30'),  -- category tiền gửi LD
  ('21014', 'T24-DEP-LD', '2026-09-30'),  -- category tiền gửi LD
  ('21017', 'T24-DEP-LD', '2026-09-30'),  -- category tiền gửi LD
  ('21018', 'T24-DEP-LD', '2026-09-30'),  -- S03 category tiền gửi LD
  ('21018', 'T24-DEP-LD', '2026-09-30'),  -- S03 dòng lặp của 21018: không được nhân đôi hợp đồng
  ('21019', 'T24-DEP-LD', '2026-09-30'),  -- S07 category tiền gửi LD
  ('21030', 'T24-DEP-LD', '2026-09-30'),  -- S08 category tiền gửi LD
  ('21050', 'T24-LOAN-LD', '2026-09-30'),  -- S11 category vay
  ('21055', 'T24-LOAN-LD', '2026-09-30'),  -- không ảnh hưởng kết quả: category vay không có hợp đồng
  ('21060', 'T24-LOAN-LD', '2026-09-30'),  -- S11 đã sửa thành vay
  ('21085', 'T24-DEP-MM', '2026-09-30');  -- không ảnh hưởng kết quả: tiền gửi trên phân hệ MM

-- ---------------------------------------------------------------------------
-- raw_eod.t24_ld_loans_and_depo__mnp: 37 dòng (ngày 2026-09-28: 2 dòng; ngày 2026-09-29: 19 dòng; ngày 2026-09-30: 16 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.t24_ld_loans_and_depo__mnp;

-- tf_partition_date = 2026-09-28: 2 dòng
insert into raw_eod.t24_ld_loans_and_depo__mnp (contract_no_, category, customer_id, currency, co_code, status, value_date, fin_mat_date, int_paymt_method, tf_partition_date) values
  ('LD2610000401', '21017', '1000016', 'VND', 'VN0010204', 'CUR', '20260329', '20260929', '1', '2026-09-28'),  -- S14 ngày 28 còn hiệu lực
  ('LD2610000403', '21017', '1000018', 'VND', 'VN0010305', 'LIQ', '20260828', '20261128', '1', '2026-09-28');  -- S16 đã tất toán từ ngày 28

-- tf_partition_date = 2026-09-29: 19 dòng
insert into raw_eod.t24_ld_loans_and_depo__mnp (contract_no_, category, customer_id, currency, co_code, status, value_date, fin_mat_date, int_paymt_method, tf_partition_date) values
  ('LD2610000101', '21017', '1000001', 'VND', 'VN0010102', 'CUR', '20260115', '20270115', '1', '2026-09-29'),  -- S01 còn hiệu lực - 365 ngày
  ('LD2610000102', '21014', '1000002', 'USD', 'VN0010204', 'CUR', '20250930', '20270930', '2', '2026-09-29'),  -- S02 USD - trả lãi đầu kỳ - 730 ngày
  ('LD2610000104', '21017', '1000004', 'VND', 'VN0010102', 'CUR', '20260903', '20260930', '1', '2026-09-29'),  -- S04 27 ngày - đáo hạn ngày 30
  ('LD2610000105', '21017', '1000005', 'VND', 'VN0010305', 'CUR', '20260928', '20261003', '1', '2026-09-29'),  -- S05 5 ngày - hiệu lực từ ngày 28
  ('LD2610000106', '21012', '1000001', 'VND', 'VN0010102', 'CUR', '20260115', '20270116', '2', '2026-09-29'),  -- S06 366 ngày
  ('LD2610000107', '21019', '1000006', 'VND', 'VN0010204', 'CUR', '20260820', '20261120', '1', '2026-09-29'),  -- S07 category 21019
  ('LD2610000108', '21030', '1000007', 'VND', 'VN0010103', 'CUR', '20260701', '20270101', '1', '2026-09-29'),  -- S08 category 21030 thuộc nhóm 3. Others
  ('LD2610000201', '21017', '1000008', 'VND', 'VN0010102', 'CUR', '20260330', '20260930', '1', '2026-09-29'),  -- S09 còn hiệu lực - ngày 30 tất toán đúng hạn
  ('LD2610000202', '21018', '1000009', 'VND', 'VN0010204', 'CUR', '20260701', '20261001', '1', '2026-09-29'),  -- S10 còn hiệu lực - ngày 30 tất toán trước hạn
  ('LD2610000301', '21050', '1000010', 'VND', 'VN0010102', 'CUR', '20260601', '20270601', '1', '2026-09-29'),  -- S11 hợp đồng vay (21050): không lên
  ('LD2610000302', '21060', '1000011', 'VND', 'VN0010305', 'CUR', '20260101', '20261231', '1', '2026-09-29'),  -- S11 vay - file map ngày 29 ghi 21060 là tiền gửi: lên
  ('LD2610000303', '21017', '1000012', 'VND', 'VN0010102', null, '20260801', '20261101', '1', '2026-09-29'),  -- S12 trạng thái trống: không lên
  ('LD2610000304', '21017', '1000013', 'VND', 'VN0010204', 'CUR', '20261001', '20270401', '1', '2026-09-29'),  -- S12 hiệu lực từ 01/10: không lên
  ('LD2610000305', '21017', '1000014', 'VND', 'VN0010103', 'CUR', '20260629', '20260929', '1', '2026-09-29'),  -- S12 đáo hạn đúng ngày 29 - còn CUR: vẫn lên
  ('LD2610000306', '21017', '1000015', 'VND', 'VN0010102', 'CUR', '20260329', '20261229', '1', '2026-09-29'),  -- S12 còn hiệu lực - ngày 30 không còn trong nguồn
  ('LD2610000307', '21014', '1000019', 'VND', 'VN0010204', 'CUR', '20260829', '20260929', '1', '2026-09-29'),  -- S17 đáo hạn đúng ngày 29 - còn CUR: vẫn lên
  ('LD2610000401', '21017', '1000016', 'VND', 'VN0010204', 'LIQ', '20260329', '20260929', '1', '2026-09-29'),  -- S14 tất toán đúng hạn ngày 29
  ('LD2610000402', '21012', '1000017', 'VND', 'VN0010103', 'LIQ', '20260929', '20261229', '1', '2026-09-29'),  -- S15 mở và tất toán trong cùng ngày 29
  ('LD2610000403', '21017', '1000018', 'VND', 'VN0010305', 'LIQ', '20260828', '20261128', '1', '2026-09-29');  -- S16 vẫn LIQ trong nguồn: lại ra dòng CLOSE

-- tf_partition_date = 2026-09-30: 16 dòng
insert into raw_eod.t24_ld_loans_and_depo__mnp (contract_no_, category, customer_id, currency, co_code, status, value_date, fin_mat_date, int_paymt_method, tf_partition_date) values
  ('LD2610000101', '21017', '1000001', 'VND', 'VN0010102', 'CUR', '20260115', '20270115', '1', '2026-09-30'),  -- S01 còn hiệu lực - 365 ngày
  ('LD2610000102', '21014', '1000002', 'USD', 'VN0010204', 'CUR', '20250930', '20270930', '2', '2026-09-30'),  -- S02 USD - trả lãi đầu kỳ - 730 ngày
  ('LD2610000103', '21018', '1000003', 'VND', 'VN0010103', 'CUR', '20260930', '20261028', null, '2026-09-30'),  -- S03 mở ngày 30 - 28 ngày - int_paymt_method trống
  ('LD2610000104', '21017', '1000004', 'VND', 'VN0010102', 'CUR', '20260903', '20260930', '1', '2026-09-30'),  -- S04 đáo hạn đúng ngày 30 nhưng còn CUR: vẫn lên
  ('LD2610000105', '21017', '1000005', 'VND', 'VN0010305', 'CUR', '20260928', '20261003', '1', '2026-09-30'),  -- S05 5 ngày
  ('LD2610000106', '21012', '1000001', 'VND', 'VN0010102', 'CUR', '20260115', '20270116', '2', '2026-09-30'),  -- S06 366 ngày
  ('LD2610000107', '21019', '1000006', 'VND', 'VN0010204', 'CUR', '20260820', '20261120', '1', '2026-09-30'),  -- S07 category 21019
  ('LD2610000108', '21030', '1000007', 'VND', 'VN0010103', 'CUR', '20260701', '20270101', '1', '2026-09-30'),  -- S08 category 21030 thuộc nhóm 3. Others
  ('LD2610000201', '21017', '1000008', 'VND', 'VN0010102', 'LIQ', '20260330', '20260930', '1', '2026-09-30'),  -- S09 tất toán đúng hạn ngày 30
  ('LD2610000202', '21018', '1000009', 'VND', 'VN0010204', 'LIQ', '20260701', '20261001', '1', '2026-09-30'),  -- S10 tất toán trước hạn (đáo hạn 01/10)
  ('LD2610000301', '21050', '1000010', 'VND', 'VN0010102', 'CUR', '20260601', '20270601', '1', '2026-09-30'),  -- S11 hợp đồng vay (21050): không lên
  ('LD2610000302', '21060', '1000011', 'VND', 'VN0010305', 'LIQ', '20260101', '20261231', '1', '2026-09-30'),  -- S11 vay - file map đã sửa 21060 thành vay: không lên
  ('LD2610000303', '21017', '1000012', 'VND', 'VN0010102', null, '20260801', '20261101', '1', '2026-09-30'),  -- S12 trạng thái trống: không lên
  ('LD2610000304', '21017', '1000013', 'VND', 'VN0010204', 'CUR', '20261001', '20270401', '1', '2026-09-30'),  -- S12 hiệu lực từ 01/10: không lên
  ('LD2610000305', '21017', '1000014', 'VND', 'VN0010103', 'CUR', '20260629', '20260929', '1', '2026-09-30'),  -- S12 quá ngày đáo hạn mà vẫn CUR: không lên
  ('LD2610000307', '21014', '1000019', 'VND', 'VN0010204', 'LIQ', '20260829', '20260929', '1', '2026-09-30');  -- S17 tất toán sau ngày đáo hạn: không lên - không có CLOSE

-- ---------------------------------------------------------------------------
-- raw_eod.t24_ld_loans_and_depo_details__mnp: 40 dòng (ngày 2026-09-28: 2 dòng; ngày 2026-09-29: 20 dòng; ngày 2026-09-30: 18 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.t24_ld_loans_and_depo_details__mnp;

-- tf_partition_date = 2026-09-28: 2 dòng
insert into raw_eod.t24_ld_loans_and_depo_details__mnp (contract_no_, m, s, amount, interest_rate, tf_partition_date) values
  ('LD2610000401', '1', '1', '90000000', '5.0', '2026-09-28'),  -- S14 số dư trước khi tất toán: 90 triệu
  ('LD2610000403', '1', '1', '0', '0.2', '2026-09-28');  -- S16 đã tất toán: số dư 0

-- tf_partition_date = 2026-09-29: 20 dòng
insert into raw_eod.t24_ld_loans_and_depo_details__mnp (contract_no_, m, s, amount, interest_rate, tf_partition_date) values
  ('LD2610000101', '1', '1', '120000000', '5.0', '2026-09-29'),  -- S01 số dư 120 triệu - lãi suất 5.0
  ('LD2610000101', '2', '1', '1000000', '1.0', '2026-09-29'),  -- S01 dòng m=2: không được lấy
  ('LD2610000102', '1', '1', '5000', '3.5', '2026-09-29'),  -- S02 không đổi giữa hai ngày
  ('LD2610000104', '1', '1', '30000000', '3.0', '2026-09-29'),  -- S04 không đổi giữa hai ngày
  ('LD2610000105', '1', '1', '15000000', '2.0', '2026-09-29'),  -- S05 ngày 29 còn dòng m=1 s=1
  ('LD2610000106', '1', '1', '200000000', '5.5', '2026-09-29'),  -- S06 không đổi giữa hai ngày
  ('LD2610000107', '1', '1', '45000000', '4.5', '2026-09-29'),  -- S07 không đổi giữa hai ngày
  ('LD2610000108', '1', '1', '60000000', '4.8', '2026-09-29'),  -- S08 không đổi giữa hai ngày
  ('LD2610000201', '1', '1', '50000000', '5.0', '2026-09-29'),  -- S09 số dư 50 triệu: ngày 30 lấy làm số dư tất toán
  ('LD2610000202', '1', '1', '80000000', '4.8', '2026-09-29'),  -- S10 số dư 80 triệu - lãi suất 4.8
  ('LD2610000301', '1', '1', '500000000', '9.5', '2026-09-29'),  -- S11 khoản vay
  ('LD2610000302', '1', '1', '300000000', '10.0', '2026-09-29'),  -- S11 khoản vay lọt vào interface tiền gửi
  ('LD2610000303', '1', '1', '10000000', '4.0', '2026-09-29'),  -- S12 không lên
  ('LD2610000304', '1', '1', '25000000', '4.3', '2026-09-29'),  -- S12 không lên
  ('LD2610000305', '1', '1', '35000000', '4.1', '2026-09-29'),  -- S12 đáo hạn ngày 29
  ('LD2610000306', '1', '1', '70000000', '4.6', '2026-09-29'),  -- S12 ngày 30 không còn trong nguồn
  ('LD2610000307', '1', '1', '40000000', '3.8', '2026-09-29'),  -- S17 đáo hạn ngày 29
  ('LD2610000401', '1', '1', '0', '5.0', '2026-09-29'),  -- S14 đã tất toán: số dư 0
  ('LD2610000402', '1', '1', '0', '0.2', '2026-09-29'),  -- S15 đã tất toán: số dư 0
  ('LD2610000403', '1', '1', '0', '0.2', '2026-09-29');  -- S16 số dư 0 từ ngày 28

-- tf_partition_date = 2026-09-30: 18 dòng
insert into raw_eod.t24_ld_loans_and_depo_details__mnp (contract_no_, m, s, amount, interest_rate, tf_partition_date) values
  ('LD2610000101', '1', '1', '100000000', '5.2', '2026-09-30'),  -- S01 số dư 100 triệu - lãi suất 5.2 (khác ngày 29)
  ('LD2610000101', '2', '1', '1000000', '1.0', '2026-09-30'),  -- S01 dòng m=2: không được lấy
  ('LD2610000102', '1', '1', '5000', '3.5', '2026-09-30'),  -- S02 không đổi giữa hai ngày
  ('LD2610000103', '1', '1', '20000000', '4.0', '2026-09-30'),  -- S03 hợp đồng mở ngày 30
  ('LD2610000103', '1', '2', '5000000', '1.5', '2026-09-30'),  -- S03 dòng s=2: không được lấy
  ('LD2610000104', '1', '1', '30000000', '3.0', '2026-09-30'),  -- S04 không đổi giữa hai ngày
  ('LD2610000105', '2', '1', '15000000', '2.0', '2026-09-30'),  -- S05 mất dòng m=1 s=1: số dư và lãi suất trống
  ('LD2610000106', '1', '1', '200000000', '5.5', '2026-09-30'),  -- S06 không đổi giữa hai ngày
  ('LD2610000107', '1', '1', '45000000', '4.5', '2026-09-30'),  -- S07 không đổi giữa hai ngày
  ('LD2610000108', '1', '1', '60000000', '4.8', '2026-09-30'),  -- S08 không đổi giữa hai ngày
  ('LD2610000201', '1', '1', '0', '5.0', '2026-09-30'),  -- S09 đã tất toán: số dư 0
  ('LD2610000202', '1', '1', '0', '0.5', '2026-09-30'),  -- S10 đã tất toán: số dư 0 - lãi suất 0.5
  ('LD2610000301', '1', '1', '500000000', '9.5', '2026-09-30'),  -- S11 khoản vay
  ('LD2610000302', '1', '1', '0', '10.0', '2026-09-30'),  -- S11 khoản vay đã tất toán
  ('LD2610000303', '1', '1', '10000000', '4.0', '2026-09-30'),  -- S12 không lên
  ('LD2610000304', '1', '1', '25000000', '4.3', '2026-09-30'),  -- S12 không lên
  ('LD2610000305', '1', '1', '35000000', '4.1', '2026-09-30'),  -- S12 nguồn còn số dư nhưng hợp đồng không lên
  ('LD2610000307', '1', '1', '0', '3.8', '2026-09-30');  -- S17 đã tất toán: số dư 0

-- Đưa log về trạng thái chưa chạy: QA chỉ được test sau khi DAG ghi success
delete from dwh_ctrl.log_etl_table where data_date in ('2026-09-29', '2026-09-30') and job_name in ('depo_intf_dag', 'bi_depo_info_intf__mnp_dag');
