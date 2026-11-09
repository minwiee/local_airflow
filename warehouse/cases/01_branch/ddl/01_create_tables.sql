-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 01_branch: tạo bảng nguồn và bảng đích (chạy lại sẽ xóa và tạo mới)

-- ---------------------------------------------------------------------------
-- Case 01 - Chi nhánh: bảng nguồn
-- ---------------------------------------------------------------------------
-- Chỉ khai báo các cột mà interface dùng tới.
-- Kiểu dữ liệu theo cách model ép kiểu khi đọc.
-- ---------------------------------------------------------------------------

-- T24 BANK.COMPANY: mỗi dòng là một đơn vị kinh doanh (hội sở, chi nhánh, phòng giao dịch)
-- Kiểu bảng __mnp: mỗi business date có một bản chụp đầy đủ, phân biệt bằng tf_partition_date
drop table if exists dwh_stag_eod.stg_raw_t24_bank_company__mnp;
create table dwh_stag_eod.stg_raw_t24_bank_company__mnp (
    id                varchar(32),    -- mã đơn vị trong T24 (company code)
    from_date         date,           -- ngày bắt đầu hiệu lực
    to_date           date,           -- ngày kết thúc hoạt động (trống = còn hoạt động)
    segment           varchar(32),    -- khối quản lý
    main_branch_code  varchar(32),    -- mã chi nhánh cấp trên
    region_khcn_code  varchar(32),    -- mã vùng khối khách hàng cá nhân
    region_khcn_name  varchar(64),    -- tên vùng khối khách hàng cá nhân
    region            varchar(32),    -- miền địa lý
    status            varchar(64),
    branch_type       varchar(64),    -- loại đơn vị
    code_province     varchar(8),     -- mã tỉnh/thành
    tf_partition_date date
);

-- T24 BANK.COMPANY.DETAILS: trường nhiều giá trị (multi-value) của BANK.COMPANY
-- Một đơn vị có nhiều dòng tên, đánh số bằng m (multi-value) và s (sub-value)
drop table if exists dwh_stag_eod.stg_raw_t24_bank_company_details__mnp;
create table dwh_stag_eod.stg_raw_t24_bank_company_details__mnp (
    id                varchar(32),
    m                 integer,
    s                 integer,
    branch_name       varchar(64),
    tf_partition_date date
);

-- T24 COMPANY: danh mục company chuẩn của T24, lấy mnemonic làm mã book
-- Kiểu bảng __s2 (SCD type 2): mỗi lần đổi sinh một dòng mới, hiệu lực từ
-- tf_created_at đến trước tf_updated_at
drop table if exists raw_eod.t24_company__s2;
create table raw_eod.t24_company__s2 (
    company_code      varchar(32),
    mnemonic          varchar(32),
    tf_created_at     timestamp,
    tf_updated_at     timestamp
);

-- T24 BANK.PROVINCE.DETAILS: danh mục tỉnh/thành
drop table if exists dwh_stag_eod.stg_raw_t24_bank_province_details__mnp;
create table dwh_stag_eod.stg_raw_t24_bank_province_details__mnp (
    id                varchar(8),
    province_name     varchar(64),
    tf_partition_date date
);

-- File MA csv_cv: bảng mã dùng chung (classification value), nhiều bộ mã phân biệt bằng cl_scm_id
drop table if exists dwh_ref.csv_cv__mnp;
create table dwh_ref.csv_cv__mnp (
    cl_scm_id         varchar(16),    -- mã bộ mã (scheme)
    cl_code           varchar(32),
    cl_nm             varchar(64),
    tf_partition_date date
);

-- File MA csv_ma_rbd_branch_area: khu vực mới của khối RBD theo từng chi nhánh (nguồn phụ của layer 2)
drop table if exists bi_ref.csv_ma_rbd_branch_area__mnp;
create table bi_ref.csv_ma_rbd_branch_area__mnp (
    branch_id         varchar(32),
    area_code         varchar(64),
    area_name         varchar(255),
    branch_type       varchar(64),
    hub_af            varchar(64),
    tf_partition_date date
);

-- ---------------------------------------------------------------------------
-- Case 01 - Chi nhánh: bảng đích
-- ---------------------------------------------------------------------------
-- Model interface dùng materialized = incremental, on_schema_change = fail:
-- bảng phải có sẵn đúng cấu trúc, mỗi lần chạy chỉ xóa và nạp lại ngày đang chạy.
-- Thứ tự cột ở đây là thứ tự cột trong câu select của model.
-- ---------------------------------------------------------------------------

-- Interface L1: mỗi dòng là một đơn vị của một hệ thống nguồn tại một business date
-- Khóa: (business_date, branch_code, src_sys_code)
drop table if exists dwh_intf.branch_intf;
create table dwh_intf.branch_intf (
    business_date      date,
    ppn_date           timestamp,      -- thời điểm nạp
    branch_code        varchar(32),
    src_sys_code       varchar(64),    -- hệ thống nguồn: T24_BANK_COMPANY, WAY4_F_I...
    value_date         date,
    actual_end_date    date,
    branch_name        varchar(64),
    division           varchar(32),
    main_branch_code   varchar(32),
    book_code          varchar(32),
    main_book_code     varchar(32),
    retail_region_code varchar(32),
    retail_region_name varchar(64),
    branch_status      varchar(64),
    geo_zone           varchar(32),
    branch_type        varchar(64),
    provin_code        varchar(64),
    provin_name        varchar(64)
);

-- Bảng biến đổi của layer 2 (nằm ở schema ref của khối BI)
-- Khóa: (tf_partition_date, branch_id)
drop table if exists bi_ref.tfm_bi_branch_info__mnp;
create table bi_ref.tfm_bi_branch_info__mnp (
    branch_code        varchar(64),
    branch_id          varchar(64),
    branch_name        varchar(255),
    branch_group_code  varchar(64),
    branch_group_id    varchar(64),
    region_code        varchar(64),
    branch_type        varchar(64),
    city_code          varchar(64),
    retail_zone_id     varchar(64),
    retail_zone_name   varchar(255),
    division           varchar(64),
    region_new_name    varchar(255),
    is_delete          char(18),
    zone_code_new      varchar(255),
    zone_name_new_vn   varchar(255),
    zone_name_new      varchar(255),
    zone_type          varchar(64),
    hub_af_flag        varchar(64),
    src_sys_code       varchar(64),
    tf_etl_at          timestamp,
    tf_sourcing_at     timestamp,
    tf_run_id          varchar(128),
    tf_partition_date  date,
    tf_source_system   varchar(64)
);

-- Interface layer 2 của khối BI: lấy 1-1 từ bảng tfm
-- Khóa: (tf_partition_date, branch_id)
drop table if exists bi_intf.bi_branch_info_intf__mnp;
create table bi_intf.bi_branch_info_intf__mnp (
    branch_code        varchar(64),
    branch_id          varchar(64),
    branch_name        varchar(255),
    branch_group_code  varchar(64),
    branch_group_id    varchar(64),
    region_code        varchar(64),
    branch_type        varchar(64),
    city_code          varchar(64),
    retail_zone_id     varchar(64),
    retail_zone_name   varchar(255),
    division           varchar(64),
    region_new_name    varchar(255),
    is_delete          char(18),
    zone_code_new      varchar(255),
    zone_name_new_vn   varchar(255),
    zone_name_new      varchar(255),
    zone_type          varchar(64),
    hub_af_flag        varchar(64),
    src_sys_code       varchar(64),
    tf_etl_at          timestamp,
    tf_sourcing_at     timestamp,
    tf_run_id          varchar(128),
    tf_partition_date  date,
    tf_source_system   varchar(64)
);

