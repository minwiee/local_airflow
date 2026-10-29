{% macro gen_tf_cols_by_table_type(table_type, src_sys_code) %}
{%- if table_type == 'mnp' -%}
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    NULL::TIMESTAMP AS TF_SOURCING_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{ var("business_date") }}' ::date as TF_PARTITION_DATE,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM
{%- elif table_type == 'snp'-%}
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    NULL::TIMESTAMP AS TF_SOURCING_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{ var("business_date") }}' ::date as TF_PARTITION_DATE,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM
{%- elif table_type == 's2'-%}
    {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }} AS TF_CREATED_AT,
    {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }} AS TF_UPDATED_AT ,
    1::SMALLINT as TF_RECORD_STATUS,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM
{%- elif table_type == 's4c'-%}
    {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }} AS TF_CREATED_AT,
    {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }} AS TF_UPDATED_AT ,
    1::SMALLINT as TF_RECORD_STATUS,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM
{%- elif table_type == 's4h'-%}
    {{ dbt_date.convert_timezone("current_timestamp", "Asia/Ho_Chi_Minh") }} AS TF_CREATED_AT,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM
{%- elif table_type == 'fa'-%}
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    NULL::TIMESTAMP AS TF_SOURCING_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM,
    '{{ var("business_date") }}' ::date as TF_PARTITION_DATE
{%- elif table_type == 'fu'-%}
    '{{ var("business_date") }}'::date AS TF_CREATED_AT,
    '{{ var("business_date") }}'::date AS TF_UPDATED_AT,
    1::SMALLINT as TF_RECORD_STATUS,
    '{{ run_started_at.astimezone(modules.pytz.timezone("Asia/Ho_Chi_Minh")) }}'::TIMESTAMP AS TF_ETL_AT,
    '{{ var("run_id") }}'::VARCHAR(128) AS TF_RUN_ID,
    '{{src_sys_code}}'::VARCHAR(64) TF_SOURCE_SYSTEM
{%- else -%}

{%- endif -%}
{% endmacro %}