{% macro futils_test_should_run(model_name, test_type) %}

{% set config_table = source('dwh_ref', 'raw_test_case_config') %}
{% set holiday_table = source('raw_eod_common', 'raw_t24_holiday') %}

(
    with cfg as (
        select
            is_enable,
            is_enable_holiday
        from {{ config_table }}
        where model_name = '{{ model_name }}'
          and test_type  = '{{ test_type }}'
          and is_active = true
        limit 1
    ),

    cal as (
        select
            case
                when max(case when is_holiday = 'H' then 1 else 0 end) = 1
                then true
                else false
            end as is_holiday
        from {{ holiday_table }}
        where mth_day_no = '{{ var("business_date") }}'::date
          and holiday_code like 'VN00%'
    )

    select
        case
            -- Không có config → default ON
            when not exists (select 1 from cfg) then true

            -- Có config nhưng is_enable = false
            when (select is_enable from cfg) = false then false

            -- enable = true và enable_holiday = true
            when (select is_enable_holiday from cfg) = true then true

            -- enable = true nhưng holiday thì skip
            when (select is_enable_holiday from cfg) = false
                 and (select is_holiday from cal) = true
                then false

            else true
        end
)

{% endmacro %}