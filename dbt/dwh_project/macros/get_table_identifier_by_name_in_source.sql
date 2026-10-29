{% macro get_table_identifiers(source_name, table_name) %}
    {% set table_full_identifier = source(source_name, table_name) | string %}
    {% set table_identifier = table_full_identifier.split('.')[2] %}
    {% set table_identifier = table_identifier | replace('"', '') %}
    {% set table_identifier = table_identifier | string %}
    {{ return( table_identifier ) }}
{% endmacro %}