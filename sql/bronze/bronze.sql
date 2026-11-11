create or refresh streaming table bronze_hotel_booking as 
select
    *,
    _metadata.file_path as source_file,
    current_timestamp() as loaded_at
from stream read_files(
    '/Volumes/hospitality_catalog/bookings/raw_files',
    format => 'csv',
    header => true
);
