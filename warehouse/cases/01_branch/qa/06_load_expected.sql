-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 01_branch: nạp kết quả mong đợi vào schema qa_expected

drop table if exists qa_expected.bi_intf__bi_branch_info_intf__mnp;
create table qa_expected.bi_intf__bi_branch_info_intf__mnp (branch_code text, branch_id text, branch_name text, branch_group_code text, branch_group_id text, region_code text, branch_type text, city_code text, retail_zone_id text, retail_zone_name text, division text, region_new_name text, is_delete text, zone_code_new text, zone_name_new_vn text, zone_name_new text, zone_type text, hub_af_flag text, src_sys_code text, tf_sourcing_at text, tf_run_id text, tf_partition_date text, tf_source_system text);
-- tf_partition_date = 2026-09-29: 11 dòng
insert into qa_expected.bi_intf__bi_branch_info_intf__mnp (branch_code, branch_id, branch_name, branch_group_code, branch_group_id, region_code, branch_type, city_code, retail_zone_id, retail_zone_name, division, region_new_name, is_delete, zone_code_new, zone_name_new_vn, zone_name_new, zone_type, hub_af_flag, src_sys_code, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('BNH', 'VN0010406', 'CHI NHANH BAC NINH', null, 'VN0019999', 'MB', 'CHI NHANH', 'BAC NINH', 'R12', 'VUNG 01', 'RB', null, null, 'A03', 'Khu vực Đông Bắc Bộ', 'Khu vuc Dong Bac Bo', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('CGY', 'VN0010103', 'TEN CU PGD CAU GIAY', 'HAN', 'VN0010102', 'MB', 'PGD', 'HA NOI', 'R02', 'VUNG 02', 'RB', 'BAC', null, 'A01', 'Khu vực Hà Nội 1', 'Khu vuc Ha Noi 1', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('CTO', 'VN0010810', 'CHI NHANH CAN THO', 'CTO', 'VN0010810', 'MN', 'CHI NHANH', 'CAN THO', 'R09', 'VUNG 09', 'RB', 'NAM', null, 'A09', 'Khu vực Tây Nam Bộ', 'Khu vuc Tay Nam Bo', 'HUB', 'Y', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('DNG', 'VN0010305', 'CHI NHANH DA NANG', 'DNG', 'VN0010305', 'MT', 'CHI NHANH', 'DA NANG', 'R07', 'VUNG 07', 'SME', 'NAM', null, 'A05', 'Khu vực Đà Nẵng', 'Khu vuc Da Nang', 'HUB', 'Y', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('HAN', 'VN0010102', 'CHI NHANH HA NOI', 'HAN', 'VN0010102', 'MB', 'CHI NHANH', 'HA NOI', 'R03', 'VUNG 03', 'RB', 'BAC', null, 'A01', 'Khu vực Hà Nội 1', 'Khu vuc Ha Noi 1', 'HUB', 'Y', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('HCM', 'VN0010204', 'CHI NHANH HO CHI MINH CN SAI GON', 'HCM', 'VN0010204', 'MN', 'CHI NHANH', 'HO CHI MINH', 'R10', 'VUNG 10', 'RB', 'NAM', null, 'A07', 'Khu vực Hồ Chí Minh 2', 'Khu vuc Ho Chi Minh 2', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('HKH', 'VN0010709', 'PGD HOA KHANH', 'HKH', 'VN0010709', 'MT', 'PGD', 'DA NANG', 'R05', 'VUNG 05', 'RB', 'BAC', null, 'A05', 'Khu vực Đà Nẵng', 'Khu vuc Da Nang', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('HPG', 'VN0010507', 'CHI NHANH HAI PHONG', 'HPG', 'VN0010507', 'MB', 'CHI NHANH', null, 'OTH', 'VUNG KHAC', 'RB', null, '1', null, null, null, null, null, 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('HPL', 'VN0010911', 'CHI NHANH HAI PHONG CN LE CHAN', 'HPL', 'VN0010911', 'MB', 'CHI NHANH', 'HAI PHONG', 'R06', 'VUNG 06', 'RB', 'BAC', null, 'A03', 'Khu vực Đông Bắc Bộ', 'Khu vuc Dong Bac Bo', 'HUB', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('HSC', 'VN0010001', 'HOI SO CHINH', 'HSC', 'VN0010001', 'MB', 'HOI SO', 'HA NOI', 'R01', 'VUNG 01', 'HO', 'BAC', null, null, null, null, null, null, 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF'),
  ('PG8', 'VN0010608', 'CHI NHANH HA NOI PGD DONG DA', 'PG8', 'VN0010608', 'MB', 'PGD', 'HA NOI', 'R04', 'VUNG 04', 'RB', 'BAC', null, 'A02', 'Khu vực Hà Nội 2', 'Khu vuc Ha Noi 2', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-29', 'BRANCH_INTF');
-- tf_partition_date = 2026-09-30: 8 dòng
insert into qa_expected.bi_intf__bi_branch_info_intf__mnp (branch_code, branch_id, branch_name, branch_group_code, branch_group_id, region_code, branch_type, city_code, retail_zone_id, retail_zone_name, division, region_new_name, is_delete, zone_code_new, zone_name_new_vn, zone_name_new, zone_type, hub_af_flag, src_sys_code, tf_sourcing_at, tf_run_id, tf_partition_date, tf_source_system) values
  ('BNH', 'VN0010406', 'CHI NHANH BAC NINH', null, 'VN0019999', 'MB', 'CHI NHANH', 'BAC NINH', 'R12', 'VUNG 01', 'RB', null, null, 'A03', 'Khu vực Đông Bắc Bộ', 'Khu vuc Dong Bac Bo', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('CGY', 'VN0010103', 'CHI NHANH HA NOI PGD CAU GIAY', 'HAN', 'VN0010102', 'MB', 'PGD', 'HA NOI', 'R02', 'VUNG 02', 'RB', 'BAC', null, null, null, null, null, null, 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('CTO', 'VN0010810', 'CHI NHANH CAN THO', 'CTO', 'VN0010810', 'MN', 'CHI NHANH', 'CAN THO', 'R09', 'VUNG 09', 'RB', 'NAM', null, 'A09', 'Khu vực Tây Nam Bộ', 'Khu vuc Tay Nam Bo', 'HUB', 'Y', 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('DNG', 'VN0010305', 'CHI NHANH DA NANG', 'DNG', 'VN0010305', 'MT', 'CHI NHANH', null, 'R07', 'VUNG 07', 'SME', 'NAM', null, 'A05', 'Khu vực Đà Nẵng', 'Khu vuc Da Nang', 'HUB', 'Y', 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('HAN', 'VN0010102', 'CHI NHANH HA NOI', 'HAN', 'VN0010102', 'MB', 'CHI NHANH', 'HA NOI', 'R02', 'VUNG 02', 'RB', 'BAC', null, 'A01', 'Khu vực Hà Nội 1', 'Khu vuc Ha Noi 1', 'HUB', 'Y', 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('HCM', 'VN0010204', 'CHI NHANH HO CHI MINH CN SAI GON', 'HCM', 'VN0010204', 'MN', 'CHI NHANH', 'HO CHI MINH', 'R10', 'VUNG 10', 'RB', 'NAM', null, 'A07', 'Khu vực Hồ Chí Minh 2', 'Khu vuc Ho Chi Minh 2', 'SPOKE', 'N', 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('HPG', 'VN0010507', 'CHI NHANH HAI PHONG', 'HPG', 'VN0010507', 'MB', 'CHI NHANH', null, 'OTH', 'VUNG KHAC', 'RB', null, '1', null, null, null, null, null, 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF'),
  ('HSC', 'VN0010001', 'HOI SO CHINH', 'HSC', 'VN0010001', 'MB', 'HOI SO', 'HA NOI', 'R01', 'VUNG 01', 'HO', 'BAC', null, null, null, null, null, null, 'T24_BANK_COMPANY', null, 'manual', '2026-09-30', 'BRANCH_INTF');

drop table if exists qa_expected.dwh_intf__branch_intf;
create table qa_expected.dwh_intf__branch_intf (business_date text, branch_code text, src_sys_code text, value_date text, actual_end_date text, branch_name text, division text, main_branch_code text, book_code text, main_book_code text, retail_region_code text, retail_region_name text, branch_status text, geo_zone text, branch_type text, provin_code text, provin_name text);
-- business_date = 2026-09-29: 13 dòng
insert into qa_expected.dwh_intf__branch_intf (business_date, branch_code, src_sys_code, value_date, actual_end_date, branch_name, division, main_branch_code, book_code, main_book_code, retail_region_code, retail_region_name, branch_status, geo_zone, branch_type, provin_code, provin_name) values
  ('2026-09-29', '0101', 'WAY4_F_I', null, null, 'WAY4 BRANCH 0101', null, null, null, null, null, null, null, null, null, null, null),
  ('2026-09-29', 'VN0010001', 'T24_BANK_COMPANY', '2010-01-01', null, 'HOI SO CHINH', 'HO', 'VN0010001', 'HSC', 'HSC', 'R1', 'VUNG 1', 'ACTIVE', 'MB', 'HOI SO', '01', 'TP HA NOI'),
  ('2026-09-29', 'VN0010102', 'T24_BANK_COMPANY', '2012-03-15', null, 'CHI NHANH HA NOI', 'RB', 'VN0010102', 'HAN', 'HAN', 'R3', 'VUNG 3', 'ACTIVE', 'MB', 'CHI NHANH', '01', 'TP HA NOI'),
  ('2026-09-29', 'VN0010103', 'T24_BANK_COMPANY', '2015-06-01', null, 'TEN CU PGD CAU GIAY', 'RB', 'VN0010102', 'CGY', 'HAN', 'R2', 'VUNG 2', 'ACTIVE', 'MB', 'PGD', '01', 'TP HA NOI'),
  ('2026-09-29', 'VN0010204', 'T24_BANK_COMPANY', '2011-09-09', null, 'CHI NHANH HO CHI MINH CN SAI GON', 'RB', 'VN0010204', 'HCM', 'HCM', 'R10', 'VUNG 10', 'ACTIVE', 'MN', 'CHI NHANH', '79', 'TP HO CHI MINH'),
  ('2026-09-29', 'VN0010305', 'T24_BANK_COMPANY', '2014-04-20', null, 'CHI NHANH DA NANG', 'SME', 'VN0010305', 'DNG', 'DNG', 'R7', 'VUNG7', 'ACTIVE', 'MT', 'CHI NHANH', '48', 'TP DA NANG'),
  ('2026-09-29', 'VN0010406', 'T24_BANK_COMPANY', '2016-11-11', '2026-09-30', 'CHI NHANH BAC NINH', 'RB', 'VN0019999', 'BNH', null, 'R12', 'VUNG1', 'ACTIVE', 'MB', 'CHI NHANH', '27', 'BAC NINH'),
  ('2026-09-29', 'VN0010507', 'T24_BANK_COMPANY', '2013-02-02', '2026-08-31', 'CHI NHANH HAI PHONG', 'RB', 'VN0010507', 'HPG', 'HPG', null, null, 'CLOSED', 'MB', 'CHI NHANH', null, null),
  ('2026-09-29', 'VN0010608', 'T24_BANK_COMPANY', '2018-08-08', null, 'CHI NHANH HA NOI PGD DONG DA', 'RB', 'VN0010608', 'PG8', 'PG8', 'R4', 'VUNG 04', 'ACTIVE', 'MB', 'PGD', '01', 'TP HA NOI'),
  ('2026-09-29', 'VN0010709', 'T24_BANK_COMPANY', '2019-09-19', null, 'PGD HOA KHANH', 'RB', 'VN0010709', 'HKH', 'HKH', 'R5', 'VUNG 05', 'ACTIVE', 'MT', 'PGD', '48', 'TP DA NANG'),
  ('2026-09-29', 'VN0010810', 'T24_BANK_COMPANY', '2017-07-07', null, 'CHI NHANH CAN THO', 'RB', 'VN0010810', 'CTO', 'CTO', 'R9', '9', 'ACTIVE', 'MN', 'CHI NHANH', '92', 'TP CAN THO'),
  ('2026-09-29', 'VN0010911', 'T24_BANK_COMPANY', '2021-05-05', null, 'CHI NHANH HAI PHONG CN LE CHAN', 'RB', 'VN0010911', 'HPL', 'HPL', 'R6', 'VUNG 6', 'ACTIVE', 'MB', 'CHI NHANH', '31', 'TP HAI PHONG'),
  ('2026-09-29', 'ZZZZZZZZZ', 'T24_BANK_COMPANY', null, null, 'ZZZZZZZZZ', null, null, null, null, null, null, null, null, null, null, null);
-- business_date = 2026-09-30: 10 dòng
insert into qa_expected.dwh_intf__branch_intf (business_date, branch_code, src_sys_code, value_date, actual_end_date, branch_name, division, main_branch_code, book_code, main_book_code, retail_region_code, retail_region_name, branch_status, geo_zone, branch_type, provin_code, provin_name) values
  ('2026-09-30', '0101', 'WAY4_F_I', null, null, 'WAY4 BRANCH 0101', null, null, null, null, null, null, null, null, null, null, null),
  ('2026-09-30', 'VN0010001', 'T24_BANK_COMPANY', '2010-01-01', null, 'HOI SO CHINH', 'HO', 'VN0010001', 'HSC', 'HSC', 'R1', 'VUNG 1', 'ACTIVE', 'MB', 'HOI SO', '01', 'TP HA NOI'),
  ('2026-09-30', 'VN0010102', 'T24_BANK_COMPANY', '2012-03-15', null, 'CHI NHANH HA NOI', 'RB', 'VN0010102', 'HAN', 'HAN', 'R2', 'VUNG 2', 'ACTIVE', 'MB', 'CHI NHANH', '01', 'TP HA NOI'),
  ('2026-09-30', 'VN0010103', 'T24_BANK_COMPANY', '2015-06-01', null, 'CHI NHANH HA NOI PGD CAU GIAY', 'RB', 'VN0010102', 'CGY', 'HAN', 'R2', 'VUNG 2', 'ACTIVE', 'MB', 'PGD', '01', 'TP HA NOI'),
  ('2026-09-30', 'VN0010204', 'T24_BANK_COMPANY', '2011-09-09', null, 'CHI NHANH HO CHI MINH CN SAI GON', 'RB', 'VN0010204', 'HCM', 'HCM', 'R10', 'VUNG 10', 'ACTIVE', 'MN', 'CHI NHANH', '79', 'TP HO CHI MINH'),
  ('2026-09-30', 'VN0010305', 'T24_BANK_COMPANY', '2014-04-20', null, 'CHI NHANH DA NANG', 'SME', 'VN0010305', 'DNG', 'DNG', 'R7', 'VUNG 7', 'ACTIVE', 'MT', 'CHI NHANH', '48', null),
  ('2026-09-30', 'VN0010406', 'T24_BANK_COMPANY', '2016-11-11', '2026-09-30', 'CHI NHANH BAC NINH', 'RB', 'VN0019999', 'BNH', null, 'R12', 'VUNG1', 'ACTIVE', 'MB', 'CHI NHANH', '27', 'BAC NINH'),
  ('2026-09-30', 'VN0010507', 'T24_BANK_COMPANY', '2013-02-02', '2026-08-31', 'CHI NHANH HAI PHONG', 'RB', 'VN0010507', 'HPG', 'HPG', null, null, 'CLOSED', 'MB', 'CHI NHANH', null, null),
  ('2026-09-30', 'VN0010810', 'T24_BANK_COMPANY', '2017-07-07', null, 'CHI NHANH CAN THO', 'RB', 'VN0010810', 'CTO', 'CTO', 'R9', '9', 'ACTIVE', 'MN', 'CHI NHANH', '92', 'TP CAN THO'),
  ('2026-09-30', 'ZZZZZZZZZ', 'T24_BANK_COMPANY', null, null, 'ZZZZZZZZZ', null, null, null, null, null, null, null, null, null, null, null);

