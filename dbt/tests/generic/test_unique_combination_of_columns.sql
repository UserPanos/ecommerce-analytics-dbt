{% test unique_combination_of_columns (model, columns) %}

SELECT
    {{ columns | join (', ') }},
    count(*)
from {{ model }}
group by
    {{ columns | join (', ') }}
having count(*) > 1

{% endtest %}