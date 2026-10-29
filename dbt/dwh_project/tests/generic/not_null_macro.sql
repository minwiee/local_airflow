{% test not_null_value(model, column_name, filter_column) %}
with should_run as (
    select {{ futils_test_should_run(model.identifier, 'not_null') }} as run_test
),
data as (
    select *
    from {{ model }}
    {% if filter_column %}
    where {{ filter_column }} = '{{ var("business_date") }}'::date
    {% endif %}
)
select
    {{ column_name }} as notnull_field
from data
cross join should_run
where
    should_run.run_test
    and {{ column_name }} is null
{% endtest %}