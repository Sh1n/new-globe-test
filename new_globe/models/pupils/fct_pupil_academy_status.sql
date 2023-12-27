{{
    config(
        materialized='incremental',
        partition_by={
            "field": "date",
            "data_type": "date",
            "granularity": "day"
        }
    )
}}

SELECT
    date,
    pupils.surrogate_key AS pupil_key,
    academies.surrogate_key AS academy_key,
    grades.surrogate_key AS grade_key,
    status
FROM {{ ref('stg_pupil_data') }}
JOIN {{ ref('dim_pupils') }} pupils USING(pupil_id)
JOIN {{ ref('dim_academies') }} academies USING(academy_name)
JOIN {{ ref('dim_grades') }} grades USING(grade_id)
WHERE
    1 = 1

{% if is_incremental() %}
    AND date > (SELECT MAX(date) FROM {{ this }})
{% endif %}
