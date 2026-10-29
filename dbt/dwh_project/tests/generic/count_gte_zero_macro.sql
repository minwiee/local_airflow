{% test count_gte_zero(model, filter_column) %}
with should_run as (
    select {{ futils_test_should_run(model.identifier, 'count_gte_zero') }} as run_test
),
cnt as (
    select count(*) as n_records from 
    (
        select 1 as n_records
        from {{ model }}
        where
            {% if not filter_column %}
                1 = 1
            {% else %}
                {{ filter_column }} = cast('{{ var("business_date") }}' as date)
            {% endif %}
        limit 1
    )x
)
select n_records
from cnt
cross join should_run
where
    should_run.run_test
    and n_records = 0
{% endtest %}