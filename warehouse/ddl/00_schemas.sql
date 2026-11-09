-- ---------------------------------------------------------------------------
-- DWH - tạo schema cho môi trường dev
-- ---------------------------------------------------------------------------
-- Tên schema giống production để câu SQL chạy ở dev, SIT và production như nhau.
-- Mỗi môi trường có một database kho dữ liệu chứa mọi schema của các lớp (nguồn,
-- interface L1, layer 2 của từng khối, mart); ở dev đó là database dwh_dev.
-- Mỗi khối nghiệp vụ có nhóm schema và user database riêng. Database điều khiển
-- (connection postgres-dwh-ctrl, schema dwh_ctrl) tách riêng ở SIT và production;
-- ở dev schema dwh_ctrl nằm chung database dwh_dev.
-- ---------------------------------------------------------------------------
set client_encoding to 'UTF8';

-- Lớp nguồn
create schema if not exists raw_eod;        -- EOD của hệ thống nguồn: T24, Way4...
create schema if not exists dwh_stag_eod;   -- staging thô: bản sao EOD theo từng business date (stg_raw_*)
create schema if not exists dwh_ref;        -- ref: file MA, bảng tham chiếu, bảng biến đổi tfm_*
create schema if not exists dwh_golden;     -- golden: dữ liệu theo subject area

-- Lớp interface L1
create schema if not exists dwh_stag;       -- staging của model: stg_*__snp
create schema if not exists dwh_intf;       -- interface L1

-- Lớp interface layer 2 của khối BI
create schema if not exists bi_stag;
create schema if not exists bi_ref;
create schema if not exists bi_intf;

-- Điều khiển và log (production: Postgres log_db, connection postgres-dwh-ctrl)
create schema if not exists dwh_ctrl;

-- Kết quả mong đợi của bộ dữ liệu kiểm thử, dùng để so với kết quả chạy
create schema if not exists qa_expected;
