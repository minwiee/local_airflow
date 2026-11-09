-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 03_loan: nạp dữ liệu test cho các bảng nguồn
-- Ngày test: 2026-09-29, 2026-09-30. Dữ liệu sinh từ data/source/*.csv; chú thích cuối dòng là tình huống test của dòng đó.


-- ---------------------------------------------------------------------------
-- bi_intf.bi_lend_repay_info_intf__fa: 3 dòng (ngày 2026-09-28: 1 dòng; ngày 2026-09-29: 1 dòng; ngày 2026-09-30: 1 dòng)
-- ---------------------------------------------------------------------------
truncate table bi_intf.bi_lend_repay_info_intf__fa;

-- business_date = 2026-09-28: 1 dòng
insert into bi_intf.bi_lend_repay_info_intf__fa (contract_nbr, ccy_code, repay_date, repay_amt_lcy, prin_amt_lcy, inst_amt_lcy, prin_repay_acct, inst_repay_acct, nbr_of_ovd_day, business_date, cust_code, repay_acty_code, tf_etl_at, tf_sourcing_at, tf_run_id, tf_source_system, tf_partition_date) values
  ('LD2407500001', 'VND', '2026-09-28', '12000000', '10000000', '2000000', '9990000101', '9990000101', null, '2026-09-28', '9000001', 'LD2407500001-20260928-S000080', '2026-09-28 23:40:00', null, 'prev_run', 'REPAY_ACTY_INTF', '2026-09-28');  -- L20 ngày 28 không chạy lại - phải còn nguyên

-- business_date = 2026-09-29: 1 dòng
insert into bi_intf.bi_lend_repay_info_intf__fa (contract_nbr, ccy_code, repay_date, repay_amt_lcy, prin_amt_lcy, inst_amt_lcy, prin_repay_acct, inst_repay_acct, nbr_of_ovd_day, business_date, cust_code, repay_acty_code, tf_etl_at, tf_sourcing_at, tf_run_id, tf_source_system, tf_partition_date) values
  ('LD2699900098', 'VND', '2026-09-29', '1', '1', '0', '9999999998', '9999999998', null, '2026-09-29', '9999998', 'LD2699900098-20260929-S000001', '2026-09-29 21:30:00', null, 'prev_run', 'REPAY_ACTY_INTF', '2026-09-29');  -- L20 dòng cũ của ngày 29 - bị pre_hook xóa

-- business_date = 2026-09-30: 1 dòng
insert into bi_intf.bi_lend_repay_info_intf__fa (contract_nbr, ccy_code, repay_date, repay_amt_lcy, prin_amt_lcy, inst_amt_lcy, prin_repay_acct, inst_repay_acct, nbr_of_ovd_day, business_date, cust_code, repay_acty_code, tf_etl_at, tf_sourcing_at, tf_run_id, tf_source_system, tf_partition_date) values
  ('LD2699900098', 'VND', '2026-09-30', '1', '1', '0', '9999999998', '9999999998', null, '2026-09-30', '9999998', 'LD2699900098-20260930-S000001', '2026-09-30 21:30:00', null, 'prev_run', 'REPAY_ACTY_INTF', '2026-09-30');  -- L20 dòng cũ của ngày 30 - bị pre_hook xóa

-- ---------------------------------------------------------------------------
-- dwh_intf.loan_contract_intf: 4 dòng (ngày 2026-09-28: 2 dòng; ngày 2026-09-29: 1 dòng; ngày 2026-09-30: 1 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_intf.loan_contract_intf;

-- business_date = 2026-09-28: 2 dòng
insert into dwh_intf.loan_contract_intf (business_date, ppn_date, contract_nbr, cust_code, cate_code, ccy_code, value_date, mat_date, term, inst_rate_type, inst_rate, inst_reset_freq, outs_prin_amt, prin_repay_acct_nbr, inst_repay_acct_nbr, nbr_ovd_day) values
  ('2026-09-28', '2026-09-28 23:20:00', 'LD2407500001', '9000001', '21050', 'VND', '2024-03-15', '2027-03-15', '36M', 'FIXED', '9.5', null, '526000000', '9990000101', '9990000101', '0'),  -- L20 ngày 28 không chạy lại - phải còn nguyên
  ('2026-09-28', '2026-09-28 23:20:00', 'LD2508900013', '9000011', '21050', 'VND', '2025-03-30', '2026-09-30', '18M', 'FIXED', '9.9', null, '20000000', '1300001101', '1300001101', '0');  -- L20 ngày 28 không chạy lại - phải còn nguyên

-- business_date = 2026-09-29: 1 dòng
insert into dwh_intf.loan_contract_intf (business_date, ppn_date, contract_nbr, cust_code, cate_code, ccy_code, value_date, mat_date, term, inst_rate_type, inst_rate, inst_reset_freq, outs_prin_amt, prin_repay_acct_nbr, inst_repay_acct_nbr, nbr_ovd_day) values
  ('2026-09-29', '2026-09-29 21:00:00', 'LD2699900098', '9999998', '21050', 'VND', '2020-01-01', '2030-01-01', 'DONG CU', 'FIXED', '1', null, '1', '9999999998', '9999999998', '0');  -- L20 dòng cũ của ngày 29 - bị pre_hook xóa

-- business_date = 2026-09-30: 1 dòng
insert into dwh_intf.loan_contract_intf (business_date, ppn_date, contract_nbr, cust_code, cate_code, ccy_code, value_date, mat_date, term, inst_rate_type, inst_rate, inst_reset_freq, outs_prin_amt, prin_repay_acct_nbr, inst_repay_acct_nbr, nbr_ovd_day) values
  ('2026-09-30', '2026-09-30 21:00:00', 'LD2699900098', '9999998', '21050', 'VND', '2020-01-01', '2030-01-01', 'DONG CU', 'FIXED', '1', null, '1', '9999999998', '9999999998', '0');  -- L20 dòng cũ của ngày 30 - bị pre_hook xóa

-- ---------------------------------------------------------------------------
-- dwh_intf.repay_acty_intf: 22 dòng (ngày 2026-09-29: 12 dòng; ngày 2026-09-30: 10 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_intf.repay_acty_intf;

-- business_date = 2026-09-29: 12 dòng
insert into dwh_intf.repay_acty_intf (business_date, repay_acty_code, contract_nbr, cate_code, cust_code, ccy_code, repay_date, repay_amt, prin_amt, inst_amt) values
  ('2026-09-29', 'LD2407500001-20260929-S000099', 'LD2407500001', '21050', '9000001', 'VND', '2026-09-29', '16500000', '12000000', '4500000'),  -- L01 tài khoản lấy từ L1 ngày 29 (tài khoản cũ)
  ('2026-09-29', 'LD2516600002-20260929-S000091', 'LD2516600002', '21050', '9000002', 'USD', '2026-09-29', '300.25', '0', '300.25'),  -- L02 trả lãi bằng USD - số tiền giữ nguyên
  ('2026-09-29', 'LD2524400003-20260928-S000092', 'LD2524400003', '21050', '9000003', 'VND', '2026-09-28', '2000000', '0', '2000000'),  -- L03 giao dịch ghi lùi ngày (ngày trả 28/09)
  ('2026-09-29', 'LD2605100005-20260929-S000093', 'LD2605100005', '21059', '9000005', 'VND', '2026-09-29', '1200000', '0', '1200000'),  -- L05 category 21059 nên bị loại
  ('2026-09-29', 'LD2533500006-20260929-S000094', 'LD2533500006', '21062', '9000006', 'VND', '2026-09-29', '850000', '0', '850000'),  -- L06 category 21062 vẫn được lấy
  ('2026-09-29', 'PDLD2324300007-20260929', 'PDLD2324300007', '21050', '9000001', 'VND', '2026-09-29', '30000000', '25000000', '5000000'),  -- L07 trả nợ quá hạn - đổi về số LD - quá hạn 29 ngày
  ('2026-09-29', 'LD2612500008-20260929-S000095', 'LD2612500008', '21050', '9000007', 'VND', '2026-09-29', '2200000', '0', '2200000'),  -- L08 L1 ngày 29 đủ thuộc tính nên có tài khoản
  ('2026-09-29', 'PDLD2428400010-20260929', 'PDLD2428400010', '21050', '9000009', 'VND', '2026-09-29', '6000000', '0', '6000000'),  -- L10 trả lãi quá hạn - đổi về số LD - quá hạn 4 ngày
  ('2026-09-29', 'LD2606200017-20260929-S000096', 'LD2606200017', '21055', '9000005', 'VND', '2026-09-29', '6300000', '5800000', '500000'),  -- L17 ngày 29 hợp đồng còn trên L1 nên có tài khoản
  ('2026-09-29', 'LD2609400018-20260929-S000097', 'LD2609400018', '21050', '9000006', 'VND', '2026-09-29', '900000', null, '900000'),  -- L18 phần gốc trống
  ('2026-09-29', 'LD2619600022-20260929-S000098', 'LD2619600022', '21065', '9000014', 'VND', '2026-09-29', '3000000', '2000000', '1000000'),  -- L22 hợp đồng chưa lên L1 ngày 29 nên tài khoản trống
  ('2026-09-29', 'LD2699900099-20260929-S000090', 'LD2699900099', null, null, 'VND', '2026-09-29', '500000', '500000', '0');  -- L19 category trống nên bị loại

-- business_date = 2026-09-30: 10 dòng
insert into dwh_intf.repay_acty_intf (business_date, repay_acty_code, contract_nbr, cate_code, cust_code, ccy_code, repay_date, repay_amt, prin_amt, inst_amt) values
  ('2026-09-30', 'LD2407500001-20260930-S000101', 'LD2407500001', '21050', '9000001', 'VND', '2026-09-30', '18000000', '14000000', '4000000'),  -- L01 tài khoản lấy từ L1 ngày 30 (tài khoản mới)
  ('2026-09-30', 'LD2601000004-20260929-S000102', 'LD2601000004', '21050', '9000004', 'VND', '2026-09-29', '5200000', '5000000', '200000'),  -- L04 ghi lùi ngày (ngày trả 29/09) - tài khoản gốc trống
  ('2026-09-30', 'PDLD2324300007-20260930', 'PDLD2324300007', '21050', '9000001', 'VND', '2026-09-30', '52500000', '50000000', '2500000'),  -- L07 trả nợ quá hạn - đổi về số LD - quá hạn 30 ngày
  ('2026-09-30', 'LD2324300007-20260930-S000104', 'LD2324300007', '21050', '9000001', 'VND', '2026-09-30', '1000000', '0', '1000000'),  -- L07 trả nợ trong hạn - số ngày quá hạn để trống
  ('2026-09-30', 'LD2612500008-20260930-S000105', 'LD2612500008', '21050', '9000007', 'VND', '2026-09-30', '5000000', '5000000', null),  -- L08 L1 ngày 30 thiếu thuộc tính nên tài khoản trống
  ('2026-09-30', 'LD2508900013-20260930-S000106', 'LD2508900013', '21050', '9000011', 'VND', '2026-09-30', '20100000', '20000000', '100000'),  -- L13 tất toán - hợp đồng không còn trên L1 ngày 30
  ('2026-09-30', 'LD2605100005-20260930-S000107', 'LD2605100005', '21059', '9000005', 'VND', '2026-09-30', '3500000', '3000000', '500000'),  -- L05 category 21059 nên bị loại
  ('2026-09-30', 'LD2699900099-20260930-S000108', 'LD2699900099', null, null, 'VND', '2026-09-30', '700000', '700000', '0'),  -- L19 category trống nên bị loại
  ('2026-09-30', 'PDPD2619900099-20260930', 'PDPD2619900099', '21050', '9000012', 'VND', '2026-09-30', '3300000', '3000000', '300000'),  -- L19 số PDPD giữ nguyên - không có trên L1
  ('2026-09-30', 'LD2516600002-20260930-S000109', 'LD2516600002', '21050', '9000002', 'USD', '2026-09-30', '1250.5', '1000', '250.5');  -- L02 giao dịch USD - số tiền giữ nguyên

-- ---------------------------------------------------------------------------
-- dwh_ref.csv_ma_map_cgy_ar_tp__mnp: 23 dòng (ngày 2026-09-29: 11 dòng; ngày 2026-09-30: 12 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_ref.csv_ma_map_cgy_ar_tp__mnp;

-- tf_partition_date = 2026-09-29: 11 dòng
insert into dwh_ref.csv_ma_map_cgy_ar_tp__mnp (category, ar_tp, sub_ar_tp, tf_partition_date) values
  ('21001', 'T24-DEP-LD', null, '2026-09-29'),  -- L11 tiền gửi - hợp đồng bị loại khỏi L1 khoản vay
  ('21002', 'T24-DEP-LD', null, '2026-09-29'),  -- tiền gửi LD - không hợp đồng nào dùng
  ('21010', 'T24-DEP-LD', null, '2026-09-29'),  -- L12 tiền gửi - hợp đồng bị loại khỏi L1 khoản vay
  ('21050', 'T24-LOAN-LD', null, '2026-09-29'),  -- khoản vay LD - category của phần lớn hợp đồng test
  ('21051', 'T24-LOAN-LD', null, '2026-09-29'),  -- khoản vay LD - không hợp đồng nào dùng
  ('21052', 'T24-LOAN-LD', null, '2026-09-29'),  -- khoản vay LD - không hợp đồng nào dùng
  ('21055', 'T24-LOAN-LD', null, '2026-09-29'),  -- L17 category chỉ có trong file ngày 29
  ('21059', 'T24-LOAN-LD', null, '2026-09-29'),  -- L05 vẫn lên L1 - layer 2 loại giao dịch của category này
  ('21062', 'T24-LOAN-LD', null, '2026-09-29'),  -- L06 khoản vay - dư nợ gốc luôn ra 0
  ('21063', 'T24-LOAN-LD', null, '2026-09-29'),  -- L09 ngày 29 có một dòng - ngày 30 bị lặp
  ('21076', 'T24-DEP-MM', null, '2026-09-29');  -- loại arrangement khác - L1 khoản vay không dùng

-- tf_partition_date = 2026-09-30: 12 dòng
insert into dwh_ref.csv_ma_map_cgy_ar_tp__mnp (category, ar_tp, sub_ar_tp, tf_partition_date) values
  ('21001', 'T24-DEP-LD', null, '2026-09-30'),  -- L11 tiền gửi - hợp đồng bị loại khỏi L1 khoản vay
  ('21002', 'T24-DEP-LD', null, '2026-09-30'),  -- tiền gửi LD - không hợp đồng nào dùng
  ('21010', 'T24-DEP-LD', null, '2026-09-30'),  -- ngày 30 không hợp đồng nào dùng (L12 không còn trong LD)
  ('21050', 'T24-LOAN-LD', null, '2026-09-30'),  -- khoản vay LD - category của phần lớn hợp đồng test
  ('21051', 'T24-LOAN-LD', null, '2026-09-30'),  -- khoản vay LD - không hợp đồng nào dùng
  ('21052', 'T24-LOAN-LD', null, '2026-09-30'),  -- khoản vay LD - không hợp đồng nào dùng
  ('21059', 'T24-LOAN-LD', null, '2026-09-30'),  -- L05 vẫn lên L1 - layer 2 loại giao dịch của category này
  ('21062', 'T24-LOAN-LD', null, '2026-09-30'),  -- L06 khoản vay - dư nợ gốc luôn ra 0
  ('21063', 'T24-LOAN-LD', null, '2026-09-30'),  -- L09 dòng thứ nhất của category 21063
  ('21063', 'T24-LOAN-LD', null, '2026-09-30'),  -- L09 dòng lặp - không được làm nhân đôi hợp đồng
  ('21065', 'T24-LOAN-LD', null, '2026-09-30'),  -- L22 category mới có trong file từ ngày 30
  ('21076', 'T24-DEP-MM', null, '2026-09-30');  -- loại arrangement khác - L1 khoản vay không dùng

-- ---------------------------------------------------------------------------
-- dwh_ref.tfm_re_crf_sbv__mnp: 40 dòng (ngày 2026-09-29: 20 dòng; ngày 2026-09-30: 20 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_ref.tfm_re_crf_sbv__mnp;

-- tf_partition_date = 2026-09-29: 20 dòng
insert into dwh_ref.tfm_re_crf_sbv__mnp (ctr_no, mud_code, desc_3, deal_bal_lcy, tf_partition_date) values
  ('LD2407500001', 'LD', 'SBV.2111', '-514000000', '2026-09-29'),  -- L01 dư nợ 514 triệu
  ('LD2516600002', 'LD', 'SBV.2141', '-3775003125', '2026-09-29'),  -- L02 khoản vay USD - số dư đã quy đổi nội tệ
  ('LD2524400003', 'LD', 'SBV.2111', '-250000000', '2026-09-29'),  -- L03 dư nợ 250 triệu - không đổi giữa hai ngày
  ('LD2601000004', 'LD', 'SBV.2111', '-80000000', '2026-09-29'),  -- L04 dư nợ 80 triệu
  ('LD2605100005', 'LD', 'SBV.2111', '-83000000', '2026-09-29'),  -- L05 dư nợ 83 triệu
  ('LD2533500006', 'LD', 'SBV.2111', '-100000000', '2026-09-29'),  -- L06 dư nợ 100 triệu - không đổi giữa hai ngày
  ('PDLD2324300007', 'PD', 'SBV.2112', '-450000000', '2026-09-29'),  -- L07 chỉ có dòng nợ quá hạn - tính về LD2324300007
  ('LD2612500008', 'LD', 'SBV.2111', '-305000000', '2026-09-29'),  -- L08 dư nợ 305 triệu
  ('LD2531500009', 'LD', 'SBV.2111', '-45000000', '2026-09-29'),  -- L09 dư nợ 45 triệu - không đổi giữa hai ngày
  ('LD2428400010', 'LD', 'SBV.2111', '-300000000', '2026-09-29'),  -- L10 dòng nợ trong hạn
  ('PDLD2428400010', 'PD', 'SBV.2112', '-200000000', '2026-09-29'),  -- L10 dòng nợ quá hạn - cộng về LD2428400010
  ('LD2618200011', 'LD', 'SBV.4232', '200000000', '2026-09-29'),  -- L11 tiền gửi có số dư GL - bị loại vì category
  ('LD2622700012', 'LD', 'SBV.4232', '1250000000', '2026-09-29'),  -- L12 tiền gửi có số dư GL - bị loại vì category
  ('LD2508900013', 'LD', 'SBV.2111', '-20000000', '2026-09-29'),  -- L13 còn số dư ngày 29 - ngày 30 không còn dòng GL
  ('LD2510000014', 'LD', 'SBV.2111', '-150000000', '2026-09-29'),  -- L14 ngày 29 chỉ có một dòng nên còn số dư
  ('LD2514000015', 'AC', 'SBV.2111', '-80000000', '2026-09-29'),  -- L15 chỉ có dòng phân hệ AC nên không được tính
  ('LD2624400016', 'LD', 'SBV.2111', '-60000000', '2026-09-29'),  -- L16 dư nợ 60 triệu
  ('LD2606200017', 'LD', 'SBV.2111', '-70000000', '2026-09-29'),  -- L17 dư nợ 70 triệu
  ('LD2609400018', 'LD', 'SBV.2111', '-90000000', '2026-09-29'),  -- L18 có số dư ngày 29 - ngày 30 không có dòng GL
  ('LD2619600022', 'LD', 'SBV.2111', '-120000000', '2026-09-29');  -- L22 có số dư nhưng category chưa có trong file map

-- tf_partition_date = 2026-09-30: 20 dòng
insert into dwh_ref.tfm_re_crf_sbv__mnp (ctr_no, mud_code, desc_3, deal_bal_lcy, tf_partition_date) values
  ('LD2407500001', 'LD', 'SBV.2111', '-500000000', '2026-09-30'),  -- L01 dư nợ còn 500 triệu sau khi trả 14 triệu gốc
  ('LD2516600002', 'LD', 'SBV.2141', '-3750003125', '2026-09-30'),  -- L02 khoản vay USD - số dư đã quy đổi nội tệ
  ('LD2524400003', 'LD', 'SBV.2111', '-250000000', '2026-09-30'),  -- L03 dư nợ 250 triệu - không đổi giữa hai ngày
  ('LD2601000004', 'LD', 'SBV.2111', '-75000000', '2026-09-30'),  -- L04 dư nợ còn 75 triệu sau khi trả 5 triệu gốc
  ('LD2605100005', 'LD', 'SBV.2111', '-80000000', '2026-09-30'),  -- L05 dư nợ còn 80 triệu sau khi trả 3 triệu gốc
  ('LD2533500006', 'LD', 'SBV.2111', '-100000000', '2026-09-30'),  -- L06 dư nợ 100 triệu - không đổi giữa hai ngày
  ('PDLD2324300007', 'PD', 'SBV.2112', '-400000000', '2026-09-30'),  -- L07 chỉ có dòng nợ quá hạn - tính về LD2324300007
  ('LD2612500008', 'LD', 'SBV.2111', '-300000000', '2026-09-30'),  -- L08 dư nợ còn 300 triệu sau khi trả 5 triệu gốc
  ('LD2531500009', 'LD', 'SBV.2111', '-45000000', '2026-09-30'),  -- L09 dư nợ 45 triệu - không đổi giữa hai ngày
  ('LD2428400010', 'LD', 'SBV.2111', '-300000000', '2026-09-30'),  -- L10 dòng nợ trong hạn
  ('PDLD2428400010', 'PD', 'SBV.2112', '-200000000', '2026-09-30'),  -- L10 dòng nợ quá hạn - cộng về LD2428400010
  ('LD2428400010', 'LD', 'SBV.9995', '500000000', '2026-09-30'),  -- L10 tài khoản SBV.9995 không được tính
  ('LD2618200011', 'LD', 'SBV.4232', '200000000', '2026-09-30'),  -- L11 tiền gửi có số dư GL - bị loại vì category
  ('LD2510000014', 'LD', 'SBV.2111', '-150000000', '2026-09-30'),  -- L14 hai dòng bù nhau - tổng số dư bằng 0
  ('LD2510000014', 'LD', 'SBV.2111', '150000000', '2026-09-30'),  -- L14 hai dòng bù nhau - tổng số dư bằng 0
  ('LD2514000015', 'LD', 'SBV.9996', '-80000000', '2026-09-30'),  -- L15 chỉ có dòng SBV.9996 nên không được tính
  ('LD2624400016', 'LD', 'SBV.2111', '-60000000', '2026-09-30'),  -- L16 GL còn số dư nhưng LD ngày 30 không có hợp đồng
  ('LD2606200017', 'LD', 'SBV.2111', '-70000000', '2026-09-30'),  -- L17 có số dư nhưng category đã bị rút khỏi file map
  ('LD2627300021', 'LD', 'SBV.2111', '-200000000', '2026-09-30'),  -- L21 hợp đồng mới mở ngày 30
  ('LD2619600022', 'LD', 'SBV.2111', '-120000000', '2026-09-30');  -- L22 category đã có trong file map nên lên L1

-- ---------------------------------------------------------------------------
-- raw_eod.t24_ld_loans_and_depo__mnp: 37 dòng (ngày 2026-09-29: 19 dòng; ngày 2026-09-30: 18 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.t24_ld_loans_and_depo__mnp;

-- tf_partition_date = 2026-09-29: 19 dòng
insert into raw_eod.t24_ld_loans_and_depo__mnp (contract_no_, category, customer_id, currency, co_code, status, value_date, fin_mat_date, term, int_rate_type, int_ref_type, interest_spread, rate_change_fre, int_paymt_method, prin_liq_acct, int_liq_acct, no_ovd_days, overdue_status, tf_partition_date) values
  ('LD2407500001', '21050', '9000001', 'VND', 'VN0010102', 'CUR', '20240315', '20270315', '36M', '1', null, null, null, '1', '1300000100', '1300000100', '0', 'CUR', '2026-09-29'),  -- L01 lãi suất cố định - ngày 29 còn dùng tài khoản trả nợ cũ
  ('LD2516600002', '21050', '9000002', 'USD', 'VN0010102', 'CUR', '20250615', '20280229', '989D', '2', 'Lai suat tha noi', '2.5', '03m', '1', '1300000202', '1300000203', '0', 'CUR', '2026-09-29'),  -- L02 loại 2 có biên độ - USD - 03m - đáo hạn 29/02/2028
  ('LD2524400003', '21050', '9000003', 'VND', 'VN0010204', 'CUR', '20250901', '20270229', '18M', '1', 'Lai suat tha noi', '1.5', '0M', '1', '1300000301', '1300000301', '0', null, '2026-09-29'),  -- L03 loại 1 tham chiếu thả nổi - 0M - đáo hạn 29/02/2027
  ('LD2601000004', '21050', '9000004', 'VND', 'VN0010204', 'CUR', '20260110', null, null, null, null, null, null, null, null, '1300000402', null, null, '2026-09-29'),  -- L04 trống loại lãi suất, kỳ hạn, ngày đáo hạn, tài khoản gốc
  ('LD2605100005', '21059', '9000005', 'VND', 'VN0010102', 'CUR', '20260220', '20280230', '24M', '1', 'Lai suat co dinh', null, '12M', '1', '1300000501', '1300000501', '0', 'CUR', '2026-09-29'),  -- L05 category 21059 - đáo hạn 30/02
  ('LD2533500006', '21062', '9000006', 'VND', 'VN0010204', 'CUR', '20251201', '20270431', '17M', '1', null, null, '06M', '2', '1300000601', '1300000601', '0', 'CUR', '2026-09-29'),  -- L06 category 21062 - tần suất 06M - đáo hạn 31/04
  ('LD2324300007', '21050', '9000001', 'VND', 'VN0010102', 'CUR', '20230831', '20260831', '36M', '2', 'Lai suat tha noi', '3', '01M', '1', '1300000101', '1300000101', '29', 'PDO', '2026-09-29'),  -- L07 chỉ còn nợ quá hạn - quá hạn 29 ngày
  ('LD2612500008', '21050', '9000007', 'VND', 'VN0010204', 'CUR', '20260505', '20290505', '36M', '1', null, null, null, '1', '1300000701', '1300000701', '0', 'CUR', '2026-09-29'),  -- L08 ngày 29 còn đủ dòng chi tiết (1,1)
  ('LD2531500009', '21063', '9000008', 'VND', 'VN0010102', 'CUR', '20251111', '20271301', '24M', '2', null, null, '03M', '2', '1300000801', '1300000802', '0', 'CUR', '2026-09-29'),  -- L09 category 21063 - loại 2 không biên độ - đáo hạn tháng 13
  ('LD2428400010', '21050', '9000009', 'VND', 'VN0010204', 'CUR', '20241010', '21000229', '60M', '1', null, null, null, '1', '1300000901', '1300000901', '4', 'PDO', '2026-09-29'),  -- L10 quá hạn 4 ngày - đáo hạn 29/02/2100
  ('LD2618200011', '21001', '9000010', 'VND', 'VN0010102', 'CUR', '20260701', '20270701', '12M', '1', null, null, null, '2', '1300001001', '1300001001', null, null, '2026-09-29'),  -- L11 tiền gửi (category 21001 xếp loại T24-DEP-LD)
  ('LD2622700012', '21010', '9000002', 'USD', 'VN0010204', 'CUR', '20260815', '20260929', '45D', '1', null, null, null, '2', '1300000204', '1300000204', null, null, '2026-09-29'),  -- L12 tiền gửi USD đáo hạn ngày 29 - ngày 30 không còn ở LD
  ('LD2508900013', '21050', '9000011', 'VND', 'VN0010102', 'CUR', '20250330', '20260930', '18M', '1', null, null, null, '1', '1300001101', '1300001101', '0', 'CUR', '2026-09-29'),  -- L13 ngày 29 còn dư nợ - tất toán ngày 30
  ('LD2510000014', '21050', '9000012', 'VND', 'VN0010204', 'CUR', '20250410', '20270410', '24M', '1', null, null, null, '1', '1300001201', '1300001201', '0', 'CUR', '2026-09-29'),  -- L14 ngày 29 còn số dư GL - ngày 30 số dư bù nhau về 0
  ('LD2514000015', '21050', '9000003', 'VND', 'VN0010102', 'CUR', '20250520', '20270520', '24M', '1', null, null, null, '1', '1300000301', '1300000301', '0', 'CUR', '2026-09-29'),  -- L15 GL ngày 29 chỉ có dòng phân hệ AC
  ('LD2624400016', '21050', '9000004', 'VND', 'VN0010204', 'CUR', '20260901', '20270901', '12M', '1', null, null, null, '1', '1300000402', '1300000402', '0', 'CUR', '2026-09-29'),  -- L16 có ở LD ngày 29 - ngày 30 không còn trong LD
  ('LD2606200017', '21055', '9000005', 'VND', 'VN0010102', 'CUR', '20260303', '20270303', '12M', '1', null, null, null, '1', '1300000501', '1300000501', '0', 'CUR', '2026-09-29'),  -- L17 category 21055 chỉ có trong file map ngày 29
  ('LD2609400018', '21050', '9000006', 'VND', 'VN0010204', 'CUR', '20260404', '20270404', '12M', '1', null, null, null, '1', '1300000601', '1300000601', '0', 'CUR', '2026-09-29'),  -- L18 ngày 29 có số dư GL - ngày 30 GL không có dòng
  ('LD2619600022', '21065', '9000014', 'VND', 'VN0010204', 'CUR', '20260715', '20280715', '24M', '2', 'Lai suat tha noi', '1.75', '06M', '1', '1300001401', '1300001402', '0', 'CUR', '2026-09-29');  -- L22 category 21065 chưa có trong file map ngày 29

-- tf_partition_date = 2026-09-30: 18 dòng
insert into raw_eod.t24_ld_loans_and_depo__mnp (contract_no_, category, customer_id, currency, co_code, status, value_date, fin_mat_date, term, int_rate_type, int_ref_type, interest_spread, rate_change_fre, int_paymt_method, prin_liq_acct, int_liq_acct, no_ovd_days, overdue_status, tf_partition_date) values
  ('LD2407500001', '21050', '9000001', 'VND', 'VN0010102', 'CUR', '20240315', '20270315', '36M', '1', null, null, null, '1', '1300000101', '1300000101', '0', 'CUR', '2026-09-30'),  -- L01 lãi suất cố định - từ ngày 30 đổi tài khoản trả nợ
  ('LD2516600002', '21050', '9000002', 'USD', 'VN0010102', 'CUR', '20250615', '20280229', '989D', '2', 'Lai suat tha noi', '2.5', '03m', '1', '1300000202', '1300000203', '0', 'CUR', '2026-09-30'),  -- L02 loại 2 có biên độ - USD - 03m - đáo hạn 29/02/2028
  ('LD2524400003', '21050', '9000003', 'VND', 'VN0010204', 'CUR', '20250901', '20270229', '18M', '1', 'Lai suat tha noi', '1.5', '0M', '1', '1300000301', '1300000301', '0', null, '2026-09-30'),  -- L03 loại 1 tham chiếu thả nổi - 0M - đáo hạn 29/02/2027
  ('LD2601000004', '21050', '9000004', 'VND', 'VN0010204', 'CUR', '20260110', null, null, null, null, null, null, null, null, '1300000402', null, null, '2026-09-30'),  -- L04 trống loại lãi suất, kỳ hạn, ngày đáo hạn, tài khoản gốc
  ('LD2605100005', '21059', '9000005', 'VND', 'VN0010102', 'CUR', '20260220', '20280230', '24M', '1', 'Lai suat co dinh', null, '12M', '1', '1300000501', '1300000501', '0', 'CUR', '2026-09-30'),  -- L05 category 21059 - đáo hạn 30/02
  ('LD2533500006', '21062', '9000006', 'VND', 'VN0010204', 'CUR', '20251201', '20270431', '17M', '1', null, null, '06M', '2', '1300000601', '1300000601', '0', 'CUR', '2026-09-30'),  -- L06 category 21062 - tần suất 06M - đáo hạn 31/04
  ('LD2324300007', '21050', '9000001', 'VND', 'VN0010102', 'CUR', '20230831', '20260831', '36M', '2', 'Lai suat tha noi', '3', '01M', '1', '1300000101', '1300000101', '30', 'PDO', '2026-09-30'),  -- L07 chỉ còn nợ quá hạn - quá hạn 30 ngày
  ('LD2612500008', '21050', '9000007', 'VND', 'VN0010204', 'CUR', '20260505', '20290505', '36M', '1', null, null, null, '1', '1300000701', '1300000701', '0', 'CUR', '2026-09-30'),  -- L08 ngày 30 thiếu dòng chi tiết (1,1)
  ('LD2531500009', '21063', '9000008', 'VND', 'VN0010102', 'CUR', '20251111', '20271301', '24M', '2', null, null, '03M', '2', '1300000801', '1300000802', '0', 'CUR', '2026-09-30'),  -- L09 category 21063 - loại 2 không biên độ - đáo hạn tháng 13
  ('LD2428400010', '21050', '9000009', 'VND', 'VN0010204', 'CUR', '20241010', '21000229', '60M', '1', null, null, null, '1', '1300000901', '1300000901', '5', 'PDO', '2026-09-30'),  -- L10 quá hạn 5 ngày - đáo hạn 29/02/2100
  ('LD2618200011', '21001', '9000010', 'VND', 'VN0010102', 'CUR', '20260701', '20270701', '12M', '1', null, null, null, '2', '1300001001', '1300001001', null, null, '2026-09-30'),  -- L11 tiền gửi (category 21001 xếp loại T24-DEP-LD)
  ('LD2508900013', '21050', '9000011', 'VND', 'VN0010102', 'LIQ', '20250330', '20260930', '18M', '1', null, null, null, '1', '1300001101', '1300001101', '0', null, '2026-09-30'),  -- L13 tất toán ngày 30 - GL không còn số dư
  ('LD2510000014', '21050', '9000012', 'VND', 'VN0010204', 'CUR', '20250410', '20270410', '24M', '1', null, null, null, '1', '1300001201', '1300001201', '0', 'CUR', '2026-09-30'),  -- L14 số dư GL ngày 30 bù nhau về 0
  ('LD2514000015', '21050', '9000003', 'VND', 'VN0010102', 'CUR', '20250520', '20270520', '24M', '1', null, null, null, '1', '1300000301', '1300000301', '0', 'CUR', '2026-09-30'),  -- L15 GL ngày 30 chỉ có dòng SBV.9996
  ('LD2606200017', '21055', '9000005', 'VND', 'VN0010102', 'CUR', '20260303', '20270303', '12M', '1', null, null, null, '1', '1300000501', '1300000501', '0', 'CUR', '2026-09-30'),  -- L17 category 21055 bị rút khỏi file map ngày 30
  ('LD2609400018', '21050', '9000006', 'VND', 'VN0010204', 'CUR', '20260404', '20270404', '12M', '1', null, null, null, '1', '1300000601', '1300000601', '0', 'CUR', '2026-09-30'),  -- L18 GL ngày 30 không có dòng của hợp đồng
  ('LD2627300021', '21050', '9000013', 'VND', 'VN0010102', 'CUR', '20260930', '20270930', '12M', '1', null, null, null, '1', '1300001301', '1300001301', '0', 'CUR', '2026-09-30'),  -- L21 hợp đồng mới mở ngày 30
  ('LD2619600022', '21065', '9000014', 'VND', 'VN0010204', 'CUR', '20260715', '20280715', '24M', '2', 'Lai suat tha noi', '1.75', '06M', '1', '1300001401', '1300001402', '0', 'CUR', '2026-09-30');  -- L22 category 21065 có trong file map từ ngày 30

-- ---------------------------------------------------------------------------
-- raw_eod.t24_ld_loans_and_depo_details__mnp: 40 dòng (ngày 2026-09-29: 20 dòng; ngày 2026-09-30: 20 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.t24_ld_loans_and_depo_details__mnp;

-- tf_partition_date = 2026-09-29: 20 dòng
insert into raw_eod.t24_ld_loans_and_depo_details__mnp (contract_no_, m, s, amount, interest_rate, tf_partition_date) values
  ('LD2407500001', '1', '1', '514000000', '9.5', '2026-09-29'),  -- L01 dòng (1,1) được dùng - dư nợ 514 triệu
  ('LD2407500001', '2', '1', '123456789', '1.5', '2026-09-29'),  -- L01 dòng (2,1) không được dùng
  ('LD2516600002', '1', '1', '151000.125', '7', '2026-09-29'),  -- L02 lãi suất 7 + biên độ 2.5 - gốc làm tròn 151000.13
  ('LD2524400003', '1', '1', '250000000', '8', '2026-09-29'),  -- L03 lãi suất 8 - không cộng biên độ 1.5
  ('LD2601000004', '1', '1', null, null, '2026-09-29'),  -- L04 số tiền và lãi suất trống
  ('LD2605100005', '1', '1', '83000000', null, '2026-09-29'),  -- L05 lãi suất trống tính là 0
  ('LD2533500006', '1', '1', '100000000', '10.25', '2026-09-29'),  -- L06 category 21062 nên dư nợ gốc ra 0
  ('LD2324300007', '1', '1', '0', '9', '2026-09-29'),  -- L07 gốc trong hạn bằng 0 - lãi suất 9 + biên độ 3
  ('LD2612500008', '1', '1', '305000000', '8.8', '2026-09-29'),  -- L08 ngày 29 có dòng (1,1) nên L1 đủ thuộc tính
  ('LD2531500009', '1', '1', '45000000', '6.5', '2026-09-29'),  -- L09 category 21063 nên dư nợ gốc ra 0
  ('LD2428400010', '1', '1', '300000000', '11', '2026-09-29'),  -- L10 gốc trong hạn 300 triệu
  ('LD2618200011', '1', '1', '200000000', '5.2', '2026-09-29'),  -- L11 tiền gửi 200 triệu
  ('LD2622700012', '1', '1', '50000', '3.1', '2026-09-29'),  -- L12 tiền gửi 50000 USD
  ('LD2508900013', '1', '1', '20000000', '9.9', '2026-09-29'),  -- L13 còn 20 triệu gốc trước khi tất toán
  ('LD2510000014', '1', '1', '150000000', '9', '2026-09-29'),  -- L14 gốc 150 triệu
  ('LD2514000015', '1', '1', '80000000', '9', '2026-09-29'),  -- L15 gốc 80 triệu
  ('LD2624400016', '1', '1', '60000000', '9', '2026-09-29'),  -- L16 gốc 60 triệu
  ('LD2606200017', '1', '1', '70000000', '9', '2026-09-29'),  -- L17 gốc 70 triệu
  ('LD2609400018', '1', '1', '90000000', '9', '2026-09-29'),  -- L18 gốc 90 triệu
  ('LD2619600022', '1', '1', '120000000', '7.25', '2026-09-29');  -- L22 lãi suất 7.25 + biên độ 1.75

-- tf_partition_date = 2026-09-30: 20 dòng
insert into raw_eod.t24_ld_loans_and_depo_details__mnp (contract_no_, m, s, amount, interest_rate, tf_partition_date) values
  ('LD2407500001', '1', '1', '500000000', '9.5', '2026-09-30'),  -- L01 dòng (1,1) được dùng - dư nợ còn 500 triệu
  ('LD2407500001', '2', '1', '123456789', '1.5', '2026-09-30'),  -- L01 dòng (2,1) không được dùng
  ('LD2407500001', '1', '2', '987654321', '2.5', '2026-09-30'),  -- L01 dòng (1,2) không được dùng
  ('LD2516600002', '1', '1', '150000.125', '7.123456', '2026-09-30'),  -- L02 lãi suất điều chỉnh từ 7 lên 7.123456
  ('LD2524400003', '1', '1', '250000000', '8', '2026-09-30'),  -- L03 lãi suất 8 - không cộng biên độ 1.5
  ('LD2601000004', '1', '1', null, null, '2026-09-30'),  -- L04 số tiền và lãi suất trống
  ('LD2605100005', '1', '1', '80000000', null, '2026-09-30'),  -- L05 lãi suất trống tính là 0
  ('LD2533500006', '1', '1', '100000000', '10.25', '2026-09-30'),  -- L06 category 21062 nên dư nợ gốc ra 0
  ('LD2324300007', '1', '1', '0', '9', '2026-09-30'),  -- L07 gốc trong hạn bằng 0 - lãi suất 9 + biên độ 3
  ('LD2612500008', '2', '1', '300000000', '8.8', '2026-09-30'),  -- L08 chỉ có dòng (2,1) - thiếu dòng (1,1)
  ('LD2531500009', '1', '1', '45000000', '6.5', '2026-09-30'),  -- L09 category 21063 nên dư nợ gốc ra 0
  ('LD2428400010', '1', '1', '300000000', '11', '2026-09-30'),  -- L10 gốc trong hạn 300 triệu
  ('LD2618200011', '1', '1', '200000000', '5.2', '2026-09-30'),  -- L11 tiền gửi 200 triệu
  ('LD2508900013', '1', '1', '0', '9.9', '2026-09-30'),  -- L13 gốc về 0 sau khi tất toán
  ('LD2510000014', '1', '1', '150000000', '9', '2026-09-30'),  -- L14 gốc 150 triệu
  ('LD2514000015', '1', '1', '80000000', '9', '2026-09-30'),  -- L15 gốc 80 triệu
  ('LD2606200017', '1', '1', '70000000', '9', '2026-09-30'),  -- L17 gốc 70 triệu
  ('LD2609400018', '1', '1', '90000000', '9', '2026-09-30'),  -- L18 gốc 90 triệu
  ('LD2627300021', '1', '1', '200000000', '10.5', '2026-09-30'),  -- L21 hợp đồng mới - gốc 200 triệu
  ('LD2619600022', '1', '1', '120000000', '7.25', '2026-09-30');  -- L22 lãi suất 7.25 + biên độ 1.75

-- Đưa log về trạng thái chưa chạy: QA chỉ được test sau khi DAG ghi success
delete from dwh_ctrl.log_etl_table where data_date in ('2026-09-29', '2026-09-30') and job_name in ('loan_contract_intf_dag', 'bi_lend_repay_info_intf__fa_dag');
