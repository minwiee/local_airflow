-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 02_deposit: tạo bảng nguồn và bảng đích (chạy lại sẽ xóa và tạo mới)

-- ---------------------------------------------------------------------------
-- Case 02 - Tiền gửi: bảng nguồn
-- ---------------------------------------------------------------------------
-- Chỉ khai báo các cột mà interface dùng tới.
-- Kiểu dữ liệu theo cách model ép kiểu khi đọc.
-- Ba bảng T24 LD bên dưới chép nguyên văn từ common/ddl_shared/t24_ld_tables.sql
-- (case 03 - khoản vay dùng cùng cấu trúc). Case 02 chỉ đọc các cột: contract_no_,
-- category, customer_id, currency, co_code, status, value_date, fin_mat_date,
-- int_paymt_method của phần đầu hợp đồng; amount, interest_rate của phần chi tiết;
-- category, ar_tp của file map. Các cột còn lại để trống trong dữ liệu test.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Bảng T24 LD dùng chung cho case 02 (tiền gửi) và case 03 (khoản vay)
-- ---------------------------------------------------------------------------
-- T24 lưu hợp đồng vay và hợp đồng tiền gửi có kỳ hạn chung một ứng dụng
-- LD.LOANS.AND.DEPOSITS. Thứ phân biệt vay với gửi là bảng map category ->
-- loại arrangement (csv_ma_map_cgy_ar_tp): T24-DEP-LD là tiền gửi, T24-LOAN-LD
-- là khoản vay. Hai case dùng cùng cấu trúc bảng dưới đây; mỗi case tự nạp bộ
-- dữ liệu test riêng của mình, nên chạy case nào thì nạp lại dữ liệu case đó.
-- Chỉ khai báo các cột mà hai interface dùng tới. T24 lưu ngày dạng chuỗi
-- YYYYMMDD nên value_date và fin_mat_date để kiểu varchar(8).
-- ---------------------------------------------------------------------------

-- Phần đầu hợp đồng LD: mỗi business date một bản chụp đầy đủ (__mnp)
drop table if exists raw_eod.t24_ld_loans_and_depo__mnp;
create table raw_eod.t24_ld_loans_and_depo__mnp (
    contract_no_      varchar(32),    -- số hợp đồng
    category          varchar(16),    -- mã category sản phẩm của T24
    customer_id       varchar(32),    -- mã khách hàng
    currency          varchar(3),
    co_code           varchar(32),    -- mã đơn vị quản lý hợp đồng
    status            varchar(16),    -- CUR = đang hiệu lực, LIQ = đã tất toán
    value_date        varchar(8),     -- ngày hiệu lực, YYYYMMDD
    fin_mat_date      varchar(8),     -- ngày đáo hạn cuối, YYYYMMDD
    term              varchar(20),    -- kỳ hạn như nhập trên T24
    int_rate_type     varchar(8),     -- 1 = lãi suất của hợp đồng, 2 = lãi suất + biên độ
    int_ref_type      varchar(64),    -- loại lãi suất tham chiếu
    interest_spread   numeric(18,6),  -- biên độ lãi suất
    rate_change_fre   varchar(16),    -- tần suất điều chỉnh lãi suất
    int_paymt_method  varchar(8),     -- phương thức trả lãi; 2 = trả lãi đầu kỳ
    prin_liq_acct     varchar(32),    -- tài khoản trả gốc
    int_liq_acct      varchar(32),    -- tài khoản trả lãi
    no_ovd_days       integer,        -- số ngày quá hạn
    overdue_status    varchar(16),
    tf_partition_date date
);

-- Trường nhiều giá trị của LD: dòng (m = 1, s = 1) mang số tiền và lãi suất
drop table if exists raw_eod.t24_ld_loans_and_depo_details__mnp;
create table raw_eod.t24_ld_loans_and_depo_details__mnp (
    contract_no_      varchar(32),
    m                 integer,
    s                 integer,
    amount            numeric(23,5),
    interest_rate     numeric(18,6),
    tf_partition_date date
);

-- File MA map category -> loại arrangement
drop table if exists dwh_ref.csv_ma_map_cgy_ar_tp__mnp;
create table dwh_ref.csv_ma_map_cgy_ar_tp__mnp (
    category          varchar(16),
    ar_tp             varchar(32),    -- T24-DEP-LD | T24-LOAN-LD | ...
    sub_ar_tp         varchar(32),
    tf_partition_date date
);

-- ---------------------------------------------------------------------------
-- Bảng riêng của case 02
-- ---------------------------------------------------------------------------

-- File MA csv_partb_product: xếp mã sản phẩm vào nhóm sản phẩm theo cách nhìn của khối BI
-- (nguồn phụ của layer 2). Với tiền gửi, mã sản phẩm chính là category của T24.
-- Kiểu bảng __mnp: mỗi ngày một bản đầy đủ của file, phân biệt bằng tf_partition_date.
drop table if exists bi_ref.csv_partb_product__mnp;
create table bi_ref.csv_partb_product__mnp (
    prd_code          varchar(64),    -- mã sản phẩm; nối với cate_code của depo_intf
    prd_group         varchar(64),    -- nhóm sản phẩm: 1. Current Account | 2. Term Deposit | 3. Others
    tf_partition_date date
);

-- ---------------------------------------------------------------------------
-- Case 02 - Tiền gửi: bảng đích
-- ---------------------------------------------------------------------------
-- Model interface dùng materialized = incremental, on_schema_change = fail:
-- bảng phải có sẵn đúng cấu trúc, mỗi lần chạy chỉ xóa và nạp lại ngày đang chạy.
-- Thứ tự cột ở đây là thứ tự cột trong câu select của model. Hai bảng staging
-- (schema dwh_stag) không khai báo ở đây: mỗi lần chạy chúng được xóa và tạo lại.
-- ---------------------------------------------------------------------------

-- Interface L1: mỗi dòng là một hợp đồng tiền gửi tại một business date.
-- Hợp đồng còn hiệu lực có mặt mỗi ngày; hợp đồng tất toán chỉ có mặt đúng ngày tất toán.
-- Khóa: (business_date, contract_nbr)
drop table if exists dwh_intf.depo_intf;
create table dwh_intf.depo_intf (
    business_date      date,
    ppn_date           timestamp,      -- thời điểm nạp
    contract_nbr       varchar(64),    -- số hợp đồng tiền gửi
    cust_code          varchar(64),    -- mã khách hàng
    ccy_code           varchar(64),    -- loại tiền của hợp đồng
    mgmt_branch_code   varchar(64),    -- đơn vị quản lý hợp đồng
    cate_code          varchar(64),    -- category sản phẩm của T24
    close_date         date,           -- ngày tất toán (trống nếu còn hiệu lực)
    inst_rate          numeric(8,5),   -- lãi suất
    inst_pmt_method    varchar(20),    -- DAU KY = trả lãi đầu kỳ, CUOI KY = trả lãi cuối kỳ
    depo_close_type    varchar(10),    -- MAT = tất toán đúng hạn, MAT_EARLY = tất toán trước hạn
    close_amt_fcy      numeric(23,5),  -- số dư nguyên tệ; hợp đồng tất toán: số dư ngày làm việc trước
    notion_mat_date    date,           -- ngày đáo hạn
    term               varchar(32),    -- kỳ hạn suy ra từ ngày hiệu lực và ngày đáo hạn: nW hoặc nM
    acct_seprt_type    varchar(32),    -- CUR = còn hiệu lực, CLOSE = tất toán trong ngày
    value_date         date            -- ngày hiệu lực
);

-- Bảng biến đổi của layer 2 (nằm ở schema ref của khối BI), còn giữ cả hợp đồng tất toán trong ngày
-- Khóa: (tf_partition_date, contract_nbr)
drop table if exists bi_ref.tfm_bi_depo_prfl__mnp;
create table bi_ref.tfm_bi_depo_prfl__mnp (
    contract_nbr       varchar(64),
    cust_code          varchar(64),
    ccy_code           varchar(32),
    notion_mat_date    date,
    inst_rate          numeric(8,5),
    close_amt_fcy      numeric(23,5),
    acct_seprt_type    varchar(64),
    prd_group_name     varchar(256),   -- nhóm sản phẩm tra từ file MA csv_partb_product
    bi_term            varchar(10),    -- kỳ hạn theo cách tính của BI (đơn vị tháng), chỉ có với nhóm tiền gửi có kỳ hạn
    cate_code          varchar(64),
    eff_date           date,           -- ngày hiệu lực (value_date của depo_intf)
    tf_etl_at          timestamp,
    tf_sourcing_at     timestamp,
    tf_run_id          varchar(128),
    tf_partition_date  date,
    tf_source_system   varchar(64)     -- DEPO_INTF
);

-- Interface layer 2 của khối BI: các hợp đồng tiền gửi còn mở tại tf_partition_date
-- Khóa: (tf_partition_date, contract_nbr)
drop table if exists bi_intf.bi_depo_info_intf__mnp;
create table bi_intf.bi_depo_info_intf__mnp (
    contract_nbr       varchar(64),
    cust_code          varchar(64),
    ccy_code           varchar(32),
    notion_mat_date    date,
    inst_rate          numeric(8,5),
    close_amt_fcy      numeric(23,5),
    acct_seprt_type    varchar(64),
    prd_group_name     varchar(256),
    bi_term            varchar(10),
    cate_code          varchar(64),
    eff_date           date,
    tf_etl_at          timestamp,
    tf_sourcing_at     timestamp,
    tf_run_id          varchar(128),
    tf_partition_date  date,
    tf_source_system   varchar(64)
);

