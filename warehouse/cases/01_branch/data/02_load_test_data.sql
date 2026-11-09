-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 01_branch: nạp dữ liệu test cho các bảng nguồn
-- Ngày test: 2026-09-29, 2026-09-30. Dữ liệu sinh từ data/source/*.csv; chú thích cuối dòng là tình huống test của dòng đó.


-- ---------------------------------------------------------------------------
-- bi_ref.csv_ma_rbd_branch_area__mnp: 21 dòng (ngày 2026-09-29: 11 dòng; ngày 2026-09-30: 10 dòng)
-- ---------------------------------------------------------------------------
truncate table bi_ref.csv_ma_rbd_branch_area__mnp;

-- tf_partition_date = 2026-09-29: 11 dòng
insert into bi_ref.csv_ma_rbd_branch_area__mnp (branch_id, area_code, area_name, branch_type, hub_af, tf_partition_date) values
  ('VN0010102', 'A01', 'Khu vực Hà Nội 1', 'HUB', 'Y', '2026-09-29'),  -- B11
  ('VN0010103', 'A01', 'Khu vực Hà Nội 1', 'SPOKE', 'N', '2026-09-29'),  -- B03 ngày 29 còn có trong file
  ('VN0010608', 'A02', 'Khu vực Hà Nội 2', 'SPOKE', 'N', '2026-09-29'),  -- B08
  ('VN0010406', 'A03', 'Khu vực Đông Bắc Bộ', 'SPOKE', 'N', '2026-09-29'),  -- B06
  ('VN0010911', 'A03', 'Khu vực Đông Bắc Bộ', 'HUB', 'N', '2026-09-29'),  -- B13
  ('VN0011111', 'A04', 'Khu vực Thanh Nghệ Tĩnh', 'HUB', 'N', '2026-09-29'),  -- chi nhánh không có trong nguồn T24
  ('VN0010305', 'A05', 'Khu vực Đà Nẵng', 'HUB', 'Y', '2026-09-29'),  -- B05
  ('VN0010709', 'A05', 'Khu vực Đà Nẵng', 'SPOKE', 'N', '2026-09-29'),  -- B09
  ('VN0010204', 'A07', 'Khu vực Hồ Chí Minh 2', 'SPOKE', 'N', '2026-09-29'),  -- B04
  ('VN0012222', 'A08', 'Khu vực Đông Nam Bộ', 'SPOKE', 'N', '2026-09-29'),  -- chi nhánh không có trong nguồn T24
  ('VN0010810', 'A09', 'Khu vực Tây Nam Bộ', 'HUB', 'Y', '2026-09-29');  -- B10

-- tf_partition_date = 2026-09-30: 10 dòng
insert into bi_ref.csv_ma_rbd_branch_area__mnp (branch_id, area_code, area_name, branch_type, hub_af, tf_partition_date) values
  ('VN0010102', 'A01', 'Khu vực Hà Nội 1', 'HUB', 'Y', '2026-09-30'),  -- B02
  ('VN0010608', 'A02', 'Khu vực Hà Nội 2', 'SPOKE', 'N', '2026-09-30'),  -- B08 đơn vị không lên interface ngày 30
  ('VN0010406', 'A03', 'Khu vực Đông Bắc Bộ', 'SPOKE', 'N', '2026-09-30'),  -- B06
  ('VN0011111', 'A04', 'Khu vực Thanh Nghệ Tĩnh', 'HUB', 'N', '2026-09-30'),  -- chi nhánh không có trong nguồn T24
  ('VN0010305', 'A05', 'Khu vực Đà Nẵng', 'HUB', 'Y', '2026-09-30'),  -- B05
  ('VN0010709', 'A05', 'Khu vực Đà Nẵng', 'SPOKE', 'N', '2026-09-30'),  -- B09 đơn vị không lên interface ngày 30
  ('VN0013333', 'A06', 'Khu vực Tây Nguyên', 'SPOKE', 'N', '2026-09-30'),  -- chi nhánh không có trong nguồn T24
  ('VN0010204', 'A07', 'Khu vực Hồ Chí Minh 2', 'SPOKE', 'N', '2026-09-30'),  -- B04
  ('VN0012222', 'A08', 'Khu vực Đông Nam Bộ', 'SPOKE', 'N', '2026-09-30'),  -- chi nhánh không có trong nguồn T24
  ('VN0010810', 'A09', 'Khu vực Tây Nam Bộ', 'HUB', 'Y', '2026-09-30');  -- B10

-- ---------------------------------------------------------------------------
-- dwh_intf.branch_intf: 5 dòng (ngày 2026-09-28: 1 dòng; ngày 2026-09-29: 2 dòng; ngày 2026-09-30: 2 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_intf.branch_intf;

-- business_date = 2026-09-28: 1 dòng
insert into dwh_intf.branch_intf (business_date, ppn_date, branch_code, src_sys_code, value_date, actual_end_date, branch_name, division, main_branch_code, book_code, main_book_code, retail_region_code, retail_region_name, branch_status, geo_zone, branch_type, provin_code, provin_name) values
  ('2026-09-28', '2026-09-28 23:05:00', 'VN0010102', 'T24_BANK_COMPANY', '2012-03-15', null, 'CHI NHANH HA NOI', 'RB', 'VN0010102', 'HAN', 'HAN', 'R3', 'VUNG 3', 'ACTIVE', 'MB', 'CHI NHANH', '01', 'TP HA NOI');  -- B12 ngày 28 không chạy lại - phải còn nguyên

-- business_date = 2026-09-29: 2 dòng
insert into dwh_intf.branch_intf (business_date, ppn_date, branch_code, src_sys_code, value_date, actual_end_date, branch_name, division, main_branch_code, book_code, main_book_code, retail_region_code, retail_region_name, branch_status, geo_zone, branch_type, provin_code, provin_name) values
  ('2026-09-29', '2026-09-29 23:10:00', '0101', 'WAY4_F_I', null, null, 'WAY4 BRANCH 0101', null, null, null, null, null, null, null, null, null, null, null),  -- B12 dòng của nguồn Way4 - lần chạy T24 không được xóa
  ('2026-09-29', '2026-09-29 22:00:00', 'VN0019998', 'T24_BANK_COMPANY', '2020-01-01', null, 'DONG CU CUA LAN CHAY TRUOC', 'RB', 'VN0019998', 'OLD', 'OLD', 'R1', 'VUNG 1', 'ACTIVE', 'MB', 'CHI NHANH', '01', 'TP HA NOI');  -- B12 dòng T24 cũ của ngày 29 - bị pre_hook xóa

-- business_date = 2026-09-30: 2 dòng
insert into dwh_intf.branch_intf (business_date, ppn_date, branch_code, src_sys_code, value_date, actual_end_date, branch_name, division, main_branch_code, book_code, main_book_code, retail_region_code, retail_region_name, branch_status, geo_zone, branch_type, provin_code, provin_name) values
  ('2026-09-30', '2026-09-30 23:10:00', '0101', 'WAY4_F_I', null, null, 'WAY4 BRANCH 0101', null, null, null, null, null, null, null, null, null, null, null),  -- B12 dòng của nguồn Way4 - lần chạy T24 không được xóa
  ('2026-09-30', '2026-09-30 22:00:00', 'VN0019998', 'T24_BANK_COMPANY', '2020-01-01', null, 'DONG CU CUA LAN CHAY TRUOC', 'RB', 'VN0019998', 'OLD', 'OLD', 'R1', 'VUNG 1', 'ACTIVE', 'MB', 'CHI NHANH', '01', 'TP HA NOI');  -- B12 dòng T24 cũ của ngày 30 - bị pre_hook xóa

-- ---------------------------------------------------------------------------
-- dwh_ref.csv_cv__mnp: 23 dòng (ngày 2026-09-29: 12 dòng; ngày 2026-09-30: 11 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_ref.csv_cv__mnp;

-- tf_partition_date = 2026-09-29: 12 dòng
insert into dwh_ref.csv_cv__mnp (cl_scm_id, cl_code, cl_nm, tf_partition_date) values
  ('209', 'R1', 'VUNG 1', '2026-09-29'),  -- B01 tên bộ mã trùng tên T24
  ('209', 'R3', 'VUNG 3', '2026-09-29'),  -- B11
  ('209', 'R4', 'VUNG 04', '2026-09-29'),  -- B08 tên bộ mã được ưu tiên hơn tên T24 (VUNG 4)
  ('209', 'R5', 'VUNG 05', '2026-09-29'),  -- B09 tên bộ mã được ưu tiên hơn tên T24 (VUNG 5)
  ('209', 'R6', 'VUNG 6', '2026-09-29'),  -- B13
  ('209', 'R8', 'VUNG 8', '2026-09-29'),  -- không đơn vị nào dùng
  ('209', 'R11', 'VUNG 11', '2026-09-29'),  -- không đơn vị nào dùng
  ('265', 'KV01', 'KHU VUC 1', '2026-09-29'),  -- bộ mã 265 - mã không phải mã vùng
  ('265', 'KV02', 'KHU VUC 2', '2026-09-29'),  -- bộ mã 265 - mã không phải mã vùng
  ('266', 'M01', 'MIEN BAC', '2026-09-29'),  -- bộ mã 266 - mã không phải mã vùng
  ('266', 'M02', 'MIEN NAM', '2026-09-29'),  -- bộ mã 266 - mã không phải mã vùng
  ('100', 'R2', 'SAI BO MA', '2026-09-29');  -- B03 đúng mã vùng nhưng sai bộ mã - không được dùng

-- tf_partition_date = 2026-09-30: 11 dòng
insert into dwh_ref.csv_cv__mnp (cl_scm_id, cl_code, cl_nm, tf_partition_date) values
  ('209', 'R3', 'VUNG 3', '2026-09-30'),  -- ngày 30 không đơn vị nào dùng
  ('209', 'R6', 'VUNG 6', '2026-09-30'),  -- ngày 30 không đơn vị nào dùng
  ('209', 'R7', 'VUNG 7', '2026-09-30'),  -- B05 tên chuẩn của vùng R7
  ('209', 'R8', 'VUNG 8', '2026-09-30'),  -- không đơn vị nào dùng
  ('209', 'R11', 'VUNG 11', '2026-09-30'),  -- không đơn vị nào dùng
  ('265', 'KV01', 'KHU VUC 1', '2026-09-30'),  -- bộ mã 265 - mã không phải mã vùng
  ('265', 'KV02', 'KHU VUC 2', '2026-09-30'),  -- bộ mã 265 - mã không phải mã vùng
  ('266', 'M01', 'MIEN BAC', '2026-09-30'),  -- bộ mã 266 - mã không phải mã vùng
  ('266', 'M02', 'MIEN NAM', '2026-09-30'),  -- bộ mã 266 - mã không phải mã vùng
  ('100', 'R2', 'SAI BO MA', '2026-09-30'),  -- B02 đúng mã vùng nhưng sai bộ mã - không được dùng
  ('100', 'R10', 'SAI BO MA 10', '2026-09-30');  -- B04 đúng mã vùng nhưng sai bộ mã - không được dùng

-- ---------------------------------------------------------------------------
-- dwh_stag_eod.stg_raw_t24_bank_company__mnp: 21 dòng (ngày 2026-09-29: 11 dòng; ngày 2026-09-30: 10 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_stag_eod.stg_raw_t24_bank_company__mnp;

-- tf_partition_date = 2026-09-29: 11 dòng
insert into dwh_stag_eod.stg_raw_t24_bank_company__mnp (id, from_date, to_date, segment, main_branch_code, region_khcn_code, region_khcn_name, region, status, branch_type, code_province, tf_partition_date) values
  ('VN0010001', '2010-01-01', null, 'HO', 'VN0010001', 'R1', 'VUNG 1', 'MB', 'ACTIVE', 'Hoi so', '1', '2026-09-29'),  -- B01 hội sở - dữ liệu đầy đủ
  ('VN0010102', '2012-03-15', null, 'RB', 'VN0010102', 'R3', 'VUNG 3', 'MB', 'ACTIVE', 'Chi nhanh', '1', '2026-09-29'),  -- B11 ngày 29 còn thuộc vùng R3
  ('VN0010103', '2015-06-01', null, 'RB', 'VN0010102', 'R2', 'VUNG 2', 'MB', 'ACTIVE', 'PGD', '1', '2026-09-29'),  -- B03 phòng giao dịch - cấp trên là VN0010102
  ('VN0010204', '2011-09-09', null, 'RB', 'VN0010204', 'R10', 'VUNG 10', 'MN', 'ACTIVE', 'Chi nhanh', '79', '2026-09-29'),  -- B04 mã vùng 3 ký tự
  ('VN0010305', '2014-04-20', null, 'SME', 'VN0010305', 'R7', 'VUNG7', 'MT', 'ACTIVE', 'Chi nhanh', '48', '2026-09-29'),  -- B05 ngày 29 bộ mã chưa có R7
  ('VN0010406', '2016-11-11', '2026-09-30', 'RB', 'VN0019999', 'R12', 'VUNG1', 'MB', 'ACTIVE', 'Chi nhanh', '27', '2026-09-29'),  -- B06 sẽ đóng ngày 30 - cấp trên không tồn tại
  ('VN0010507', '2013-02-02', '2026-08-31', 'RB', 'VN0010507', null, null, 'MB', 'CLOSED', 'Chi nhanh', null, '2026-09-29'),  -- B07 đã đóng từ 31/08 - vùng và tỉnh trống
  ('VN0010608', '2018-08-08', null, 'RB', 'VN0010608', 'R4', 'VUNG 4', 'MB', 'ACTIVE', 'PGD', '1', '2026-09-29'),  -- B08 ngày 29 còn đủ dòng tên
  ('VN0010709', '2019-09-19', null, 'RB', 'VN0010709', 'R5', 'VUNG 5', 'MT', 'ACTIVE', 'PGD', '48', '2026-09-29'),  -- B09 ngày 29 COMPANY còn hiệu lực
  ('VN0010810', '2017-07-07', null, 'RB', 'VN0010810', 'R9', '9', 'MN', 'ACTIVE', 'Chi nhanh', '92', '2026-09-29'),  -- B10 tên vùng thiếu chữ VUNG
  ('VN0010911', '2021-05-05', null, 'RB', 'VN0010911', 'R6', 'VUNG 6', 'MB', 'ACTIVE', 'Chi nhanh', '31', '2026-09-29');  -- B13 chỉ có ở bản chụp ngày 29

-- tf_partition_date = 2026-09-30: 10 dòng
insert into dwh_stag_eod.stg_raw_t24_bank_company__mnp (id, from_date, to_date, segment, main_branch_code, region_khcn_code, region_khcn_name, region, status, branch_type, code_province, tf_partition_date) values
  ('VN0010001', '2010-01-01', null, 'HO', 'VN0010001', 'R1', 'VUNG 1', 'MB', 'ACTIVE', 'Hoi so', '1', '2026-09-30'),  -- B01 hội sở - dữ liệu đầy đủ
  ('VN0010102', '2012-03-15', null, 'RB', 'VN0010102', 'R2', 'VUNG 2', 'MB', 'ACTIVE', 'Chi nhanh', '1', '2026-09-30'),  -- B02 đổi sang vùng R2 - mã R2 chỉ có ở bộ mã 100
  ('VN0010103', '2015-06-01', null, 'RB', 'VN0010102', 'R2', 'VUNG 2', 'MB', 'ACTIVE', 'PGD', '1', '2026-09-30'),  -- B03 phòng giao dịch - tên 2 dòng
  ('VN0010204', '2011-09-09', null, 'RB', 'VN0010204', 'R10', 'VUNG 10', 'MN', 'ACTIVE', 'Chi nhanh', '79', '2026-09-30'),  -- B04 mã vùng 3 ký tự
  ('VN0010305', '2014-04-20', null, 'SME', 'VN0010305', 'R7', 'VUNG7', 'MT', 'ACTIVE', 'Chi nhanh', '48', '2026-09-30'),  -- B05 tên vùng lấy từ bộ mã - tỉnh 48 không có tên
  ('VN0010406', '2016-11-11', '2026-09-30', 'RB', 'VN0019999', 'R12', 'VUNG1', 'MB', 'ACTIVE', 'Chi nhanh', '27', '2026-09-30'),  -- B06 đóng đúng ngày 30 - cấp trên không tồn tại
  ('VN0010507', '2013-02-02', '2026-08-31', 'RB', 'VN0010507', null, null, 'MB', 'CLOSED', 'Chi nhanh', null, '2026-09-30'),  -- B07 đã đóng từ 31/08 - vùng và tỉnh trống
  ('VN0010608', '2018-08-08', null, 'RB', 'VN0010608', 'R4', 'VUNG 4', 'MB', 'ACTIVE', 'PGD', '1', '2026-09-30'),  -- B08 ngày 30 thiếu dòng tên - không lên interface
  ('VN0010709', '2019-09-19', null, 'RB', 'VN0010709', 'R5', 'VUNG 5', 'MT', 'ACTIVE', 'PGD', '48', '2026-09-30'),  -- B09 COMPANY hết hiệu lực đúng ngày 30 - không lên interface
  ('VN0010810', '2017-07-07', null, 'RB', 'VN0010810', 'R9', '9', 'MN', 'ACTIVE', 'Chi nhanh', '92', '2026-09-30');  -- B10 tên vùng thiếu chữ VUNG

-- ---------------------------------------------------------------------------
-- dwh_stag_eod.stg_raw_t24_bank_company_details__mnp: 26 dòng (ngày 2026-09-29: 14 dòng; ngày 2026-09-30: 12 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_stag_eod.stg_raw_t24_bank_company_details__mnp;

-- tf_partition_date = 2026-09-29: 14 dòng
insert into dwh_stag_eod.stg_raw_t24_bank_company_details__mnp (id, m, s, branch_name, tf_partition_date) values
  ('VN0010001', '1', '1', 'HOI SO CHINH', '2026-09-29'),  -- B01
  ('VN0010102', '1', '1', 'CHI NHANH HA NOI', '2026-09-29'),  -- B11
  ('VN0010103', '1', '1', 'TEN CU PGD CAU GIAY', '2026-09-29'),  -- B03 ngày 29 tên cũ chỉ có 1 dòng
  ('VN0010204', '2', '1', 'CN SAI GON', '2026-09-29'),  -- B04 dòng m = 2 nằm trước trong file
  ('VN0010204', '1', '1', 'CHI NHANH HO CHI MINH', '2026-09-29'),  -- B04
  ('VN0010305', '1', '1', 'CHI NHANH DA NANG', '2026-09-29'),  -- B05
  ('VN0010406', '1', '1', 'CHI NHANH BAC NINH', '2026-09-29'),  -- B06
  ('VN0010507', '1', '1', 'CHI NHANH HAI PHONG', '2026-09-29'),  -- B07
  ('VN0010608', '1', '1', 'CHI NHANH HA NOI PGD DONG DA', '2026-09-29'),  -- B08 ngày 29 còn dòng tên
  ('VN0010709', '1', '1', 'PGD HOA KHANH', '2026-09-29'),  -- B09
  ('VN0010810', '1', '1', 'CHI NHANH CAN THO', '2026-09-29'),  -- B10
  ('VN0010911', '2', '1', 'CN LE CHAN', '2026-09-29'),  -- B13 ghép theo m rồi s
  ('VN0010911', '1', '2', 'HAI PHONG', '2026-09-29'),  -- B13
  ('VN0010911', '1', '1', 'CHI NHANH', '2026-09-29');  -- B13

-- tf_partition_date = 2026-09-30: 12 dòng
insert into dwh_stag_eod.stg_raw_t24_bank_company_details__mnp (id, m, s, branch_name, tf_partition_date) values
  ('VN0010001', '1', '1', 'HOI SO CHINH', '2026-09-30'),  -- B01
  ('VN0010102', '1', '1', 'CHI NHANH HA NOI', '2026-09-30'),  -- B02
  ('VN0010103', '1', '2', 'PGD CAU GIAY', '2026-09-30'),  -- B03 dòng s = 2 nằm trước trong file
  ('VN0010103', '1', '1', 'CHI NHANH HA NOI', '2026-09-30'),  -- B03
  ('VN0010204', '2', '1', 'CN SAI GON', '2026-09-30'),  -- B04 dòng m = 2 nằm trước trong file
  ('VN0010204', '1', '1', 'CHI NHANH HO CHI MINH', '2026-09-30'),  -- B04
  ('VN0010305', '1', '1', 'CHI NHANH DA NANG', '2026-09-30'),  -- B05
  ('VN0010406', '1', '1', 'CHI NHANH BAC NINH', '2026-09-30'),  -- B06
  ('VN0010507', '1', '1', 'CHI NHANH HAI PHONG', '2026-09-30'),  -- B07
  ('VN0010608', '2', '1', 'PGD DONG DA', '2026-09-30'),  -- B08 chỉ còn dòng m = 2 - thiếu dòng (1 1)
  ('VN0010709', '1', '1', 'PGD HOA KHANH', '2026-09-30'),  -- B09
  ('VN0010810', '1', '1', 'CHI NHANH CAN THO', '2026-09-30');  -- B10

-- ---------------------------------------------------------------------------
-- dwh_stag_eod.stg_raw_t24_bank_province_details__mnp: 22 dòng (ngày 2026-09-29: 11 dòng; ngày 2026-09-30: 11 dòng)
-- ---------------------------------------------------------------------------
truncate table dwh_stag_eod.stg_raw_t24_bank_province_details__mnp;

-- tf_partition_date = 2026-09-29: 11 dòng
insert into dwh_stag_eod.stg_raw_t24_bank_province_details__mnp (id, province_name, tf_partition_date) values
  ('1', 'TP Ha Noi', '2026-09-29'),  -- mã 1 ký tự - interface ghi 01
  ('4', 'Cao Bang', '2026-09-29'),  -- không đơn vị nào dùng
  ('27', 'Bac Ninh', '2026-09-29'),  -- B06 tên không có chữ TP
  ('31', 'TP Hai Phong', '2026-09-29'),  -- B13
  ('46', 'Thua Thien Hue', '2026-09-29'),  -- không đơn vị nào dùng
  ('48', 'TP Da Nang', '2026-09-29'),  -- B05 ngày 29 còn có tên
  ('56', 'Khanh Hoa', '2026-09-29'),  -- không đơn vị nào dùng
  ('74', 'Binh Duong', '2026-09-29'),  -- không đơn vị nào dùng
  ('75', 'Dong Nai', '2026-09-29'),  -- không đơn vị nào dùng
  ('79', 'TP Ho Chi Minh', '2026-09-29'),  -- B04
  ('92', 'TP Can Tho', '2026-09-29');  -- B10

-- tf_partition_date = 2026-09-30: 11 dòng
insert into dwh_stag_eod.stg_raw_t24_bank_province_details__mnp (id, province_name, tf_partition_date) values
  ('1', 'TP Ha Noi', '2026-09-30'),  -- mã 1 ký tự - interface ghi 01
  ('4', 'Cao Bang', '2026-09-30'),  -- không đơn vị nào dùng
  ('27', 'Bac Ninh', '2026-09-30'),  -- B06 tên không có chữ TP
  ('31', 'TP Hai Phong', '2026-09-30'),  -- không đơn vị nào dùng trong ngày 30
  ('46', 'Thua Thien Hue', '2026-09-30'),  -- không đơn vị nào dùng
  ('48', null, '2026-09-30'),  -- B05 ngày 30 tỉnh 48 không có tên
  ('56', 'Khanh Hoa', '2026-09-30'),  -- không đơn vị nào dùng
  ('74', 'Binh Duong', '2026-09-30'),  -- không đơn vị nào dùng
  ('75', 'Dong Nai', '2026-09-30'),  -- không đơn vị nào dùng
  ('79', 'TP Ho Chi Minh', '2026-09-30'),  -- B04
  ('92', 'TP Can Tho', '2026-09-30');  -- B10

-- ---------------------------------------------------------------------------
-- raw_eod.t24_company__s2: 13 dòng (bảng không chia theo ngày)
-- ---------------------------------------------------------------------------
truncate table raw_eod.t24_company__s2;
insert into raw_eod.t24_company__s2 (company_code, mnemonic, tf_created_at, tf_updated_at) values
  ('VN0010001', 'HSC', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B01
  ('VN0010102', 'HNO', '2020-01-01 00:00:00', '2026-06-01 00:00:00'),  -- B02 phiên bản cũ - hết hiệu lực từ 01/06/2026
  ('VN0010102', 'HAN', '2026-06-01 00:00:00', '9999-12-31 00:00:00'),  -- B02 phiên bản đang hiệu lực
  ('VN0010103', 'CGY', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B03
  ('VN0010204', 'HCM', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B04
  ('VN0010305', 'DNG', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B05
  ('VN0010406', 'BNH', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B06
  ('VN0010507', 'HPG', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B07
  ('VN0010608', 'PG8', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B08
  ('VN0010709', 'HKH', '2020-01-01 00:00:00', '2026-09-30 00:00:00'),  -- B09 hết hiệu lực đúng ngày 30 - ngày 29 còn hiệu lực
  ('VN0010810', 'CTO', '2020-01-01 00:00:00', '9999-12-31 00:00:00'),  -- B10
  ('VN0010911', 'HPO', '2020-01-01 00:00:00', '2026-09-29 00:00:00'),  -- B13 phiên bản cũ - hết hiệu lực đúng ngày 29
  ('VN0010911', 'HPL', '2026-09-29 00:00:00', '9999-12-31 00:00:00');  -- B13 phiên bản mới - hiệu lực từ đúng ngày 29

-- Đưa log về trạng thái chưa chạy: QA chỉ được test sau khi DAG ghi success
delete from dwh_ctrl.log_etl_table where data_date in ('2026-09-29', '2026-09-30') and job_name in ('branch_intf_dag', 'bi_branch_info_intf__mnp_dag');
