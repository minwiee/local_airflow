{% test unique_value(model, column_name, filter_column) %}
with should_run as (
    select {{ futils_test_should_run(model.identifier, 'unique') }} as run_test
),
data as (
    select *
    from {{ model }}
    cross join should_run
    where should_run.run_test
      and {{ column_name }} is not null
    {% if filter_column %}
        and {{ filter_column }} = '{{ var("business_date") }}'::date
    {% endif %}
)
select
    {{ column_name }} as unique_field,
    count(1) as n_records
from data
group by {{ column_name }}
having count(1) > 1
{% endtest %}