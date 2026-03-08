SELECT
    database,
    table,
    name AS column_name,
    type AS data_type,
    position,
    is_in_partition_key,
    is_in_sorting_key,
    is_in_primary_key,
    is_in_sampling_key,
    compression_codec,
    comment
FROM system.columns
WHERE database NOT IN ('system', 'information_schema', 'INFORMATION_SCHEMA')
ORDER BY database, table, position