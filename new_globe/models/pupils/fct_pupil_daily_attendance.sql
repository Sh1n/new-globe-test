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
    PupilID as pupil_id,
    CASE WHEN Attendance = 'Present' THEN 1 ELSE 0 END AS is_present
FROM {{ source('pupils', 'pupil_attendance') }}
WHERE
    1 = 1

{% if is_incremental() %}
    AND date > (SELECT MAX(date) FROM {{ this }})
{% endif %}
