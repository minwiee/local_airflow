{% macro get_data_date_for_table(tbls_data_date_dict, source_name, table_name) %}
    {% set table_identifier = get_table_identifiers(source_name, table_name) %}
    {# Check if the table_name exists in the dictionary #}
    {% if table_identifier in tbls_data_date_dict %}
        {{ return(tbls_data_date_dict[table_identifier]) }}
    {% else %}
        {# Handle case where table_name does not exist in the dictionary #}
        {{ return(var("business_date")) }}
    {% endif %}
{% endmacro %}