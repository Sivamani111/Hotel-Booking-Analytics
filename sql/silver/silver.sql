-- ==========================================
-- SILVER LAYER: CLEAN BOOKINGS
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_clean AS

WITH ranked_bookings AS (

    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY booking_id
            ORDER BY loaded_at DESC
        ) AS rn
    FROM bronze_hotel_booking

),

cleaned AS (

    SELECT
        booking_id,

        NULLIF(TRIM(guest_id), '') AS guest_id,

        booking_date,
        check_in_date,
        check_out_date,

        COALESCE(
            nights,
            DATEDIFF(check_out_date, check_in_date)
        ) AS nights,

        INITCAP(TRIM(hotel_name)) AS hotel_name,

        COALESCE(
            NULLIF(INITCAP(TRIM(city)), ''),
            'Unknown'
        ) AS city,

        INITCAP(TRIM(region)) AS region,

        INITCAP(TRIM(room_type)) AS room_type,

        COALESCE(
            NULLIF(INITCAP(TRIM(booking_channel)), ''),
            'Unknown'
        ) AS booking_channel,

        guests,
        room_rate,

        COALESCE(
            total_amount,
            COALESCE(
                nights,
                DATEDIFF(check_out_date, check_in_date)
            ) * room_rate
        ) AS total_amount,

        discount_amount,

        NULLIF(INITCAP(TRIM(meal_plan)), '') AS meal_plan,

        NULLIF(INITCAP(TRIM(payment_method)), '') AS payment_method,

        NULLIF(INITCAP(TRIM(payment_status)), '') AS payment_status,

        INITCAP(TRIM(booking_status)) AS booking_status,

        guest_rating

    FROM ranked_bookings
    WHERE rn = 1
)

SELECT *
FROM cleaned
WHERE check_out_date > check_in_date
  AND room_rate >= 0;


-- ==========================================
-- SILVER LAYER: REJECTED BOOKINGS
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_rejected AS

SELECT *,
    CASE
        WHEN check_out_date <= check_in_date
            THEN 'Invalid stay dates'

        WHEN room_rate < 0
            THEN 'Negative room rate'
    END AS reject_reason

FROM bronze_hotel_booking

WHERE check_out_date <= check_in_date
   OR room_rate < 0;
