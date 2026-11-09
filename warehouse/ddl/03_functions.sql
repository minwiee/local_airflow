-- ---------------------------------------------------------------------------
-- DWH - hàm dùng chung của dự án
-- ---------------------------------------------------------------------------
-- PostgreSQL không có sẵn hàm tính số tháng giữa hai ngày và hàm lấy ngày cuối tháng,
-- nên dự án tự định nghĩa hai hàm dưới đây trong schema public:
--   public.months_between(d1 date, d2 date)  số tháng từ d2 đến d1, có phần lẻ
--   public.last_day(d date)                  ngày cuối tháng của d
-- Model và test QA gọi hàm kèm tên schema: public.months_between(...), public.last_day(...).
-- Database kho dữ liệu ở SIT và production có sẵn hai hàm với cùng định nghĩa; ở dev,
-- run_all.ps1 tạo chúng khi dựng môi trường. Chạy lại file này nhiều lần vẫn an toàn.
-- ---------------------------------------------------------------------------
set client_encoding to 'UTF8';

-- Số tháng từ d2 đến d1: nếu hai ngày cùng "ngày trong tháng" hoặc cùng là ngày cuối
-- tháng thì ra số nguyên; nếu không, phần lẻ = chênh lệch ngày / 31.
-- Ví dụ: public.months_between('2027-03-31', '2026-09-30') = 6
--        public.months_between('2026-10-15', '2026-09-30') = 1 + (15 - 30) / 31 = 0.516...
create or replace function public.months_between(d1 date, d2 date)
returns numeric
language sql
immutable
as $fn$
    select ((extract(year from d1) - extract(year from d2)) * 12
            + (extract(month from d1) - extract(month from d2)))::numeric
         + case
               when extract(day from d1) = extract(day from d2) then 0
               when d1 = (date_trunc('month', d1) + interval '1 month - 1 day')::date
                and d2 = (date_trunc('month', d2) + interval '1 month - 1 day')::date then 0
               else (extract(day from d1) - extract(day from d2))::numeric / 31
           end
$fn$;

-- Ngày cuối tháng của một ngày. Ví dụ: public.last_day('2028-02-10') = 2028-02-29
create or replace function public.last_day(d date)
returns date
language sql
immutable
as $fn$
    select (date_trunc('month', d) + interval '1 month - 1 day')::date
$fn$;
