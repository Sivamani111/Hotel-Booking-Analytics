
-- ==========================================
-- GOLD 1: MONTHLY BOOKINGS SUMMARY
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_bookings AS

SELECT
    DATE_FORMAT(booking_date, 'yyyy-MM') AS booking_month,

    COUNT(*) AS total_bookings,

    COUNT_IF(booking_status = 'Cancelled') AS cancelled_bookings,

    SUM(
        CASE
            WHEN booking_status = 'Completed' THEN nights
            ELSE 0
        END
    ) AS room_nights,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN total_amount - COALESCE(discount_amount, 0)
            ELSE 0
        END
    ) AS net_revenue

FROM silver_bookings_clean
GROUP BY DATE_FORMAT(booking_date, 'yyyy-MM');


-- ==========================================
-- GOLD 2: HOTEL SUMMARY
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW gold_hotel_summary AS

SELECT
    region,
    city,
    hotel_name,

    COUNT(*) AS total_bookings,

    SUM(
        CASE
            WHEN booking_status = 'Completed' THEN nights
            ELSE 0
        END
    ) AS room_nights,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN total_amount - COALESCE(discount_amount, 0)
            ELSE 0
        END
    ) AS net_revenue,

    ROUND(
        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN total_amount - COALESCE(discount_amount, 0)
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN booking_status = 'Completed' THEN nights
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS avg_daily_rate

FROM silver_bookings_clean
GROUP BY region, city, hotel_name;


-- ==========================================
-- GOLD 3: ROOM TYPE SUMMARY
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW gold_room_type_summary AS

SELECT
    room_type,

    COUNT(*) AS total_bookings,

    SUM(
        CASE
            WHEN booking_status = 'Completed' THEN nights
            ELSE 0
        END
    ) AS room_nights,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN total_amount - COALESCE(discount_amount, 0)
            ELSE 0
        END
    ) AS net_revenue,

    ROUND(AVG(guest_rating), 2) AS avg_rating

FROM silver_bookings_clean
GROUP BY room_type;


-- ==========================================
-- GOLD 4: BOOKING CHANNEL SUMMARY
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW gold_channel_summary AS

SELECT
    booking_channel,

    COUNT(*) AS total_bookings,

    COUNT_IF(booking_status = 'Cancelled') AS cancelled_bookings,

    ROUND(
        COUNT_IF(booking_status = 'Cancelled') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN total_amount - COALESCE(discount_amount, 0)
            ELSE 0
        END
    ) AS net_revenue

FROM silver_bookings_clean
GROUP BY booking_channel;


-- ==========================================
-- GOLD 5: DATA QUALITY SUMMARY
-- ==========================================

CREATE OR REFRESH MATERIALIZED VIEW gold_data_quality AS

SELECT
    (SELECT COUNT(*)
     FROM bronze_hotel_booking) AS bronze_rows,

    (SELECT COUNT(*) - COUNT(DISTINCT booking_id)
     FROM bronze_hotel_booking) AS duplicate_rows,

    (SELECT COUNT(*)
     FROM bronze_hotel_booking
     WHERE check_out_date <= check_in_date) AS invalid_date_rows,

    (SELECT COUNT(*)
     FROM bronze_hotel_booking
     WHERE city IS NULL OR TRIM(city) = '') AS missing_city_rows,

    (SELECT COUNT(*)
     FROM bronze_hotel_booking
     WHERE room_rate < 0) AS negative_rate_rows,

    (SELECT COUNT(*)
     FROM bronze_hotel_booking
     WHERE booking_channel IS NULL
        OR TRIM(booking_channel) = '') AS missing_channel_rows,

    (SELECT COUNT(*)
     FROM bronze_hotel_booking
     WHERE total_amount IS NULL) AS missing_amount_rows,

    (SELECT COUNT(*)
     FROM bronze_hotel_booking
     WHERE nights IS NULL) AS missing_nights_rows,

    (SELECT COUNT(*)
     FROM silver_bookings_clean) AS clean_rows,

    (SELECT COUNT(*)
     FROM silver_bookings_rejected) AS rejected_rows;
