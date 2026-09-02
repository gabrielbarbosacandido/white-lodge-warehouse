{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
      dbt's default prefixes the target schema onto every custom schema, which
      would give main_bronze / main_silver / main_gold. The medallion layer names
      are the contract analysts query against, so they are used verbatim.
    -#}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
