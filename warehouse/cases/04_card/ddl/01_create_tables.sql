-- File này do tools/build_sql.py sinh ra. Đừng sửa tay: sửa nguồn rồi chạy lại công cụ.
set client_encoding to 'UTF8';

-- Case 04_card: tạo bảng nguồn và bảng đích (chạy lại sẽ xóa và tạo mới)

-- ---------------------------------------------------------------------------
-- Case 04 - Thẻ: bảng nguồn
-- ---------------------------------------------------------------------------
-- Chỉ khai báo các cột mà interface dùng tới.
-- Kiểu dữ liệu theo cách model ép kiểu khi đọc.
-- ---------------------------------------------------------------------------

-- Way4 ACNT_CONTRACT: bảng "hợp đồng" của hệ thống quản lý thẻ Way4.
-- Cùng một bảng chứa cả thẻ và hợp đồng thẻ, phân biệt bằng con_cat:
--   con_cat = 'C' : thẻ (card)
--   con_cat = 'A' : hợp đồng thẻ (account contract)
-- Thẻ trỏ về hợp đồng thẻ của nó qua acnt_contract__oid = id của hợp đồng.
-- Kiểu bảng __mnp: mỗi business date có một bản chụp đầy đủ, phân biệt bằng tf_partition_date
drop table if exists raw_eod.way4_acnt_contract__mnp;
create table raw_eod.way4_acnt_contract__mnp (
    id                   numeric(18,0),   -- id nội bộ của Way4, là khóa của thẻ / hợp đồng
    acnt_contract__oid   numeric(18,0),   -- id bản ghi cha; với thẻ là id của hợp đồng thẻ
    con_cat              varchar(1),      -- loại bản ghi: C = thẻ, A = hợp đồng thẻ
    pcat                 varchar(1),      -- model chỉ nhận hợp đồng có pcat = 'C'
    amnd_state           varchar(1),      -- trạng thái bản ghi: A = đang hiệu lực
    base_relation        varchar(32),     -- model chỉ lấy bản ghi để trống cột này
    contract_number_mask varchar(64),     -- với thẻ: số thẻ đã che; với hợp đồng: số hợp đồng
    product              varchar(32),     -- mã sản phẩm, nối với way4_appl_product.internal_code
    contr_status         numeric(18,0),   -- id trạng thái, nối với way4_contr_status.id
    production_status    varchar(1),      -- mã trạng thái sản xuất thẻ vật lý (phân biệt chữ hoa, chữ thường)
    auth_limit_amount    numeric(23,5),   -- hạn mức
    card_expire          varchar(4),      -- hạn in trên thẻ, dạng YYMM; '0000' = không có
    date_open            date,            -- ngày mở
    date_expire          date,            -- ngày hết hiệu lực trên Way4
    add_info_04          varchar(256),    -- thông tin nguồn phát hành (chuỗi tự do)
    tf_partition_date    date
);

-- Way4 APPL_PRODUCT: danh mục sản phẩm thẻ. Tên sản phẩm chứa PRIN (thẻ chính) hoặc SUPP (thẻ phụ).
-- Kiểu bảng __mnp
drop table if exists raw_eod.way4_appl_product__mnp;
create table raw_eod.way4_appl_product__mnp (
    id                   numeric(18,0),   -- id sản phẩm; lên interface thành prd_card_code
    internal_code        varchar(32),     -- mã nội bộ, thẻ tham chiếu sản phẩm bằng mã này
    name                 varchar(256),    -- tên sản phẩm
    appl_pr_group__id    numeric(18,0),   -- id nhóm sản phẩm, nối với way4_appl_pr_group.id
    amnd_state           varchar(1),      -- A = đang hiệu lực
    tf_partition_date    date
);

-- Way4 APPL_PR_GROUP: nhóm sản phẩm. Tên nhóm cho biết thẻ tín dụng (CREDIT) hay ghi nợ (DEBIT, ISSUING).
-- Kiểu bảng __s2 (SCD type 2): mỗi lần đổi sinh một dòng mới, hiệu lực từ
-- tf_created_at đến trước tf_updated_at
drop table if exists raw_eod.way4_appl_pr_group__s2;
create table raw_eod.way4_appl_pr_group__s2 (
    id                   numeric(18,0),
    name                 varchar(256),
    tf_created_at        timestamp,
    tf_updated_at        timestamp
);

-- Way4 CONTR_STATUS: danh mục trạng thái của thẻ / hợp đồng (id -> tên trạng thái).
-- Kiểu bảng __mnp
drop table if exists raw_eod.way4_contr_status__mnp;
create table raw_eod.way4_contr_status__mnp (
    id                   numeric(18,0),
    name                 varchar(64),     -- tên trạng thái, ví dụ Card OK, Card Closed
    amnd_state           varchar(1),      -- A = đang hiệu lực
    tf_partition_date    date
);

-- Interface sản phẩm L1 (nguồn phụ của layer 2), do prd_intf_dag nạp mỗi ngày; ở môi
-- trường dev bảng được nạp sẵn dữ liệu.
-- Dòng của Way4 có src_sys_code = 'WAY4_APPL_PRODUCT'; prd_name là tên sản phẩm Way4 bỏ 4 ký tự đầu
-- (SUBSTRING(NAME, 5)), prd_group_name là tên nhóm sản phẩm.
-- Khóa: (business_date, uniq_id_in_src_sys, src_sys_code)
drop table if exists dwh_intf.prd_intf;
create table dwh_intf.prd_intf (
    business_date        date,
    src_sys_code         varchar(64),     -- hệ thống nguồn của sản phẩm
    uniq_id_in_src_sys   varchar(256),    -- id sản phẩm ở hệ thống nguồn (Way4: appl_product.id)
    prd_name             varchar(128),
    prd_group_name       varchar(64)
);

-- ---------------------------------------------------------------------------
-- Case 04 - Thẻ: bảng đích
-- ---------------------------------------------------------------------------
-- Model interface dùng materialized = incremental, on_schema_change = fail:
-- bảng phải có sẵn đúng cấu trúc, mỗi lần chạy chỉ xóa và nạp lại ngày đang chạy.
-- Thứ tự cột ở đây là thứ tự cột trong câu select của model.
-- Các bảng staging (stg_*__snp) dùng materialized = table nên không cần khai báo ở đây.
-- ---------------------------------------------------------------------------

-- Interface L1: mỗi dòng là một thẻ Way4 tại một business date
-- Khóa: (business_date, uniq_id_in_src_sys)
drop table if exists dwh_intf.card_intf;
create table dwh_intf.card_intf (
    business_date      date,
    ppn_date           timestamp,      -- thời điểm nạp
    card_nbr           varchar(64),    -- số thẻ đã che
    contract_nbr       varchar(64),    -- số hợp đồng thẻ mà thẻ thuộc về
    prd_card_code      varchar(64),    -- id sản phẩm thẻ trên Way4
    limit_amt          numeric(23,5),  -- hạn mức thẻ
    card_type          varchar(64),    -- CREDIT-CARD | DEBIT-CARD
    status_name        varchar(64),    -- tên trạng thái thẻ theo danh mục Way4
    card_status        varchar(128),   -- trạng thái sản xuất thẻ vật lý (READY, LOCKED...)
    prim_card_flag     varchar(10),    -- YES = thẻ chính, NO = không phải thẻ chính
    card_open_date     date,
    exp_date           date,           -- ngày cuối của tháng hết hạn in trên thẻ
    src_sys_code       varchar(64),    -- luôn là WAY4_ACNT_CONTRACT
    uniq_id_in_src_sys varchar(64),    -- id của thẻ trên Way4
    actual_end_date    date,           -- ngày hết hiệu lực trên Way4
    src_info           varchar(256)    -- thông tin nguồn phát hành
);

-- Bảng biến đổi của layer 2 (nằm ở schema ref của khối BI)
-- Khóa: (tf_partition_date, uniq_id_in_src_sys)
drop table if exists bi_ref.tfm_bi_card_info__mnp;
create table bi_ref.tfm_bi_card_info__mnp (
    uniq_id_in_src_sys varchar(64),
    card_nbr           varchar(64),
    card_status        varchar(64),
    card_limit_amt     numeric(23,5),
    card_open_date     date,
    originl_date_exp   varchar(6),
    actual_date_exp    date,
    card_prd_name      varchar(256),
    phys_card_status   varchar(64),
    bi_prd_type        varchar(64),
    bi_prd_group       varchar(64),
    tf_source_system   varchar(64),
    tf_etl_at          timestamp,
    tf_run_id          varchar(128),
    tf_partition_date  date,
    tf_sourcing_at     timestamp
);

-- Interface layer 2 của khối BI: lấy từ bảng tfm, mỗi dòng là một thẻ tại một ngày
-- Khóa: (tf_partition_date, uniq_id_in_src_sys)
drop table if exists bi_intf.bi_card_info_intf__mnp;
create table bi_intf.bi_card_info_intf__mnp (
    uniq_id_in_src_sys numeric(23,5),  -- id của thẻ trên Way4, interface ép sang kiểu số
    card_nbr           varchar(64),
    card_status        varchar(64),    -- = status_name của card_intf (tên trạng thái Way4)
    card_limit_amt     numeric(23,5),
    card_open_date     date,
    originl_date_exp   varchar(6),     -- tháng hết hạn in trên thẻ, dạng YYYYMM
    actual_date_exp    date,
    card_prd_name      varchar(256),   -- tên sản phẩm tra từ prd_intf
    phys_card_status   varchar(64),    -- = card_status của card_intf (trạng thái thẻ vật lý)
    bi_prd_type        varchar(64),    -- 01.Local Card | 02.International Card
    bi_prd_group       varchar(64),    -- 01.Credit Card | 02.Debit Card
    tf_source_system   varchar(64),
    tf_etl_at          timestamp,
    tf_run_id          varchar(128),
    tf_partition_date  date
);

