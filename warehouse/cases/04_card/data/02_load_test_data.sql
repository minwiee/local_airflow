-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 04_card: nạp dữ liệu test cho các bảng nguồn
-- Ngày test: 2026-09-29, 2026-09-30. Dữ liệu sinh từ data/source/*.csv; chú thích cuối dòng là tình huống test của dòng đó.


-- ---------------------------------------------------------------------------
-- dwh_intf.card_intf: 5 dòng (ngày 2026-09-28: 3 dòng; ngày 2026-09-29: 1 dòng; ngày 2026-09-30: 1 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_intf.card_intf;

-- business_date = 2026-09-28: 3 dòng
insert into dwh_intf.card_intf (business_date, ppn_date, card_nbr, contract_nbr, prd_card_code, limit_amt, card_type, status_name, card_status, prim_card_flag, card_open_date, exp_date, src_sys_code, uniq_id_in_src_sys, actual_end_date, src_info) values
  ('2026-09-28', '2026-09-28 23:05:00', '545400******1001', 'HD0002001', '301', '45000000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-03-14', '2028-12-31', 'WAY4_ACNT_CONTRACT', '1001', '2026-10-01', 'T,AL26001001'),  -- C13 dòng 28/09 của thẻ 1001: phải còn nguyên
  ('2026-09-28', '2026-09-28 23:05:00', '545400******1007', 'HD0002001', '301', '10000000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2024-09-15', '2027-09-30', 'WAY4_ACNT_CONTRACT', '1007', '2026-09-30', null),  -- C07 dòng 28/09 của thẻ 1007: ngày 29/09 đọc status_name
  ('2026-09-28', '2026-09-28 23:05:00', '545400******1099', 'HD0002001', '301', '1000000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2025-01-01', '2028-12-31', 'WAY4_ACNT_CONTRACT', '1099', '2028-12-31', null);  -- C13 dòng 28/09 của thẻ không còn ở nguồn: phải còn nguyên

-- business_date = 2026-09-29: 1 dòng
insert into dwh_intf.card_intf (business_date, ppn_date, card_nbr, contract_nbr, prd_card_code, limit_amt, card_type, status_name, card_status, prim_card_flag, card_open_date, exp_date, src_sys_code, uniq_id_in_src_sys, actual_end_date, src_info) values
  ('2026-09-29', '2026-09-29 20:00:00', '545400******1001', 'HD0002001', '301', '1', 'CREDIT-CARD', 'TRANG THAI CU', 'READY', 'YES', '2026-03-14', '2028-12-31', 'WAY4_ACNT_CONTRACT', '1001', '2026-10-01', 'DONG CU CUA LAN CHAY TRUOC');  -- C13 dòng cũ của ngày 29/09: pre_hook xóa trước khi nạp

-- business_date = 2026-09-30: 1 dòng
insert into dwh_intf.card_intf (business_date, ppn_date, card_nbr, contract_nbr, prd_card_code, limit_amt, card_type, status_name, card_status, prim_card_flag, card_open_date, exp_date, src_sys_code, uniq_id_in_src_sys, actual_end_date, src_info) values
  ('2026-09-30', '2026-09-30 20:00:00', '545400******9999', 'HD0002001', '301', '1000000', 'CREDIT-CARD', 'Card OK', 'READY', 'YES', '2026-01-01', '2028-12-31', 'WAY4_ACNT_CONTRACT', '9999', '2028-12-31', 'DONG CU CUA LAN CHAY TRUOC');  -- C13 dòng cũ của ngày 30/09: pre_hook xóa trước khi nạp

-- ---------------------------------------------------------------------------
-- dwh_intf.prd_intf: 20 dòng (ngày 2026-09-29: 10 dòng; ngày 2026-09-30: 10 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_intf.prd_intf;

-- business_date = 2026-09-29: 10 dòng
insert into dwh_intf.prd_intf (business_date, src_sys_code, uniq_id_in_src_sys, prd_name, prd_group_name) values
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '301', 'MC PLATINUM CREDIT PRIN', 'Credit Cards'),  -- C01 tên có CREDIT: 01.Credit Card
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '302', 'MC PLATINUM CREDIT SUPP', 'Credit Cards'),  -- C01 tên có CREDIT: 01.Credit Card
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '303', 'MC2 DEBIT SUPP', 'Issuing'),  -- C02 và C12: tên có DEBIT và MC2
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '304', 'MC2 CREDIT PRIN', 'Issuing'),  -- C02 nhóm Issuing nhưng tên có CREDIT
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '305', 'OUR IMPRINTER DEBIT', 'Debit Cards'),  -- C09 tên có DEBIT: 02.Debit Card
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '306', 'VISA PREPAID VIR', 'Prepaid Cards'),  -- C09 không có CREDIT hay DEBIT: xét đầu số thẻ
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '307', 'JCB CREDIT PRIN', null),  -- C08 không có tên nhóm; tên có CREDIT
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '308', 'Card Relation Product', 'Credit Cards'),  -- Sản phẩm RELATION: không có thẻ nào lên L1
  ('2026-09-29', 'WAY4_APPL_PRODUCT', '310', 'VISA GOLD CREDIT PRIN', 'Debit Cards'),  -- C10 nhóm 44 ngày 29/09 còn tên Debit Cards
  ('2026-09-29', 'OTHER_SOURCE', '301', 'SAN PHAM CUA NGUON KHAC', 'Debit Cards');  -- C13 trùng id 301 nhưng khác nguồn: không được dùng

-- business_date = 2026-09-30: 10 dòng
insert into dwh_intf.prd_intf (business_date, src_sys_code, uniq_id_in_src_sys, prd_name, prd_group_name) values
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '301', 'MC PLATINUM CREDIT PRIN', 'Credit Cards'),  -- C01 tên có CREDIT: 01.Credit Card
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '302', 'MC PLATINUM CREDIT SUPP', 'Credit Cards'),  -- C01 tên có CREDIT: 01.Credit Card
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '303', 'MC2 DEBIT SUPP', 'Issuing'),  -- C02 và C12: tên có DEBIT và MC2
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '304', 'MC2 CREDIT PRIN', 'Issuing'),  -- C02 nhóm Issuing nhưng tên có CREDIT
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '305', 'OUR IMPRINTER DEBIT', 'Debit Cards'),  -- C09 tên có DEBIT: 02.Debit Card
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '306', 'VISA PREPAID VIR', 'Prepaid Cards'),  -- C09 không có CREDIT hay DEBIT: xét đầu số thẻ
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '307', 'JCB CREDIT PRIN', null),  -- C08 không có tên nhóm; tên có CREDIT
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '308', 'Card Relation Product', 'Credit Cards'),  -- Sản phẩm RELATION: không có thẻ nào lên L1
  ('2026-09-30', 'WAY4_APPL_PRODUCT', '310', 'VISA GOLD CREDIT PRIN', 'Credit Cards'),  -- C10 nhóm 44 đổi tên từ 30/09
  ('2026-09-30', 'OTHER_SOURCE', '301', 'SAN PHAM CUA NGUON KHAC', 'Debit Cards');  -- C13 trùng id 301 nhưng khác nguồn: không được dùng

-- ---------------------------------------------------------------------------
-- raw_eod.way4_acnt_contract__mnp: 44 dòng (ngày 2026-09-29: 22 dòng; ngày 2026-09-30: 22 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.way4_acnt_contract__mnp;

-- tf_partition_date = 2026-09-29: 22 dòng
insert into raw_eod.way4_acnt_contract__mnp (id, acnt_contract__oid, con_cat, pcat, amnd_state, base_relation, contract_number_mask, product, contr_status, production_status, auth_limit_amount, card_expire, date_open, date_expire, add_info_04, tf_partition_date) values
  ('2001', null, 'A', 'C', 'A', null, 'HD0002001', null, '59', null, '100000000', null, '2024-01-15', null, null, '2026-09-29'),  -- Hợp đồng thẻ hợp lệ: cha của các thẻ tín dụng
  ('2003', null, 'A', 'C', 'A', null, 'HD0002003', null, '59', null, '50000000', null, '2022-03-01', '2026-09-29', null, '2026-09-29'),  -- C05 hết hiệu lực đúng ngày chạy: vẫn hợp lệ
  ('2005', null, 'A', 'M', 'A', null, 'HD0002005', null, '59', null, '10000000', null, '2024-02-02', null, null, '2026-09-29'),  -- C05 hợp đồng có PCAT = M (khác C)
  ('2006', null, 'A', 'C', 'I', null, 'HD0002006', null, '60', null, '10000000', null, '2024-02-02', null, null, '2026-09-29'),  -- C04 hợp đồng không hiệu lực (AMND_STATE = I)
  ('2007', null, 'A', 'C', 'A', '2001', 'HD0002007', null, '59', null, '10000000', null, '2024-02-02', null, null, '2026-09-29'),  -- C05 hợp đồng có BASE_RELATION
  ('1001', '2001', 'C', 'C', 'A', null, '545400******1001', 'MCPC_PRIN', '51', 'R', '45000000', '2812', '2026-03-14', '2026-10-01', 'T,AL26001001', '2026-09-29'),  -- C01 thẻ chính; hết hiệu lực 01/10 (D+2): quy tắc thường
  ('1002', '2003', 'C', 'C', 'A', null, '545400******1002', 'MCPC_SUPP', '51', 'S', '20000000', '2812', '2026-03-20', '2028-12-31', null, '2026-09-29'),  -- C01 thẻ phụ; hợp đồng 2003 hết hiệu lực đúng D: vẫn lên
  ('1007', '2001', 'C', 'C', 'A', null, '545400******1007', 'MCPC_PRIN', '52', 'C', '10000000', '2709', '2024-09-15', '2026-09-30', null, '2026-09-29'),  -- C07 hết hiệu lực D+1: lấy trạng thái của dòng 28/09
  ('1012', '2001', 'C', 'C', 'A', null, '412345******1012', 'VSGC_PRIN', '51', 'R', '40000000', '2905', '2026-05-05', '2029-05-31', null, '2026-09-29'),  -- C10 nhóm 44 còn tên Debit Cards: DEBIT-CARD
  ('1006', '2001', 'C', 'C', 'I', null, '545400******1006', 'MCPC_PRIN', '52', 'R', '10000000', '2908', '2026-08-31', '2026-10-01', null, '2026-09-29'),  -- C03 AMND_STATE = I: bị loại (ngày 30/09 thành A)
  ('1008', '2001', 'C', 'C', 'A', null, '545400******1008', 'MCPC_PRIN', '51', 'N', '15000000', '2910', '2026-09-30', '2026-10-01', null, '2026-09-29'),  -- C06 mở 30/09 (sau ngày chạy): bị loại
  ('1013', '2001', 'C', 'C', 'A', null, '512345******1013', 'VSSC_PRIN', '51', 'R', '80000000', '2901', '2026-09-29', '2029-01-31', null, '2026-09-29'),  -- C04 sản phẩm 311 chưa hiệu lực: bị loại
  ('1102', '2001', 'C', 'C', 'A', '1001', '545400******1102', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C03 thẻ có BASE_RELATION: bị loại
  ('1103', '2001', 'C', 'C', 'A', null, '700012******1103', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C03 số thẻ đầu 70: bị loại
  ('1104', '2001', 'C', 'C', 'A', null, '600001******1104', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C03 số thẻ đầu 60000: bị loại
  ('1105', '2001', 'C', 'C', 'A', null, '111111******1105', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C03 số thẻ đầu 111111: bị loại
  ('1107', '2999', 'C', 'C', 'A', null, '545400******1107', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C04 hợp đồng cha 2999 không tồn tại: bị loại
  ('1108', '1001', 'C', 'C', 'A', null, '545400******1108', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C04 bản ghi cha (1001) là thẻ: bị loại
  ('1109', '2006', 'C', 'C', 'A', null, '545400******1109', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C04 hợp đồng cha 2006 không hiệu lực: bị loại
  ('1111', '2001', 'C', 'C', 'A', null, '545400******1111', 'RELA_ACC', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C04 tên sản phẩm có RELATION: bị loại
  ('1113', '2005', 'C', 'C', 'A', null, '545400******1113', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29'),  -- C05 hợp đồng cha có PCAT = M: bị loại
  ('1114', '2007', 'C', 'C', 'A', null, '545400******1114', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-29');  -- C05 hợp đồng cha có BASE_RELATION: bị loại

-- tf_partition_date = 2026-09-30: 22 dòng
insert into raw_eod.way4_acnt_contract__mnp (id, acnt_contract__oid, con_cat, pcat, amnd_state, base_relation, contract_number_mask, product, contr_status, production_status, auth_limit_amount, card_expire, date_open, date_expire, add_info_04, tf_partition_date) values
  ('2001', null, 'A', 'C', 'A', null, 'HD0002001', null, '59', null, '100000000', null, '2024-01-15', null, null, '2026-09-30'),  -- Hợp đồng thẻ hợp lệ: cha của các thẻ tín dụng
  ('2002', null, 'A', 'C', 'A', null, 'HD0002002', null, '59', null, '0', null, '2023-05-20', null, null, '2026-09-30'),  -- Hợp đồng thẻ hợp lệ: cha của các thẻ ghi nợ
  ('2003', null, 'A', 'C', 'A', null, 'HD0002003', null, '59', null, '50000000', null, '2022-03-01', '2026-09-29', null, '2026-09-30'),  -- C05 hết hiệu lực 29/09 (trước ngày chạy): thẻ con bị loại
  ('1001', '2001', 'C', 'C', 'A', null, '545400******1001', 'MCPC_PRIN', '52', 'R', '50000000', '2812', '2026-03-14', '2026-10-01', 'T,AL26001001', '2026-09-30'),  -- C07 hết hiệu lực D+1: giữ Card OK của ngày 29/09
  ('1002', '2003', 'C', 'C', 'A', null, '545400******1002', 'MCPC_SUPP', '51', 'S', '20000000', '2812', '2026-03-20', '2028-12-31', null, '2026-09-30'),  -- C05 hợp đồng 2003 đã hết hiệu lực: bị loại
  ('1003', '2002', 'C', 'C', 'A', null, '905555******1003', 'MC2D_SUPP', '51', 'R', '0', '2706', '2025-06-10', '2027-06-30', null, '2026-09-30'),  -- C02 nhóm Issuing: DEBIT-CARD
  ('1004', '2002', 'C', 'C', 'A', null, '905555******1004', 'MC2C_PRIN', '51', 'L', '30000000', '2706', '2025-06-10', '2027-06-30', null, '2026-09-30'),  -- C02 nhóm Issuing nhưng tên sản phẩm có CREDIT
  ('1006', '2001', 'C', 'C', 'A', null, '545400******1006', 'MCPC_PRIN', '52', 'R', '10000000', '2908', '2026-08-31', '2026-10-01', null, '2026-09-30'),  -- C07 hết hiệu lực D+1 nhưng không có dòng 29/09: trống
  ('1007', '2001', 'C', 'C', 'A', null, '545400******1007', 'MCPC_PRIN', '52', 'C', '10000000', '2709', '2024-09-15', '2026-09-30', null, '2026-09-30'),  -- C07 hết hiệu lực đúng ngày chạy: Card Closed
  ('1008', '2001', 'C', 'C', 'A', null, '545400******1008', 'MCPC_PRIN', '51', 'N', '15000000', '2910', '2026-09-30', '2026-10-01', null, '2026-09-30'),  -- C06 mở đúng ngày chạy; C07 D+1 nhưng không mở trước D
  ('1009', '2002', 'C', 'C', 'A', null, '356789******1009', 'JCBC_PRIN', '53', 'X', null, null, '2025-01-05', null, null, '2026-09-30'),  -- C08 thiếu hạn mức và hạn thẻ; mã X; trạng thái 53
  ('1010', '2002', 'C', 'C', 'A', null, '453201******1010', 'PREP_VIR', '51', 'm', '0', '0000', '2025-02-01', null, null, '2026-09-30'),  -- C09 mã m (chữ thường); hạn thẻ 0000; nhóm Prepaid
  ('1011', '2002', 'C', 'C', 'A', null, '621234******1011', 'IMPR_DEB', '51', 'M', '0', '2711', '2025-03-01', '2027-11-30', null, '2026-09-30'),  -- C09 mã M; tên sản phẩm có IMPRINTER; đầu số 62
  ('1012', '2001', 'C', 'C', 'A', null, '412345******1012', 'VSGC_PRIN', '51', 'R', '40000000', '2905', '2026-05-05', '2029-05-31', null, '2026-09-30'),  -- C10 nhóm 44 đổi tên từ 30/09: CREDIT-CARD
  ('1013', '2001', 'C', 'C', 'A', null, '512345******1013', 'VSSC_PRIN', '51', 'R', '80000000', '2901', '2026-09-29', '2029-01-31', null, '2026-09-30'),  -- C11 sản phẩm 311 không có ở prd_intf; đầu số 5
  ('1014', '2001', 'C', 'C', 'A', null, '412345******1014', 'VSSC_PRIN', '51', 'R', '80000000', '2901', '2026-09-30', '2029-01-31', null, '2026-09-30'),  -- C11 sản phẩm 311 không có ở prd_intf; đầu số 4
  ('1015', '2001', 'C', 'C', 'A', null, '545400******1015', 'MCPC_PRIN', '51', 'R', '25000000', '2704', '2014-04-09', '2027-04-30', null, '2026-09-30'),  -- C12 mở 2014-04-09: layer 2 đổi thành 2014-04-10
  ('1016', '2002', 'C', 'C', 'A', null, '905555******1016', 'MC2D_SUPP', '51', 'R', '0', '2712', '2013-12-31', null, '_MOBI_PHONE', '2026-09-30'),  -- C12 MOBIPHONE + MC2 + mở trước 2014: layer 2 loại
  ('1017', '2002', 'C', 'C', 'A', null, '905555******1017', 'MC2D_SUPP', '51', 'R', '0', '2712', '2014-01-01', null, '_MOBI_PHONE', '2026-09-30'),  -- C12 đối chứng: mở đúng 2014-01-01 nên được giữ
  ('1018', '2002', 'C', 'C', 'A', null, '905555******1018', 'MC2D_SUPP', '51', 'R', '0', '2712', '2013-12-31', null, 'MOBI_PHONE', '2026-09-30'),  -- C12 đối chứng: chuỗi không bắt đầu bằng _ nên được giữ
  ('1019', '2001', 'C', 'C', 'A', null, '545400******1019', 'MCPC_SUPP', '51', 'R', '5000000', '2706', '2013-06-15', null, 'MOBIPHONE FYF', '2026-09-30'),  -- C12 đối chứng: sản phẩm không phải MC2 nên được giữ
  ('1106', '2001', 'C', 'C', 'A', null, '999999******1106', 'MCPC_PRIN', '51', 'R', '1000000', '2812', '2025-01-01', '2028-12-31', null, '2026-09-30');  -- C03 số thẻ đầu 999999: bị loại

-- ---------------------------------------------------------------------------
-- raw_eod.way4_appl_pr_group__s2: 11 dòng (bảng không chia theo ngày)
-- ---------------------------------------------------------------------------
truncate table raw_eod.way4_appl_pr_group__s2;
insert into raw_eod.way4_appl_pr_group__s2 (id, name, tf_created_at, tf_updated_at) values
  ('41', 'Credit', '2015-01-01 00:00:00', '2020-01-01 00:00:00'),  -- C13 phiên bản cũ của nhóm 41 (đã đóng năm 2020): không dùng
  ('41', 'Credit Cards', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- Tên có CREDIT: thẻ là CREDIT-CARD
  ('42', 'Debit Cards', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- Tên có DEBIT: thẻ là DEBIT-CARD
  ('43', 'Issuing', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- C02 tên đúng bằng ISSUING: thẻ là DEBIT-CARD
  ('44', 'Debit Cards', '2020-01-01 00:00:00', '2026-09-30 00:00:00'),  -- C10 hiệu lực đến hết 29/09: ngày 29/09 dùng tên này
  ('44', 'Credit Cards', '2026-09-30 00:00:00', '9999-12-31 00:00:00'),  -- C10 hiệu lực từ 30/09: ngày 30/09 dùng tên này
  ('45', 'Prepaid Cards', '2020-01-01 00:00:00', '2026-10-01 00:00:00'),  -- C09 tên không có CREDIT hay DEBIT: card_type trống
  ('45', 'Prepaid Debit Cards', '2026-10-01 00:00:00', '9999-12-31 00:00:00'),  -- C13 phiên bản tương lai (từ 01/10): chưa được dùng
  ('46', 'Corporate Cards', '2021-06-01 00:00:00', '9999-12-31 00:00:00'),  -- Nhóm chưa có sản phẩm nào
  ('47', 'Virtual Cards', '2022-03-01 00:00:00', '9999-12-31 00:00:00'),  -- Nhóm chưa có sản phẩm nào
  ('48', 'Co-brand Cards', '2019-01-01 00:00:00', '2024-07-01 00:00:00');  -- Nhóm đã đóng năm 2024: không còn phiên bản hiệu lực

-- ---------------------------------------------------------------------------
-- raw_eod.way4_appl_product__mnp: 22 dòng (ngày 2026-09-29: 11 dòng; ngày 2026-09-30: 11 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.way4_appl_product__mnp;

-- tf_partition_date = 2026-09-29: 11 dòng
insert into raw_eod.way4_appl_product__mnp (id, internal_code, name, appl_pr_group__id, amnd_state, tf_partition_date) values
  ('300', 'MCPC_PRIN', 'BNK MC PLATINUM CREDIT PRIN OLD', '42', 'I', '2026-09-29'),  -- C13 bản cũ của mã MCPC_PRIN (AMND_STATE = I): không dùng
  ('301', 'MCPC_PRIN', 'BNK MC PLATINUM CREDIT PRIN', '41', 'A', '2026-09-29'),  -- C01 thẻ chính (PRIN) thuộc nhóm Credit Cards
  ('302', 'MCPC_SUPP', 'BNK MC PLATINUM CREDIT SUPP', '41', 'A', '2026-09-29'),  -- C01 thẻ phụ (SUPP) thuộc nhóm Credit Cards
  ('303', 'MC2D_SUPP', 'BNK MC2 DEBIT SUPP', '43', 'A', '2026-09-29'),  -- C02 nhóm Issuing; tên có DEBIT và MC2
  ('304', 'MC2C_PRIN', 'BNK MC2 CREDIT PRIN', '43', 'A', '2026-09-29'),  -- C02 nhóm Issuing nhưng tên có CREDIT
  ('305', 'IMPR_DEB', 'BNK OUR IMPRINTER DEBIT', '42', 'A', '2026-09-29'),  -- C09 tên có IMPRINTER: khớp chuỗi PRIN
  ('306', 'PREP_VIR', 'BNK VISA PREPAID VIR', '45', 'A', '2026-09-29'),  -- C09 nhóm Prepaid; tên không có PRIN hay SUPP
  ('307', 'JCBC_PRIN', 'BNK JCB CREDIT PRIN', null, 'A', '2026-09-29'),  -- C08 sản phẩm không có nhóm
  ('308', 'RELA_ACC', 'BNK Card Relation Product', '41', 'A', '2026-09-29'),  -- C04 tên có RELATION: thẻ dùng sản phẩm này bị loại
  ('310', 'VSGC_PRIN', 'BNK VISA GOLD CREDIT PRIN', '44', 'A', '2026-09-29'),  -- C10 thuộc nhóm 44 (đổi tên từ 30/09)
  ('311', 'VSSC_PRIN', 'BNK VISA SIGNATURE CREDIT PRIN', '41', 'I', '2026-09-29');  -- C04 sản phẩm mới: ngày 29/09 chưa hiệu lực

-- tf_partition_date = 2026-09-30: 11 dòng
insert into raw_eod.way4_appl_product__mnp (id, internal_code, name, appl_pr_group__id, amnd_state, tf_partition_date) values
  ('300', 'MCPC_PRIN', 'BNK MC PLATINUM CREDIT PRIN OLD', '42', 'I', '2026-09-30'),  -- C13 bản cũ của mã MCPC_PRIN (AMND_STATE = I): không dùng
  ('301', 'MCPC_PRIN', 'BNK MC PLATINUM CREDIT PRIN', '41', 'A', '2026-09-30'),  -- C01 thẻ chính (PRIN) thuộc nhóm Credit Cards
  ('302', 'MCPC_SUPP', 'BNK MC PLATINUM CREDIT SUPP', '41', 'A', '2026-09-30'),  -- C01 thẻ phụ (SUPP) thuộc nhóm Credit Cards
  ('303', 'MC2D_SUPP', 'BNK MC2 DEBIT SUPP', '43', 'A', '2026-09-30'),  -- C02 nhóm Issuing; tên có DEBIT và MC2
  ('304', 'MC2C_PRIN', 'BNK MC2 CREDIT PRIN', '43', 'A', '2026-09-30'),  -- C02 nhóm Issuing nhưng tên có CREDIT
  ('305', 'IMPR_DEB', 'BNK OUR IMPRINTER DEBIT', '42', 'A', '2026-09-30'),  -- C09 tên có IMPRINTER: khớp chuỗi PRIN
  ('306', 'PREP_VIR', 'BNK VISA PREPAID VIR', '45', 'A', '2026-09-30'),  -- C09 nhóm Prepaid; tên không có PRIN hay SUPP
  ('307', 'JCBC_PRIN', 'BNK JCB CREDIT PRIN', null, 'A', '2026-09-30'),  -- C08 sản phẩm không có nhóm
  ('308', 'RELA_ACC', 'BNK Card Relation Product', '41', 'A', '2026-09-30'),  -- C04 tên có RELATION: thẻ dùng sản phẩm này bị loại
  ('310', 'VSGC_PRIN', 'BNK VISA GOLD CREDIT PRIN', '44', 'A', '2026-09-30'),  -- C10 thuộc nhóm 44 (đổi tên từ 30/09)
  ('311', 'VSSC_PRIN', 'BNK VISA SIGNATURE CREDIT PRIN', '41', 'A', '2026-09-30');  -- C11 hiệu lực từ 30/09; chưa có ở prd_intf

-- ---------------------------------------------------------------------------
-- raw_eod.way4_contr_status__mnp: 22 dòng (ngày 2026-09-29: 11 dòng; ngày 2026-09-30: 11 dòng)
-- ---------------------------------------------------------------------------
truncate table raw_eod.way4_contr_status__mnp;

-- tf_partition_date = 2026-09-29: 11 dòng
insert into raw_eod.way4_contr_status__mnp (id, name, amnd_state, tf_partition_date) values
  ('51', 'Card OK', 'A', '2026-09-29'),  -- Trạng thái của phần lớn thẻ
  ('52', 'Card Closed', 'A', '2026-09-29'),  -- C07 trạng thái của thẻ đã đóng
  ('52', 'Card Closed (old)', 'I', '2026-09-29'),  -- C13 bản cũ của mã 52 (AMND_STATE = I): không dùng
  ('53', 'Card De-active', 'I', '2026-09-29'),  -- C08 mã 53 chỉ có dòng AMND_STATE = I: tên trạng thái trống
  ('54', 'Card Lost', 'A', '2026-09-29'),  -- Chưa có thẻ nào dùng
  ('55', 'Card Stolen', 'A', '2026-09-29'),  -- Chưa có thẻ nào dùng
  ('56', 'PIN Blocked', 'A', '2026-09-29'),  -- Chưa có thẻ nào dùng
  ('57', 'Card Expired', 'A', '2026-09-29'),  -- Chưa có thẻ nào dùng
  ('58', 'Card Do not honor', 'A', '2026-09-29'),  -- Chưa có thẻ nào dùng
  ('59', 'Account OK', 'A', '2026-09-29'),  -- Trạng thái của hợp đồng thẻ (interface không dùng)
  ('60', 'Account Closed', 'A', '2026-09-29');  -- Trạng thái của hợp đồng thẻ (interface không dùng)

-- tf_partition_date = 2026-09-30: 11 dòng
insert into raw_eod.way4_contr_status__mnp (id, name, amnd_state, tf_partition_date) values
  ('51', 'Card OK', 'A', '2026-09-30'),  -- Trạng thái của phần lớn thẻ
  ('52', 'Card Closed', 'A', '2026-09-30'),  -- C07 trạng thái của thẻ đã đóng
  ('52', 'Card Closed (old)', 'I', '2026-09-30'),  -- C13 bản cũ của mã 52 (AMND_STATE = I): không dùng
  ('53', 'Card De-active', 'I', '2026-09-30'),  -- C08 mã 53 chỉ có dòng AMND_STATE = I: tên trạng thái trống
  ('54', 'Card Lost', 'A', '2026-09-30'),  -- Chưa có thẻ nào dùng
  ('55', 'Card Stolen', 'A', '2026-09-30'),  -- Chưa có thẻ nào dùng
  ('56', 'PIN Blocked', 'A', '2026-09-30'),  -- Chưa có thẻ nào dùng
  ('57', 'Card Expired', 'A', '2026-09-30'),  -- Chưa có thẻ nào dùng
  ('58', 'Card Do not honor', 'A', '2026-09-30'),  -- Chưa có thẻ nào dùng
  ('59', 'Account OK', 'A', '2026-09-30'),  -- Trạng thái của hợp đồng thẻ (interface không dùng)
  ('60', 'Account Closed', 'A', '2026-09-30');  -- Trạng thái của hợp đồng thẻ (interface không dùng)

-- Đưa log về trạng thái chưa chạy: QA chỉ được test sau khi DAG ghi success
delete from dwh_ctrl.log_etl_table where data_date in ('2026-09-29', '2026-09-30') and job_name in ('card_intf_dag', 'bi_card_info_intf__mnp_dag');
