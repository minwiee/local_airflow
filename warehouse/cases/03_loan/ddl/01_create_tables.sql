-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 03_loan: tạo bảng nguồn và bảng đích (chạy lại sẽ xóa và tạo mới)

-- ---------------------------------------------------------------------------
-- Case 03 - Khoản vay: bảng nguồn
-- ---------------------------------------------------------------------------
-- Chỉ khai báo các cột mà interface dùng tới.
-- Ba bảng T24 LD đầu tiên chép nguyên văn từ common/ddl_shared/t24_ld_tables.sql
-- (case 02 - tiền gửi dùng cùng cấu trúc). Hai bảng cuối do DAG khác dựng;
-- ở môi trường dev chúng được nạp sẵn dữ liệu như một bảng nguồn.
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
-- Hai bảng riêng của case 03
-- ---------------------------------------------------------------------------

-- Số dư sổ cái (GL) theo từng hợp đồng: bảng biến đổi của bảng T24 RE.CRF.SBV.
-- bal_sheet_detail_intf_dag dựng bảng này từ raw_eod.t24_re_crf_sbv__mnp bằng cách
-- tách chuỗi RECID; loan_contract_intf_dag chỉ đọc.
-- Mỗi hợp đồng có nhiều dòng (mỗi tài khoản SBV một dòng). Kiểu bảng __mnp.
drop table if exists dwh_ref.tfm_re_crf_sbv__mnp;
create table dwh_ref.tfm_re_crf_sbv__mnp (
    ctr_no            varchar(64),    -- số hợp đồng trên dòng GL; phần nợ quá hạn của hợp đồng LD mang số PD + số hợp đồng (PDLD...)
    mud_code          varchar(10),    -- phân hệ T24 của dòng: LD, PD, MD, MM, LCM, AC
    desc_3            varchar(10),    -- tài khoản SBV dạng SBV.xxxx; SBV.9995 và SBV.9996 không được tính
    deal_bal_lcy      numeric(23,5),  -- số dư của dòng, quy đổi về đồng nội tệ
    tf_partition_date date
);

-- Interface L1 giao dịch trả nợ trong ngày (nguồn phụ của layer 2).
-- repay_acty_intf_dag dựng bảng này từ lịch sử trả nợ trong hạn của LD và giao dịch
-- trả nợ quá hạn của PD.
-- Mỗi dòng là một lần trả nợ. Khóa: (business_date, repay_acty_code)
drop table if exists dwh_intf.repay_acty_intf;
create table dwh_intf.repay_acty_intf (
    business_date     date,
    repay_acty_code   varchar(128),   -- mã giao dịch trả nợ
    contract_nbr      varchar(64),    -- số hợp đồng: LD... = trả nợ trong hạn, PDLD... = trả nợ quá hạn của hợp đồng LD
    cate_code         varchar(10),    -- category của hợp đồng; trống khi không tìm được hợp đồng
    cust_code         varchar(64),
    ccy_code          char(3),
    repay_date        date,           -- ngày trả nợ (có thể trước business_date nếu ghi lùi ngày)
    repay_amt         numeric(18,2),  -- tổng số tiền trả
    prin_amt          numeric(18,2),  -- phần trả gốc
    inst_amt          numeric(18,2)   -- phần trả lãi
);

-- ---------------------------------------------------------------------------
-- Case 03 - Khoản vay: bảng đích
-- ---------------------------------------------------------------------------
-- Model interface dùng materialized = incremental, on_schema_change = fail:
-- bảng phải có sẵn đúng cấu trúc, mỗi lần chạy chỉ xóa và nạp lại ngày đang chạy.
-- Bảng staging dwh_stag.stg_ar_x_cl_pst_t24_loan__snp không khai báo ở đây vì model
-- tạo lại nó (materialized = table) mỗi lần chạy.
-- ---------------------------------------------------------------------------

-- Interface L1: mỗi dòng là một hợp đồng vay tại một business date
-- Khóa: (business_date, contract_nbr)
drop table if exists dwh_intf.loan_contract_intf;
create table dwh_intf.loan_contract_intf (
    business_date        date,
    ppn_date             timestamp,      -- thời điểm nạp
    contract_nbr         varchar(32),    -- số hợp đồng LD
    cust_code            varchar(64),    -- mã khách hàng vay
    cate_code            varchar(20),    -- category sản phẩm của T24
    ccy_code             varchar(3),
    value_date           date,           -- ngày hiệu lực
    mat_date             date,           -- ngày đáo hạn cuối, đã kiểm tra hợp lệ
    term                 varchar(20),    -- kỳ hạn như nhập trên T24
    inst_rate_type       varchar(64),    -- FIXED | FLOATING
    inst_rate            numeric(8,5),   -- lãi suất đang áp dụng
    inst_reset_freq      varchar(64),    -- tần suất điều chỉnh lãi suất, đã chuẩn hóa
    outs_prin_amt        numeric(18,2),  -- dư nợ gốc trong hạn
    prin_repay_acct_nbr  varchar(64),    -- tài khoản trả gốc
    inst_repay_acct_nbr  varchar(64),    -- tài khoản trả lãi
    nbr_ovd_day          integer         -- số ngày quá hạn
);

-- Interface layer 2 của khối BI: mỗi dòng là một giao dịch trả nợ trong ngày,
-- kèm tài khoản trả nợ và số ngày quá hạn lấy từ interface hợp đồng vay
-- Khóa: (business_date, repay_acty_code)
drop table if exists bi_intf.bi_lend_repay_info_intf__fa;
create table bi_intf.bi_lend_repay_info_intf__fa (
    contract_nbr      varchar(64),    -- số hợp đồng LD (đã đổi PDLD... về LD...)
    ccy_code          varchar(10),
    repay_date        date,
    repay_amt_lcy     numeric(23,5),  -- tổng số tiền trả
    prin_amt_lcy      numeric(23,5),  -- phần trả gốc
    inst_amt_lcy      numeric(23,5),  -- phần trả lãi
    prin_repay_acct   varchar(64),    -- tài khoản trả gốc của hợp đồng
    inst_repay_acct   varchar(64),    -- tài khoản trả lãi của hợp đồng
    nbr_of_ovd_day    integer,        -- số ngày quá hạn, chỉ có với giao dịch trả nợ quá hạn
    business_date     date,
    cust_code         varchar(64),
    repay_acty_code   varchar(128),   -- mã giao dịch trả nợ
    tf_etl_at         timestamp,
    tf_sourcing_at    timestamp,
    tf_run_id         varchar(128),
    tf_source_system  varchar(64),
    tf_partition_date date
);

