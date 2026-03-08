-- ClickHouse SQL dump
-- Database: manufacturing_dw
-- Generated at: 2026-03-07 19:07:55

CREATE DATABASE manufacturing_dw\nENGINE = Atomic\nCOMMENT \'Manufacturing data warehouse for production, inventory, procurement, quality, and shipments\';

CREATE TABLE manufacturing_dw.ai_business_synonyms\n(\n    `synonym` String COMMENT \'Word or phrase a user may type in natural language, such as factory, FG, vendor, or stock on hand\',\n    `canonical_term` String COMMENT \'Standard business term the synonym should map to, such as plant, finished_good, supplier, or inventory_on_hand\',\n    `term_type` String COMMENT \'Type of canonical term such as table, column, dimension, measure, kpi, filter_value, business_term, or abbreviation\',\n    `target_table` String COMMENT \'Primary physical table related to the canonical term; blank when not applicable\',\n    `target_column` String COMMENT \'Primary physical column related to the canonical term; blank when not applicable\',\n    `target_value` String COMMENT \'Suggested filter value or business value when the synonym refers to a specific coded meaning\',\n    `domain` String COMMENT \'Business domain such as inventory, production, procurement, quality, shipment, bom, or general\',\n    `confidence_score` Decimal(5, 2) COMMENT \'Confidence score from 0 to 1 indicating how strongly this synonym maps to the canonical term\',\n    `usage_note` String COMMENT \'Explanation for AI on how to use the mapping in SQL generation or business interpretation\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether this synonym is currently active and should be used by the AI\'\n)\nENGINE = MergeTree\nORDER BY (lower(synonym), term_type, target_table, target_column)\nSETTINGS index_granularity = 8192\nCOMMENT \'Business synonym and vocabulary mapping table used by AI to translate user language into manufacturing warehouse schema terms\';

CREATE TABLE manufacturing_dw.ai_example_questions\n(\n    `domain` String COMMENT \'Business domain such as inventory, procurement, production, quality, or shipment\',\n    `question_text` String COMMENT \'Natural-language question users may ask\',\n    `primary_table` String COMMENT \'Main table expected to answer the question\',\n    `related_tables` String COMMENT \'Comma-separated list of commonly joined supporting tables\',\n    `expected_grouping` String COMMENT \'Typical grouping or breakdown needed for the answer\',\n    `expected_filters` String COMMENT \'Typical date or business filters used in the question\',\n    `notes` String COMMENT \'Extra notes for AI prompt engineering and SQL generation\'\n)\nENGINE = MergeTree\nORDER BY (domain, primary_table)\nSETTINGS index_granularity = 8192;

CREATE TABLE manufacturing_dw.ai_sql_templates\n(\n    `template_name` String COMMENT \'Unique name of the SQL template\',\n    `template_category` String COMMENT \'Business category such as inventory, procurement, production, quality, shipment, bom, or general\',\n    `business_question` String COMMENT \'Natural-language business question this template is intended to answer\',\n    `intent_type` String COMMENT \'Intent type such as summary, trend, ranking, detail, root_cause, or lookup\',\n    `primary_table` String COMMENT \'Main fact or bridge table used by the template\',\n    `related_tables` String COMMENT \'Comma-separated list of dimension or supporting tables typically joined in the query\',\n    `primary_time_column` String COMMENT \'Preferred time column to use for date filtering in this template\',\n    `grain_description` String COMMENT \'Business grain expected before aggregation\',\n    `required_filters` String COMMENT \'Comma-separated list of filters that should usually be applied\',\n    `optional_filters` String COMMENT \'Comma-separated list of optional filters commonly used with the template\',\n    `grouping_columns` String COMMENT \'Comma-separated list of typical grouping columns for the query\',\n    `measure_logic` String COMMENT \'Description of the aggregation or KPI logic used in the query\',\n    `sql_template` String COMMENT \'Parameterized SQL template for AI-generated queries\',\n    `result_notes` String COMMENT \'Guidance on interpreting the output of the query\',\n    `caveats` String COMMENT \'Warnings about grain, snapshot logic, or business interpretation\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the template is active and approved for AI use\'\n)\nENGINE = MergeTree\nORDER BY (template_category, template_name)\nSETTINGS index_granularity = 8192\nCOMMENT \'Approved SQL template library for AI-generated analytics queries in the manufacturing warehouse\';

CREATE TABLE manufacturing_dw.bom_component\n(\n    `parent_product_key` UInt32 COMMENT \'Foreign key to dim_product for the parent assembly or finished good\',\n    `component_product_key` UInt32 COMMENT \'Foreign key to dim_product for the child component or raw material\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant where this bill of material is valid\',\n    `bom_version` String COMMENT \'Version identifier of the bill of material\',\n    `component_quantity` Decimal(18, 4) COMMENT \'Required component quantity to produce one base quantity of the parent product\',\n    `component_uom` String COMMENT \'Unit of measure of the component quantity\',\n    `scrap_factor_pct` Decimal(9, 4) COMMENT \'Expected scrap percentage for the component in the manufacturing process\',\n    `valid_from` Date COMMENT \'Date from which the BOM component row is valid\',\n    `valid_to` Date COMMENT \'Date until which the BOM component row is valid\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this BOM row is currently active\'\n)\nENGINE = MergeTree\nORDER BY (parent_product_key, component_product_key, plant_key, bom_version, valid_from)\nSETTINGS index_granularity = 8192\nCOMMENT \'Bridge table representing the bill of materials between parent products and component products\';

CREATE TABLE manufacturing_dw.dim_customer\n(\n    `customer_key` UInt32 COMMENT \'Surrogate key for the customer dimension\',\n    `customer_id` String COMMENT \'Business identifier of the customer from ERP or CRM\',\n    `customer_name` String COMMENT \'Customer legal or trading name\',\n    `customer_segment` String COMMENT \'Business segment of the customer such as retail, industrial, or distributor\',\n    `country` String COMMENT \'Customer country\',\n    `region` String COMMENT \'Customer sales region\',\n    `channel` String COMMENT \'Sales channel such as direct, distributor, e-commerce, or OEM\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the customer is active\',\n    `valid_from` Date COMMENT \'Start date when this dimension row became valid\',\n    `valid_to` Date COMMENT \'End date when this dimension row stopped being valid\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this is the current active version of the dimension row\'\n)\nENGINE = MergeTree\nORDER BY customer_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Dimension table with customer master data for outbound shipments\';

CREATE TABLE manufacturing_dw.dim_date\n(\n    `date_key` UInt32 COMMENT \'Integer date key in YYYYMMDD format\',\n    `full_date` Date COMMENT \'Calendar date\',\n    `year` UInt16 COMMENT \'Calendar year number\',\n    `quarter` UInt8 COMMENT \'Calendar quarter number from 1 to 4\',\n    `month` UInt8 COMMENT \'Calendar month number from 1 to 12\',\n    `month_name` String COMMENT \'Calendar month name\',\n    `week_of_year` UInt8 COMMENT \'ISO week number within the year\',\n    `day_of_month` UInt8 COMMENT \'Day number within the month\',\n    `day_of_week` UInt8 COMMENT \'Day number within the week where Monday is 1 and Sunday is 7\',\n    `day_name` String COMMENT \'Calendar day name\',\n    `is_weekend` UInt8 COMMENT \'Flag indicating whether the date falls on a weekend\'\n)\nENGINE = MergeTree\nORDER BY date_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Calendar date dimension used for reporting and time-based analysis\';

CREATE TABLE manufacturing_dw.dim_plant\n(\n    `plant_key` UInt32 COMMENT \'Surrogate key for the plant dimension\',\n    `plant_id` String COMMENT \'Business identifier of the plant from the source ERP or MES system\',\n    `plant_name` String COMMENT \'Human-readable name of the manufacturing plant\',\n    `country` String COMMENT \'Country where the plant is located\',\n    `state_region` String COMMENT \'State, province, or region of the plant\',\n    `city` String COMMENT \'City where the plant is located\',\n    `timezone` String COMMENT \'Local timezone used by the plant for operations and reporting\',\n    `plant_type` String COMMENT \'Type of plant such as assembly, fabrication, packaging, or distribution\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the plant is currently active; 1 means active, 0 means inactive\',\n    `valid_from` Date COMMENT \'Start date when this dimension row became valid\',\n    `valid_to` Date COMMENT \'End date when this dimension row stopped being valid; use a far-future date for current row\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this is the current active version of the dimension row\'\n)\nENGINE = MergeTree\nORDER BY plant_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Dimension table with descriptive information about manufacturing plants\';

CREATE TABLE manufacturing_dw.dim_product\n(\n    `product_key` UInt32 COMMENT \'Surrogate key for the product dimension\',\n    `product_id` String COMMENT \'Business identifier of the product, item, or material from ERP or PLM\',\n    `product_name` String COMMENT \'Human-readable name of the product or material\',\n    `product_type` String COMMENT \'Type of item such as raw_material, component, subassembly, finished_good, or consumable\',\n    `product_family` String COMMENT \'Higher-level grouping used for analytics and reporting\',\n    `product_category` String COMMENT \'Category used by business stakeholders for planning and reporting\',\n    `base_uom` String COMMENT \'Base unit of measure used for inventory and costing\',\n    `standard_cost` Decimal(18, 4) COMMENT \'Standard cost per base unit\',\n    `standard_price` Decimal(18, 4) COMMENT \'Standard selling price per base unit where applicable\',\n    `weight_kg` Decimal(18, 4) COMMENT \'Weight of one base unit in kilograms\',\n    `shelf_life_days` UInt32 COMMENT \'Expected shelf life in days; 0 when shelf life is not applicable\',\n    `is_batch_tracked` UInt8 COMMENT \'Flag indicating whether the product is tracked by batch or lot\',\n    `is_serial_tracked` UInt8 COMMENT \'Flag indicating whether the product is tracked by serial number\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the product is active\',\n    `valid_from` Date COMMENT \'Start date when this dimension row became valid\',\n    `valid_to` Date COMMENT \'End date when this dimension row stopped being valid\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this is the current active version of the dimension row\'\n)\nENGINE = MergeTree\nORDER BY product_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Dimension table with product, material, and item master attributes\';

CREATE TABLE manufacturing_dw.dim_supplier\n(\n    `supplier_key` UInt32 COMMENT \'Surrogate key for the supplier dimension\',\n    `supplier_id` String COMMENT \'Business identifier of the supplier from the procurement or ERP system\',\n    `supplier_name` String COMMENT \'Supplier legal or trading name\',\n    `supplier_category` String COMMENT \'Supplier category such as raw_material, packaging, tooling, or logistics\',\n    `country` String COMMENT \'Country where the supplier is based\',\n    `lead_time_days` UInt16 COMMENT \'Standard supplier lead time in days for delivered materials\',\n    `payment_terms` String COMMENT \'Commercial payment terms agreed with the supplier\',\n    `quality_rating` Decimal(5, 2) COMMENT \'Internal quality score assigned to the supplier\',\n    `is_preferred` UInt8 COMMENT \'Flag indicating whether the supplier is preferred; 1 means preferred\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the supplier is active; 1 means active, 0 means inactive\',\n    `valid_from` Date COMMENT \'Start date when this dimension row became valid\',\n    `valid_to` Date COMMENT \'End date when this dimension row stopped being valid\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this is the current active version of the dimension row\'\n)\nENGINE = MergeTree\nORDER BY supplier_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Dimension table with supplier master data and sourcing attributes\';

CREATE TABLE manufacturing_dw.dim_warehouse\n(\n    `warehouse_key` UInt32 COMMENT \'Surrogate key for the warehouse dimension\',\n    `warehouse_id` String COMMENT \'Business identifier of the warehouse or storage location\',\n    `warehouse_name` String COMMENT \'Human-readable warehouse name\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant indicating which plant owns or uses the warehouse\',\n    `warehouse_type` String COMMENT \'Warehouse type such as raw_material, wip, finished_goods, spare_parts, or quarantine\',\n    `temperature_zone` String COMMENT \'Storage temperature category such as ambient, chilled, or frozen\',\n    `capacity_units` Decimal(18, 2) COMMENT \'Declared storage capacity in warehouse-defined units\',\n    `capacity_uom` String COMMENT \'Unit of measure for capacity such as pallets, bins, or cubic_meters\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the warehouse is active; 1 means active, 0 means inactive\',\n    `valid_from` Date COMMENT \'Start date when this dimension row became valid\',\n    `valid_to` Date COMMENT \'End date when this dimension row stopped being valid\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this is the current active version of the dimension row\'\n)\nENGINE = MergeTree\nORDER BY warehouse_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Dimension table with descriptive information about warehouses and storage areas\';

CREATE TABLE manufacturing_dw.dim_work_center\n(\n    `work_center_key` UInt32 COMMENT \'Surrogate key for the work center dimension\',\n    `work_center_id` String COMMENT \'Business identifier of the work center or machine group\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant indicating where the work center operates\',\n    `work_center_name` String COMMENT \'Human-readable name of the work center\',\n    `department_name` String COMMENT \'Department or production area responsible for the work center\',\n    `work_center_type` String COMMENT \'Type of work center such as machining, welding, assembly, paint, or packaging\',\n    `capacity_hours_per_day` Decimal(10, 2) COMMENT \'Nominal available production hours per day\',\n    `is_bottleneck` UInt8 COMMENT \'Flag indicating whether the work center is considered a production bottleneck\',\n    `is_active` UInt8 COMMENT \'Flag indicating whether the work center is active\',\n    `valid_from` Date COMMENT \'Start date when this dimension row became valid\',\n    `valid_to` Date COMMENT \'End date when this dimension row stopped being valid\',\n    `is_current` UInt8 COMMENT \'Flag indicating whether this is the current active version of the dimension row\'\n)\nENGINE = MergeTree\nORDER BY work_center_key\nSETTINGS index_granularity = 8192\nCOMMENT \'Dimension table with work center and machine group attributes\';

CREATE TABLE manufacturing_dw.fact_inventory_snapshot\n(\n    `snapshot_ts` DateTime COMMENT \'Timestamp when the inventory snapshot was taken\',\n    `date_key` UInt32 COMMENT \'Foreign key to dim_date for the snapshot date\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant for the plant holding the stock\',\n    `warehouse_key` UInt32 COMMENT \'Foreign key to dim_warehouse for the storage location\',\n    `product_key` UInt32 COMMENT \'Foreign key to dim_product for the stocked item\',\n    `batch_number` String COMMENT \'Batch or lot identifier when batch tracking is enabled\',\n    `quantity_on_hand` Decimal(18, 4) COMMENT \'Physical quantity currently on hand\',\n    `quantity_reserved` Decimal(18, 4) COMMENT \'Quantity reserved for production or customer demand\',\n    `quantity_available` Decimal(18, 4) COMMENT \'Quantity available for use after reservations\',\n    `inventory_uom` String COMMENT \'Unit of measure of the inventory quantities\',\n    `inventory_value` Decimal(18, 4) COMMENT \'Extended inventory value for the available stock according to costing rules\'\n)\nENGINE = MergeTree\nPARTITION BY toYYYYMM(snapshot_ts)\nORDER BY (snapshot_ts, plant_key, warehouse_key, product_key, batch_number)\nSETTINGS index_granularity = 8192\nCOMMENT \'Snapshot fact table with inventory balances by time, plant, warehouse, product, and batch\';

CREATE TABLE manufacturing_dw.fact_material_receipt\n(\n    `receipt_id` String COMMENT \'Unique identifier for the material receipt transaction\',\n    `receipt_ts` DateTime COMMENT \'Timestamp when the receipt was posted\',\n    `date_key` UInt32 COMMENT \'Foreign key to dim_date for the receipt date\',\n    `supplier_key` UInt32 COMMENT \'Foreign key to dim_supplier for the supplier that delivered the material\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant for the receiving plant\',\n    `warehouse_key` UInt32 COMMENT \'Foreign key to dim_warehouse for the receiving storage location\',\n    `product_key` UInt32 COMMENT \'Foreign key to dim_product for the received item\',\n    `purchase_order_number` String COMMENT \'Purchase order number associated with the receipt\',\n    `purchase_order_line` UInt32 COMMENT \'Purchase order line number associated with the receipt\',\n    `batch_number` String COMMENT \'Supplier or internal batch number assigned to the received lot\',\n    `quantity_received` Decimal(18, 4) COMMENT \'Quantity physically received\',\n    `quantity_accepted` Decimal(18, 4) COMMENT \'Quantity accepted after inspection\',\n    `quantity_rejected` Decimal(18, 4) COMMENT \'Quantity rejected during receipt or inspection\',\n    `receipt_uom` String COMMENT \'Unit of measure of the receipt quantities\',\n    `unit_cost` Decimal(18, 4) COMMENT \'Unit cost recorded at receipt\',\n    `total_cost` Decimal(18, 4) COMMENT \'Extended total receipt cost\'\n)\nENGINE = MergeTree\nPARTITION BY toYYYYMM(receipt_ts)\nORDER BY (receipt_ts, plant_key, warehouse_key, supplier_key, product_key, receipt_id)\nSETTINGS index_granularity = 8192\nCOMMENT \'Transactional fact table with inbound supplier receipts and receiving quality outcomes\';

CREATE TABLE manufacturing_dw.fact_production_operation\n(\n    `production_order_id` String COMMENT \'Identifier of the production order this operation belongs to\',\n    `operation_sequence` UInt16 COMMENT \'Sequence number of the operation within the routing\',\n    `work_center_key` UInt32 COMMENT \'Foreign key to dim_work_center where the operation was executed\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant where the operation was executed\',\n    `product_key` UInt32 COMMENT \'Foreign key to dim_product being produced during the operation\',\n    `operation_name` String COMMENT \'Human-readable operation name such as cutting, welding, or assembly\',\n    `operation_status` String COMMENT \'Current status of the operation such as queued, running, completed, or failed\',\n    `setup_time_minutes` Decimal(12, 2) COMMENT \'Actual setup time consumed by the operation in minutes\',\n    `run_time_minutes` Decimal(12, 2) COMMENT \'Actual run time consumed by the operation in minutes\',\n    `downtime_minutes` Decimal(12, 2) COMMENT \'Downtime experienced during the operation in minutes\',\n    `labor_hours` Decimal(12, 2) COMMENT \'Direct labor hours charged to the operation\',\n    `machine_hours` Decimal(12, 2) COMMENT \'Machine hours charged to the operation\',\n    `good_quantity` Decimal(18, 4) COMMENT \'Quantity produced successfully by the operation\',\n    `scrap_quantity` Decimal(18, 4) COMMENT \'Quantity scrapped during the operation\',\n    `event_ts` DateTime COMMENT \'Timestamp representing the most important event time for this operation record\'\n)\nENGINE = MergeTree\nPARTITION BY toYYYYMM(event_ts)\nORDER BY (event_ts, production_order_id, operation_sequence)\nSETTINGS index_granularity = 8192\nCOMMENT \'Fact table with operation-level execution metrics such as runtime, downtime, and output\';

CREATE TABLE manufacturing_dw.fact_production_order\n(\n    `production_order_id` String COMMENT \'Unique identifier of the production order or work order\',\n    `order_status` String COMMENT \'Current status such as planned, released, in_progress, completed, or cancelled\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant where the order is produced\',\n    `product_key` UInt32 COMMENT \'Foreign key to dim_product for the finished good or assembly being produced\',\n    `planned_start_ts` DateTime COMMENT \'Planned start timestamp of the production order\',\n    `planned_end_ts` DateTime COMMENT \'Planned completion timestamp of the production order\',\n    `actual_start_ts` Nullable(DateTime) COMMENT \'Actual start timestamp when execution began\',\n    `actual_end_ts` Nullable(DateTime) COMMENT \'Actual completion timestamp when execution ended\',\n    `due_date_key` UInt32 COMMENT \'Foreign key to dim_date for the committed due date\',\n    `order_quantity` Decimal(18, 4) COMMENT \'Planned production quantity\',\n    `completed_quantity` Decimal(18, 4) COMMENT \'Quantity completed and reported as good output\',\n    `scrapped_quantity` Decimal(18, 4) COMMENT \'Quantity scrapped or lost during production\',\n    `order_uom` String COMMENT \'Unit of measure of order quantities\',\n    `standard_cost_total` Decimal(18, 4) COMMENT \'Expected standard total cost of the production order\',\n    `actual_cost_total` Decimal(18, 4) COMMENT \'Actual accumulated total cost of the production order\'\n)\nENGINE = MergeTree\nPARTITION BY toYYYYMM(planned_start_ts)\nORDER BY (plant_key, production_order_id)\nSETTINGS index_granularity = 8192\nCOMMENT \'Fact table with production order planning, execution, output, and cost metrics\';

CREATE TABLE manufacturing_dw.fact_quality_inspection\n(\n    `inspection_id` String COMMENT \'Unique identifier of the quality inspection event\',\n    `inspection_ts` DateTime COMMENT \'Timestamp when the inspection occurred\',\n    `date_key` UInt32 COMMENT \'Foreign key to dim_date for the inspection date\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant where the inspection occurred\',\n    `product_key` UInt32 COMMENT \'Foreign key to dim_product being inspected\',\n    `supplier_key` UInt32 COMMENT \'Foreign key to dim_supplier when the inspection is related to incoming material; use 0 or unknown when not applicable\',\n    `production_order_id` String COMMENT \'Production order associated with the inspection when applicable\',\n    `batch_number` String COMMENT \'Batch or lot number being inspected\',\n    `inspection_type` String COMMENT \'Type of inspection such as incoming, in_process, final, or audit\',\n    `defect_code` String COMMENT \'Defect code observed during inspection\',\n    `defect_description` String COMMENT \'Human-readable description of the observed defect\',\n    `inspected_quantity` Decimal(18, 4) COMMENT \'Total quantity inspected\',\n    `accepted_quantity` Decimal(18, 4) COMMENT \'Quantity accepted after inspection\',\n    `rejected_quantity` Decimal(18, 4) COMMENT \'Quantity rejected after inspection\',\n    `reworked_quantity` Decimal(18, 4) COMMENT \'Quantity sent to rework after inspection\',\n    `inspection_result` String COMMENT \'Overall result such as pass, fail, conditional_pass, or rework\'\n)\nENGINE = MergeTree\nPARTITION BY toYYYYMM(inspection_ts)\nORDER BY (inspection_ts, plant_key, product_key, inspection_id)\nSETTINGS index_granularity = 8192\nCOMMENT \'Fact table with incoming, in-process, and final quality inspection results\';

CREATE TABLE manufacturing_dw.fact_shipment\n(\n    `shipment_id` String COMMENT \'Unique identifier of the outbound shipment\',\n    `shipment_ts` DateTime COMMENT \'Timestamp when the shipment was posted or dispatched\',\n    `date_key` UInt32 COMMENT \'Foreign key to dim_date for the shipment date\',\n    `customer_key` UInt32 COMMENT \'Foreign key to dim_customer receiving the goods\',\n    `plant_key` UInt32 COMMENT \'Foreign key to dim_plant shipping the goods\',\n    `warehouse_key` UInt32 COMMENT \'Foreign key to dim_warehouse from which the goods were shipped\',\n    `product_key` UInt32 COMMENT \'Foreign key to dim_product being shipped\',\n    `sales_order_number` String COMMENT \'Sales order number associated with the shipment\',\n    `sales_order_line` UInt32 COMMENT \'Sales order line number associated with the shipment\',\n    `batch_number` String COMMENT \'Batch or lot number shipped when applicable\',\n    `shipped_quantity` Decimal(18, 4) COMMENT \'Quantity shipped to the customer\',\n    `shipment_uom` String COMMENT \'Unit of measure of the shipped quantity\',\n    `net_sales_amount` Decimal(18, 4) COMMENT \'Net sales amount recognized for the shipment excluding tax\',\n    `freight_amount` Decimal(18, 4) COMMENT \'Freight amount charged or allocated to the shipment\'\n)\nENGINE = MergeTree\nPARTITION BY toYYYYMM(shipment_ts)\nORDER BY (shipment_ts, customer_key, product_key, shipment_id)\nSETTINGS index_granularity = 8192\nCOMMENT \'Transactional fact table with outbound customer shipments and commercial amounts\';

CREATE TABLE manufacturing_dw.kpi_definitions\n(\n    `kpi_name` String COMMENT \'Business-friendly KPI name\',\n    `kpi_category` String COMMENT \'Category such as inventory, production, quality, procurement, or shipment\',\n    `source_table` String COMMENT \'Primary table used to calculate the KPI\',\n    `grain_note` String COMMENT \'Required grain or aggregation guidance before computing the KPI\',\n    `formula_sql` String COMMENT \'SQL expression or pseudo-SQL used to calculate the KPI\',\n    `numerator_definition` String COMMENT \'Business meaning of the numerator if applicable\',\n    `denominator_definition` String COMMENT \'Business meaning of the denominator if applicable\',\n    `unit_of_measure` String COMMENT \'Output unit such as percent, quantity, currency, hours, or ratio\',\n    `preferred_time_column` String COMMENT \'Recommended time column for trend analysis\',\n    `dimensions_supported` String COMMENT \'Comma-separated list of dimensions commonly used with this KPI\',\n    `filters_supported` String COMMENT \'Comma-separated list of recommended filters for this KPI\',\n    `interpretation` String COMMENT \'Human-readable explanation of what high or low values mean\',\n    `caveats` String COMMENT \'Warnings about data quality, grain mismatch, or interpretation limits\'\n)\nENGINE = MergeTree\nORDER BY (kpi_category, kpi_name)\nSETTINGS index_granularity = 8192;

CREATE TABLE manufacturing_dw.table_ai_context\n(\n    `database_name` String COMMENT \'Database that owns the table\',\n    `table_name` String COMMENT \'Physical table name\',\n    `table_role` String COMMENT \'High-level role of the table such as dimension, fact, bridge, metadata, or view\',\n    `business_grain` String COMMENT \'Lowest level of detail represented by one row in the table\',\n    `business_purpose` String COMMENT \'Business reason the table exists and how it should be used\',\n    `primary_time_column` String COMMENT \'Main timestamp or date column to use for time filtering; blank if not applicable\',\n    `default_dimensions` String COMMENT \'Comma-separated list of common dimension columns used for grouping and filtering\',\n    `default_measures` String COMMENT \'Comma-separated list of common numeric measures used for aggregations\',\n    `common_filters` String COMMENT \'Comma-separated list of recommended business filters for this table\',\n    `join_instructions` String COMMENT \'Human-readable guidance on how this table should be joined to related tables\',\n    `data_freshness_expectation` String COMMENT \'Expected refresh cadence such as realtime, hourly, daily, or snapshot\',\n    `ai_usage_notes` String COMMENT \'Extra instructions for AI tools on how to interpret or prioritize the table\'\n)\nENGINE = MergeTree\nORDER BY (database_name, table_name)\nSETTINGS index_granularity = 8192;

CREATE TABLE manufacturing_dw.table_descriptions\n(\n    `database_name` String COMMENT \'Database name that owns the table\',\n    `table_name` String COMMENT \'Physical table name\',\n    `table_description` String COMMENT \'Business description of the table and how it should be used by analytics or AI\'\n)\nENGINE = MergeTree\nORDER BY (database_name, table_name)\nSETTINGS index_granularity = 8192\nCOMMENT \'Registry table containing table-level business descriptions for the warehouse\';

CREATE VIEW manufacturing_dw.v_ai_business_synonyms\n(\n    `synonym` String,\n    `canonical_term` String,\n    `term_type` String,\n    `target_table` String,\n    `target_column` String,\n    `target_value` String,\n    `domain` String,\n    `confidence_score` Decimal(5, 2),\n    `usage_note` String,\n    `is_active` UInt8\n)\nAS SELECT\n    synonym,\n    canonical_term,\n    term_type,\n    target_table,\n    target_column,\n    target_value,\n    domain,\n    confidence_score,\n    usage_note,\n    is_active\nFROM manufacturing_dw.ai_business_synonyms\nWHERE is_active = 1;

CREATE VIEW manufacturing_dw.v_ai_questions\n(\n    `domain` String,\n    `question_text` String,\n    `primary_table` String,\n    `related_tables` String,\n    `expected_grouping` String,\n    `expected_filters` String,\n    `notes` String\n)\nAS SELECT *\nFROM manufacturing_dw.ai_example_questions\nORDER BY\n    domain ASC,\n    question_text ASC;

CREATE VIEW manufacturing_dw.v_ai_semantic_catalog\n(\n    `database_name` String,\n    `table_name` String,\n    `native_table_comment` String,\n    `table_description` String,\n    `table_role` String,\n    `business_grain` String,\n    `business_purpose` String,\n    `primary_time_column` String,\n    `default_dimensions` String,\n    `default_measures` String,\n    `common_filters` String,\n    `join_instructions` String,\n    `data_freshness_expectation` String,\n    `ai_usage_notes` String,\n    `column_position` UInt64,\n    `column_name` String,\n    `column_type` String,\n    `column_description` String\n)\nAS SELECT\n    c.database AS database_name,\n    c.`table` AS table_name,\n    t.comment AS native_table_comment,\n    td.table_description,\n    a.table_role,\n    a.business_grain,\n    a.business_purpose,\n    a.primary_time_column,\n    a.default_dimensions,\n    a.default_measures,\n    a.common_filters,\n    a.join_instructions,\n    a.data_freshness_expectation,\n    a.ai_usage_notes,\n    c.position AS column_position,\n    c.name AS column_name,\n    c.type AS column_type,\n    c.comment AS column_description\nFROM system.columns AS c\nLEFT JOIN system.tables AS t ON (c.database = t.database) AND (c.`table` = t.name)\nLEFT JOIN manufacturing_dw.table_descriptions AS td ON (c.database = td.database_name) AND (c.`table` = td.table_name)\nLEFT JOIN manufacturing_dw.table_ai_context AS a ON (c.database = a.database_name) AND (c.`table` = a.table_name)\nWHERE c.database = \'manufacturing_dw\'\nORDER BY\n    c.`table` ASC,\n    c.position ASC;

CREATE VIEW manufacturing_dw.v_ai_sql_templates\n(\n    `template_name` String,\n    `template_category` String,\n    `business_question` String,\n    `intent_type` String,\n    `primary_table` String,\n    `related_tables` String,\n    `primary_time_column` String,\n    `grain_description` String,\n    `required_filters` String,\n    `optional_filters` String,\n    `grouping_columns` String,\n    `measure_logic` String,\n    `sql_template` String,\n    `result_notes` String,\n    `caveats` String,\n    `is_active` UInt8\n)\nAS SELECT\n    template_name,\n    template_category,\n    business_question,\n    intent_type,\n    primary_table,\n    related_tables,\n    primary_time_column,\n    grain_description,\n    required_filters,\n    optional_filters,\n    grouping_columns,\n    measure_logic,\n    sql_template,\n    result_notes,\n    caveats,\n    is_active\nFROM manufacturing_dw.ai_sql_templates\nWHERE is_active = 1;

CREATE VIEW manufacturing_dw.v_ai_sql_templates_summary\n(\n    `template_category` String,\n    `template_name` String,\n    `business_question` String,\n    `intent_type` String,\n    `primary_table` String,\n    `primary_time_column` String,\n    `grouping_columns` String,\n    `measure_logic` String\n)\nAS SELECT\n    template_category,\n    template_name,\n    business_question,\n    intent_type,\n    primary_table,\n    primary_time_column,\n    grouping_columns,\n    measure_logic\nFROM manufacturing_dw.ai_sql_templates\nWHERE is_active = 1\nORDER BY\n    template_category ASC,\n    template_name ASC;

CREATE VIEW manufacturing_dw.v_ai_synonyms_by_column\n(\n    `target_table` String,\n    `target_column` String,\n    `synonyms` Array(String),\n    `canonical_terms` Array(String)\n)\nAS SELECT\n    target_table,\n    target_column,\n    groupArray(synonym) AS synonyms,\n    groupArray(canonical_term) AS canonical_terms\nFROM manufacturing_dw.ai_business_synonyms\nWHERE (is_active = 1) AND (target_table != \'\') AND (target_column != \'\')\nGROUP BY\n    target_table,\n    target_column;

CREATE VIEW manufacturing_dw.v_ai_synonyms_by_table\n(\n    `target_table` String,\n    `synonyms` Array(String),\n    `canonical_terms` Array(String)\n)\nAS SELECT\n    target_table,\n    groupArray(synonym) AS synonyms,\n    groupArray(canonical_term) AS canonical_terms\nFROM manufacturing_dw.ai_business_synonyms\nWHERE (is_active = 1) AND (target_table != \'\')\nGROUP BY target_table;

CREATE VIEW manufacturing_dw.v_ai_vocabulary_catalog\n(\n    `synonym` String,\n    `canonical_term` String,\n    `term_type` String,\n    `domain` String,\n    `target_table` String,\n    `target_column` String,\n    `target_value` String,\n    `confidence_score` Decimal(5, 2),\n    `usage_note` String,\n    `table_role` String,\n    `business_grain` String,\n    `business_purpose` String,\n    `primary_time_column` String\n)\nAS SELECT\n    s.synonym,\n    s.canonical_term,\n    s.term_type,\n    s.domain,\n    s.target_table,\n    s.target_column,\n    s.target_value,\n    s.confidence_score,\n    s.usage_note,\n    tc.table_role,\n    tc.business_grain,\n    tc.business_purpose,\n    tc.primary_time_column\nFROM manufacturing_dw.ai_business_synonyms AS s\nLEFT JOIN manufacturing_dw.table_ai_context AS tc ON (s.target_table = tc.table_name) AND (tc.database_name = \'manufacturing_dw\')\nWHERE s.is_active = 1;

CREATE VIEW manufacturing_dw.v_data_dictionary\n(\n    `database_name` String,\n    `table_name` String,\n    `table_description` String,\n    `column_position` UInt64,\n    `column_name` String,\n    `column_type` String,\n    `column_description` String\n)\nAS SELECT\n    c.database AS database_name,\n    c.`table` AS table_name,\n    td.table_description,\n    c.position AS column_position,\n    c.name AS column_name,\n    c.type AS column_type,\n    c.comment AS column_description\nFROM system.columns AS c\nLEFT JOIN manufacturing_dw.table_descriptions AS td ON (c.database = td.database_name) AND (c.`table` = td.table_name)\nWHERE c.database = \'manufacturing_dw\'\nORDER BY\n    table_name ASC,\n    column_position ASC;

CREATE VIEW manufacturing_dw.v_kpi_catalog\n(\n    `kpi_name` String,\n    `kpi_category` String,\n    `source_table` String,\n    `grain_note` String,\n    `formula_sql` String,\n    `numerator_definition` String,\n    `denominator_definition` String,\n    `unit_of_measure` String,\n    `preferred_time_column` String,\n    `dimensions_supported` String,\n    `filters_supported` String,\n    `interpretation` String,\n    `caveats` String\n)\nAS SELECT *\nFROM manufacturing_dw.kpi_definitions\nORDER BY\n    kpi_category ASC,\n    kpi_name ASC;

CREATE VIEW manufacturing_dw.v_table_catalog\n(\n    `database_name` String,\n    `table_name` String,\n    `engine` String,\n    `native_table_comment` String,\n    `table_description` String,\n    `table_role` String,\n    `business_grain` String,\n    `business_purpose` String,\n    `primary_time_column` String,\n    `default_dimensions` String,\n    `default_measures` String,\n    `common_filters` String,\n    `join_instructions` String,\n    `data_freshness_expectation` String,\n    `ai_usage_notes` String\n)\nAS SELECT\n    t.database AS database_name,\n    t.name AS table_name,\n    t.engine,\n    t.comment AS native_table_comment,\n    td.table_description,\n    a.table_role,\n    a.business_grain,\n    a.business_purpose,\n    a.primary_time_column,\n    a.default_dimensions,\n    a.default_measures,\n    a.common_filters,\n    a.join_instructions,\n    a.data_freshness_expectation,\n    a.ai_usage_notes\nFROM system.tables AS t\nLEFT JOIN manufacturing_dw.table_descriptions AS td ON (t.database = td.database_name) AND (t.name = td.table_name)\nLEFT JOIN manufacturing_dw.table_ai_context AS a ON (t.database = a.database_name) AND (t.name = a.table_name)\nWHERE t.database = \'manufacturing_dw\'\nORDER BY t.name ASC;

INSERT INTO `manufacturing_dw`.`ai_business_synonyms` (`synonym`, `canonical_term`, `term_type`, `target_table`, `target_column`, `target_value`, `domain`, `confidence_score`, `usage_note`, `is_active`) VALUES
('acceptance rate', 'receipt_acceptance_rate', 'kpi', 'fact_material_receipt', '', '', 'procurement', 1.00, 'Acceptance rate should use the KPI definition for Receipt Acceptance Rate.', 1),
('accepted qty', 'quantity_accepted', 'measure', 'fact_material_receipt', 'quantity_accepted', '', 'procurement', 1.00, 'Accepted qty maps to quantity_accepted.', 1),
('available inventory', 'inventory_available', 'measure', 'fact_inventory_snapshot', 'quantity_available', '', 'inventory', 1.00, 'Available inventory maps to quantity_available.', 1),
('available stock', 'inventory_available', 'measure', 'fact_inventory_snapshot', 'quantity_available', '', 'inventory', 1.00, 'Available stock maps to quantity_available.', 1),
('batch', 'batch_number', 'column', 'fact_inventory_snapshot', 'batch_number', '', 'inventory', 1.00, 'Batch maps to batch_number.', 1),
('bill of materials', 'bill_of_materials', 'business_term', 'bom_component', '', '', 'bom', 1.00, 'Bill of materials maps to bom_component.', 1),
('blocked stock', 'inventory_reserved', 'measure', 'fact_inventory_snapshot', 'quantity_reserved', '', 'inventory', 0.65, 'Blocked stock may map to reserved stock depending on business usage.', 1),
('bom', 'bill_of_materials', 'business_term', 'bom_component', '', '', 'bom', 1.00, 'BOM means bill of materials.', 1),
('client', 'customer', 'dimension', 'dim_customer', '', '', 'shipment', 0.85, 'Client often maps to customer.', 1),
('completed qty', 'completed_quantity', 'measure', 'fact_production_order', 'completed_quantity', '', 'production', 1.00, 'Completed qty maps to completed_quantity.', 1),
('completion rate', 'production_completion_rate', 'kpi', 'fact_production_order', '', '', 'production', 1.00, 'Completion rate in production context maps to Production Completion Rate.', 1),
('cost variance', 'production_cost_variance', 'kpi', 'fact_production_order', '', '', 'production', 1.00, 'Cost variance maps to Production Cost Variance.', 1),
('customer', 'customer', 'dimension', 'dim_customer', '', '', 'shipment', 1.00, 'Canonical customer term.', 1),
('defect', 'defect_code', 'column', 'fact_quality_inspection', 'defect_code', '', 'quality', 0.95, 'Defect often maps to defect_code and defect_description.', 1),
('defect code', 'defect_code', 'column', 'fact_quality_inspection', 'defect_code', '', 'quality', 1.00, 'Defect code maps to defect_code.', 1),
('defect description', 'defect_description', 'column', 'fact_quality_inspection', 'defect_description', '', 'quality', 1.00, 'Defect description maps to defect_description.', 1),
('depot', 'warehouse', 'dimension', 'dim_warehouse', '', '', 'inventory', 0.75, 'Depot may map to warehouse depending on business usage.', 1),
('dispatch', 'shipment', 'table', 'fact_shipment', '', '', 'shipment', 0.95, 'Dispatch usually maps to shipment.', 1),
('downtime', 'downtime_minutes', 'measure', 'fact_production_operation', 'downtime_minutes', '', 'production', 1.00, 'Downtime maps to downtime_minutes.', 1),
('downtime rate', 'work_center_downtime_rate', 'kpi', 'fact_production_operation', '', '', 'production', 1.00, 'Downtime rate maps to Work Center Downtime Rate.', 1),
('facility', 'plant', 'dimension', 'dim_plant', '', '', 'general', 0.92, 'Facility should generally map to plant unless the question is specifically about warehouses.', 1),
('factory', 'plant', 'dimension', 'dim_plant', '', '', 'general', 1.00, 'Map user references to factory or site to the plant dimension and plant-based fact filtering.', 1),
('fg', 'finished_good', 'filter_value', 'dim_product', 'product_type', 'finished_good', 'general', 1.00, 'FG means finished_good and is usually used as a product_type filter.', 1),
('final inspection', 'final', 'filter_value', 'fact_quality_inspection', 'inspection_type', 'final', 'quality', 1.00, 'Final inspection should filter inspection_type = final.', 1),
('finished good', 'finished_good', 'filter_value', 'dim_product', 'product_type', 'finished_good', 'general', 1.00, 'Finished good maps to product_type = finished_good.', 1),
('finished goods', 'finished_good', 'filter_value', 'dim_product', 'product_type', 'finished_good', 'general', 1.00, 'Finished goods maps to product_type = finished_good.', 1),
('free stock', 'inventory_available', 'measure', 'fact_inventory_snapshot', 'quantity_available', '', 'inventory', 0.90, 'Free stock maps to quantity_available.', 1),
('freight', 'freight_amount', 'measure', 'fact_shipment', 'freight_amount', '', 'shipment', 1.00, 'Freight maps to freight_amount.', 1),
('freight per unit', 'average_freight_per_unit', 'kpi', 'fact_shipment', '', '', 'shipment', 1.00, 'Freight per unit maps to Average Freight per Unit KPI.', 1),
('good yield', 'good_yield', 'kpi', 'fact_quality_inspection', '', '', 'quality', 1.00, 'Good yield maps to Good Yield KPI.', 1),
('goods receipt', 'material_receipt', 'table', 'fact_material_receipt', '', '', 'procurement', 1.00, 'Goods receipt maps to fact_material_receipt.', 1),
('in process inspection', 'in_process', 'filter_value', 'fact_quality_inspection', 'inspection_type', 'in_process', 'quality', 1.00, 'In-process inspection should filter inspection_type = in_process.', 1),
('inbound receipt', 'material_receipt', 'table', 'fact_material_receipt', '', '', 'procurement', 0.98, 'Inbound receipt maps to fact_material_receipt.', 1),
('incoming inspection', 'incoming', 'filter_value', 'fact_quality_inspection', 'inspection_type', 'incoming', 'quality', 1.00, 'Incoming inspection should filter inspection_type = incoming.', 1),
('inspection', 'quality_inspection', 'table', 'fact_quality_inspection', '', '', 'quality', 1.00, 'Inspection maps to fact_quality_inspection.', 1),
('inventory on hand', 'inventory_on_hand', 'measure', 'fact_inventory_snapshot', 'quantity_on_hand', '', 'inventory', 1.00, 'Inventory on hand maps to quantity_on_hand.', 1),
('inventory value', 'inventory_value', 'measure', 'fact_inventory_snapshot', 'inventory_value', '', 'inventory', 1.00, 'Inventory value maps to inventory_value.', 1),
('item', 'product', 'dimension', 'dim_product', '', '', 'general', 0.95, 'Item generally maps to product master.', 1),
('labor hours', 'labor_hours', 'measure', 'fact_production_operation', 'labor_hours', '', 'production', 1.00, 'Labor hours maps to labor_hours.', 1),
('last 30 days', 'rolling_30_days', 'business_term', '', '', '', 'general', 1.00, 'Translate to rolling 30-day filter on the table primary time column.', 1),
('last 90 days', 'rolling_90_days', 'business_term', '', '', '', 'general', 1.00, 'Translate to rolling 90-day filter on the table primary time column.', 1),
('last month', 'previous_month', 'business_term', '', '', '', 'general', 0.95, 'Translate to previous month filter using the relevant time column.', 1),
('last quarter', 'previous_quarter', 'business_term', '', '', '', 'general', 0.95, 'Translate to previous quarter filter using the relevant time column.', 1),
('line', 'work_center', 'dimension', 'dim_work_center', '', '', 'production', 0.90, 'Production line may map to work center.', 1),
('lot', 'batch_number', 'column', 'fact_inventory_snapshot', 'batch_number', '', 'inventory', 0.95, 'Lot usually maps to batch_number.', 1),
('lot number', 'batch_number', 'column', 'fact_inventory_snapshot', 'batch_number', '', 'inventory', 1.00, 'Lot number maps to batch_number.', 1),
('machine', 'work_center', 'dimension', 'dim_work_center', '', '', 'production', 0.88, 'Machine often maps to work center in aggregated manufacturing reporting.', 1),
('machine hours', 'machine_hours', 'measure', 'fact_production_operation', 'machine_hours', '', 'production', 1.00, 'Machine hours maps to machine_hours.', 1),
('material', 'product', 'dimension', 'dim_product', '', '', 'general', 0.95, 'Material maps to product in the warehouse.', 1),
('net sales', 'net_sales_amount', 'measure', 'fact_shipment', 'net_sales_amount', '', 'shipment', 1.00, 'Net sales maps to net_sales_amount.', 1),
('on hand', 'inventory_on_hand', 'measure', 'fact_inventory_snapshot', 'quantity_on_hand', '', 'inventory', 0.95, 'On hand usually maps to quantity_on_hand.', 1),
('outbound', 'shipment', 'table', 'fact_shipment', '', '', 'shipment', 0.90, 'Outbound in logistics context usually maps to shipment.', 1),
('output', 'completed_quantity', 'measure', 'fact_production_order', 'completed_quantity', '', 'production', 0.92, 'Output often maps to completed_quantity at order level.', 1),
('part', 'product', 'dimension', 'dim_product', '', '', 'general', 0.92, 'Part usually maps to product.', 1),
('planned qty', 'order_quantity', 'measure', 'fact_production_order', 'order_quantity', '', 'production', 1.00, 'Planned qty maps to order_quantity.', 1),
('plant', 'plant', 'dimension', 'dim_plant', '', '', 'general', 1.00, 'Canonical plant term.', 1),
('po', 'purchase_order', 'business_term', 'fact_material_receipt', 'purchase_order_number', '', 'procurement', 0.98, 'PO means purchase order.', 1),
('product', 'product', 'dimension', 'dim_product', '', '', 'general', 1.00, 'Canonical product term.', 1),
('production line', 'work_center', 'dimension', 'dim_work_center', '', '', 'production', 0.95, 'Production line maps to work center.', 1),
('production order', 'production_order', 'business_term', 'fact_production_order', 'production_order_id', '', 'production', 1.00, 'Canonical production order term.', 1),
('purchase order', 'purchase_order', 'business_term', 'fact_material_receipt', 'purchase_order_number', '', 'procurement', 1.00, 'Purchase order maps to purchase_order_number.', 1),
('qc', 'quality_inspection', 'table', 'fact_quality_inspection', '', '', 'quality', 0.92, 'QC usually maps to quality inspection.', 1),
('quality check', 'quality_inspection', 'table', 'fact_quality_inspection', '', '', 'quality', 0.95, 'Quality check maps to fact_quality_inspection.', 1),
('raw material', 'raw_material', 'filter_value', 'dim_product', 'product_type', 'raw_material', 'general', 1.00, 'Raw material maps to product_type = raw_material.', 1),
('raw materials', 'raw_material', 'filter_value', 'dim_product', 'product_type', 'raw_material', 'general', 1.00, 'Raw materials maps to product_type = raw_material.', 1),
('receipts', 'material_receipt', 'table', 'fact_material_receipt', '', '', 'procurement', 0.95, 'Receipts typically map to fact_material_receipt.', 1),
('received qty', 'quantity_received', 'measure', 'fact_material_receipt', 'quantity_received', '', 'procurement', 1.00, 'Received qty maps to quantity_received.', 1),
('reject rate', 'reject_rate', 'kpi', 'fact_quality_inspection', '', '', 'quality', 0.92, 'In quality context reject rate maps to Reject Rate.', 1),
('rejected qty', 'quantity_rejected', 'measure', 'fact_material_receipt', 'quantity_rejected', '', 'procurement', 1.00, 'Rejected qty maps to quantity_rejected.', 1),
('rejection rate', 'receipt_rejection_rate', 'kpi', 'fact_material_receipt', '', '', 'procurement', 0.85, 'If the question is about suppliers or receipts, rejection rate usually means Receipt Rejection Rate.', 1),
('reserved stock', 'inventory_reserved', 'measure', 'fact_inventory_snapshot', 'quantity_reserved', '', 'inventory', 1.00, 'Reserved stock maps to quantity_reserved.', 1),
('rework rate', 'rework_rate', 'kpi', 'fact_quality_inspection', '', '', 'quality', 1.00, 'Rework rate maps to Rework Rate.', 1),
('rm', 'raw_material', 'filter_value', 'dim_product', 'product_type', 'raw_material', 'general', 1.00, 'RM means raw_material.', 1),
('run time', 'run_time_minutes', 'measure', 'fact_production_operation', 'run_time_minutes', '', 'production', 1.00, 'Run time maps to run_time_minutes.', 1),
('runtime', 'run_time_minutes', 'measure', 'fact_production_operation', 'run_time_minutes', '', 'production', 1.00, 'Runtime maps to run_time_minutes.', 1),
('sales order', 'sales_order', 'business_term', 'fact_shipment', 'sales_order_number', '', 'shipment', 1.00, 'Sales order maps to sales_order_number.', 1),
('scrap', 'scrapped_quantity', 'measure', 'fact_production_order', 'scrapped_quantity', '', 'production', 0.95, 'Scrap usually maps to scrapped_quantity or scrap_quantity depending on grain.', 1),
('scrap qty', 'scrapped_quantity', 'measure', 'fact_production_order', 'scrapped_quantity', '', 'production', 0.95, 'At order level scrap qty maps to scrapped_quantity.', 1),
('scrap quantity', 'scrapped_quantity', 'measure', 'fact_production_order', 'scrapped_quantity', '', 'production', 0.95, 'At order level scrap quantity maps to scrapped_quantity.', 1),
('scrap rate', 'production_scrap_rate', 'kpi', 'fact_production_order', '', '', 'production', 0.90, 'In production context scrap rate maps to Production Scrap Rate.', 1),
('setup time', 'setup_time_minutes', 'measure', 'fact_production_operation', 'setup_time_minutes', '', 'production', 1.00, 'Setup time maps to setup_time_minutes.', 1),
('shipment', 'shipment', 'table', 'fact_shipment', '', '', 'shipment', 1.00, 'Shipment maps to fact_shipment.', 1),
('shipment volume', 'shipment_volume', 'kpi', 'fact_shipment', '', '', 'shipment', 1.00, 'Shipment volume maps to Shipment Volume KPI.', 1),
('shipped qty', 'shipped_quantity', 'measure', 'fact_shipment', 'shipped_quantity', '', 'shipment', 1.00, 'Shipped qty maps to shipped_quantity.', 1),
('site', 'plant', 'dimension', 'dim_plant', '', '', 'general', 0.95, 'Site usually means plant in this warehouse.', 1),
('sku', 'product', 'dimension', 'dim_product', '', '', 'general', 0.90, 'SKU usually maps to product.', 1),
('so', 'sales_order', 'business_term', 'fact_shipment', 'sales_order_number', '', 'shipment', 0.98, 'SO means sales order.', 1),
('source vendor', 'supplier', 'dimension', 'dim_supplier', '', '', 'procurement', 0.90, 'Source vendor maps to supplier.', 1),
('stock', 'inventory_on_hand', 'measure', 'fact_inventory_snapshot', 'quantity_on_hand', '', 'inventory', 0.98, 'Stock usually means quantity_on_hand.', 1),
('stock on hand', 'inventory_on_hand', 'measure', 'fact_inventory_snapshot', 'quantity_on_hand', '', 'inventory', 1.00, 'Stock on hand maps to quantity_on_hand.', 1),
('stock value', 'inventory_value', 'measure', 'fact_inventory_snapshot', 'inventory_value', '', 'inventory', 0.98, 'Stock value maps to inventory_value.', 1),
('storage', 'warehouse', 'dimension', 'dim_warehouse', '', '', 'inventory', 0.90, 'Storage location usually maps to warehouse.', 1),
('storage location', 'warehouse', 'dimension', 'dim_warehouse', '', '', 'inventory', 1.00, 'Storage location maps to warehouse.', 1),
('supplier', 'supplier', 'dimension', 'dim_supplier', '', '', 'procurement', 1.00, 'Canonical supplier term.', 1),
('supplier rejection rate', 'receipt_rejection_rate', 'kpi', 'fact_material_receipt', '', '', 'procurement', 1.00, 'Supplier rejection rate maps to Receipt Rejection Rate.', 1),
('this month', 'current_month', 'business_term', '', '', '', 'general', 0.95, 'Translate to current month filter using the relevant time column.', 1),
('this quarter', 'current_quarter', 'business_term', '', '', '', 'general', 0.95, 'Translate to current quarter filter using the relevant time column.', 1),
('today', 'current_date', 'business_term', '', '', '', 'general', 0.90, 'Translate using current date functions in SQL.', 1),
('uom', 'unit_of_measure', 'business_term', '', '', '', 'general', 1.00, 'UOM means unit of measure.', 1),
('vendor', 'supplier', 'dimension', 'dim_supplier', '', '', 'procurement', 1.00, 'Vendor maps to supplier.', 1),
('warehouse', 'warehouse', 'dimension', 'dim_warehouse', '', '', 'inventory', 1.00, 'Canonical warehouse term.', 1),
('wip', 'wip', 'filter_value', 'dim_warehouse', 'warehouse_type', 'wip', 'production', 0.90, 'WIP often maps to warehouse_type = wip or product lifecycle context.', 1),
('wo', 'production_order', 'business_term', 'fact_production_order', 'production_order_id', '', 'production', 1.00, 'WO means production order or work order.', 1),
('work center', 'work_center', 'dimension', 'dim_work_center', '', '', 'production', 1.00, 'Canonical work center term.', 1),
('work in progress', 'wip', 'filter_value', 'dim_warehouse', 'warehouse_type', 'wip', 'production', 0.92, 'Work in progress often maps to WIP storage or WIP analysis context.', 1),
('work order', 'production_order', 'business_term', 'fact_production_order', 'production_order_id', '', 'production', 1.00, 'Work order maps to production_order_id.', 1),
('yield', 'good_yield', 'kpi', 'fact_quality_inspection', '', '', 'quality', 0.95, 'Yield in quality context maps to Good Yield.', 1);

INSERT INTO `manufacturing_dw`.`ai_example_questions` (`domain`, `question_text`, `primary_table`, `related_tables`, `expected_grouping`, `expected_filters`, `notes`) VALUES
('bom', 'What components are required to build each finished good?', 'bom_component', 'dim_product, dim_plant', 'parent product, component product', 'is_current = 1', 'Join dim_product twice: once for parent_product_key and once for component_product_key'),
('inventory', 'What is the current inventory available by plant and product?', 'fact_inventory_snapshot', 'dim_plant, dim_product', 'plant_name, product_name', 'latest snapshot', 'Use the latest snapshot_ts and sum quantity_available'),
('inventory', 'Which warehouses have the highest inventory value this month?', 'fact_inventory_snapshot', 'dim_warehouse, dim_product, dim_date', 'warehouse_name', 'current month', 'Use month filter on snapshot date and aggregate inventory_value carefully by snapshot rules'),
('procurement', 'Which suppliers have the highest rejection rate over the last 90 days?', 'fact_material_receipt', 'dim_supplier, dim_product, dim_date', 'supplier_name', 'last 90 days', 'Compute sum(quantity_rejected) / sum(quantity_received)'),
('production', 'Which work centers had the most downtime last month?', 'fact_production_operation', 'dim_work_center, dim_plant, dim_date', 'work_center_name, plant_name', 'last month', 'Aggregate downtime_minutes by work center'),
('production', 'What is the production completion rate by plant this quarter?', 'fact_production_order', 'dim_plant, dim_date, dim_product', 'plant_name', 'current quarter', 'Compute completion rate after aggregating order quantities'),
('quality', 'What are the top defect codes for finished goods this month?', 'fact_quality_inspection', 'dim_product, dim_plant, dim_date', 'defect_code, defect_description', 'current month, product_type = finished_good', 'Group by defect code and order by rejected quantity or inspection count'),
('shipment', 'Which customers received the highest shipped quantity last quarter?', 'fact_shipment', 'dim_customer, dim_product, dim_date', 'customer_name', 'last quarter', 'Aggregate shipped_quantity by customer');

INSERT INTO `manufacturing_dw`.`ai_sql_templates` (`template_name`, `template_category`, `business_question`, `intent_type`, `primary_table`, `related_tables`, `primary_time_column`, `grain_description`, `required_filters`, `optional_filters`, `grouping_columns`, `measure_logic`, `sql_template`, `result_notes`, `caveats`, `is_active`) VALUES
('bom_component_usage_by_parent', 'bom', 'How much of each component is used across parent products?', 'summary', 'bom_component', 'dim_product, dim_plant', 'valid_from', 'One row per parent product, component product, plant, BOM version, and validity range', 'is_current = 1', 'plant, bom_version', 'component_product_name', 'Use sum(component_quantity) grouped by component product', 'SELECT
        comp_pr.product_name AS component_product_name,
        sum(b.component_quantity) AS total_component_quantity
    FROM manufacturing_dw.bom_component b
    LEFT JOIN manufacturing_dw.dim_product comp_pr
        ON b.component_product_key = comp_pr.product_key
    WHERE b.is_current = 1
    GROUP BY comp_pr.product_name
    ORDER BY total_component_quantity DESC;', 'Useful for identifying heavily used components across the BOM structure.', 'This is structural usage, not actual consumption volume from production transactions.', 1),
('bom_explosion_current', 'bom', 'What components are required for each finished good?', 'detail', 'bom_component', 'dim_product, dim_plant', 'valid_from', 'One row per parent product, component product, plant, BOM version, and validity range', 'is_current = 1', 'plant, bom_version', 'parent_product_name, component_product_name', 'List component_quantity and component_uom by parent and component product', 'SELECT
        parent_pr.product_name AS parent_product_name,
        comp_pr.product_name AS component_product_name,
        b.component_quantity,
        b.component_uom,
        b.bom_version
    FROM manufacturing_dw.bom_component b
    LEFT JOIN manufacturing_dw.dim_product parent_pr
        ON b.parent_product_key = parent_pr.product_key
    LEFT JOIN manufacturing_dw.dim_product comp_pr
        ON b.component_product_key = comp_pr.product_key
    WHERE b.is_current = 1
    ORDER BY
        parent_product_name,
        component_product_name;', 'Useful for product structure lookup and material requirements logic.', 'Join dim_product twice: once for parent product and once for component product.', 1),
('bom_component_usage_by_parent', 'bom', 'How much of each component is used across parent products?', 'summary', 'bom_component', 'dim_product, dim_plant', 'valid_from', 'One row per parent product, component product, plant, BOM version, and validity range', 'is_current = 1', 'plant, bom_version', 'component_product_name', 'Use sum(component_quantity) grouped by component product', 'SELECT
        comp_pr.product_name AS component_product_name,
        sum(b.component_quantity) AS total_component_quantity
    FROM manufacturing_dw.bom_component b
    LEFT JOIN manufacturing_dw.dim_product comp_pr
        ON b.component_product_key = comp_pr.product_key
    WHERE b.is_current = 1
    GROUP BY comp_pr.product_name
    ORDER BY total_component_quantity DESC;', 'Useful for identifying heavily used components across the BOM structure.', 'This is structural usage, not actual consumption volume from production transactions.', 1),
('bom_explosion_current', 'bom', 'What components are required for each finished good?', 'detail', 'bom_component', 'dim_product, dim_plant', 'valid_from', 'One row per parent product, component product, plant, BOM version, and validity range', 'is_current = 1', 'plant, bom_version', 'parent_product_name, component_product_name', 'List component_quantity and component_uom by parent and component product', 'SELECT
        parent_pr.product_name AS parent_product_name,
        comp_pr.product_name AS component_product_name,
        b.component_quantity,
        b.component_uom,
        b.bom_version
    FROM manufacturing_dw.bom_component b
    LEFT JOIN manufacturing_dw.dim_product parent_pr
        ON b.parent_product_key = parent_pr.product_key
    LEFT JOIN manufacturing_dw.dim_product comp_pr
        ON b.component_product_key = comp_pr.product_key
    WHERE b.is_current = 1
    ORDER BY
        parent_product_name,
        component_product_name;', 'Useful for product structure lookup and material requirements logic.', 'Join dim_product twice: once for parent product and once for component product.', 1),
('inventory_current_by_plant_product', 'inventory', 'What is the current inventory available by plant and product?', 'summary', 'fact_inventory_snapshot', 'dim_plant, dim_product', 'snapshot_ts', 'One row per snapshot timestamp, plant, warehouse, product, and batch before aggregation', 'latest snapshot', 'plant, product, warehouse, batch', 'plant_name, product_name', 'Use sum(quantity_available) at the latest snapshot timestamp', 'WITH latest_snapshot AS (
        SELECT max(snapshot_ts) AS max_snapshot_ts
        FROM manufacturing_dw.fact_inventory_snapshot
    )
    SELECT
        p.plant_name,
        pr.product_name,
        sum(i.quantity_available) AS quantity_available
    FROM manufacturing_dw.fact_inventory_snapshot i
    INNER JOIN latest_snapshot ls
        ON i.snapshot_ts = ls.max_snapshot_ts
    LEFT JOIN manufacturing_dw.dim_plant p
        ON i.plant_key = p.plant_key
    LEFT JOIN manufacturing_dw.dim_product pr
        ON i.product_key = pr.product_key
    GROUP BY
        p.plant_name,
        pr.product_name
    ORDER BY
        p.plant_name,
        pr.product_name;', 'Use this for current-state inventory reporting by plant and product.', 'Do not sum across multiple snapshots for current inventory questions.', 1),
('inventory_current_by_plant_product', 'inventory', 'What is the current inventory available by plant and product?', 'summary', 'fact_inventory_snapshot', 'dim_plant, dim_product', 'snapshot_ts', 'One row per snapshot timestamp, plant, warehouse, product, and batch before aggregation', 'latest snapshot', 'plant, product, warehouse, batch', 'plant_name, product_name', 'Use sum(quantity_available) at the latest snapshot timestamp', 'WITH latest_snapshot AS (
        SELECT max(snapshot_ts) AS max_snapshot_ts
        FROM manufacturing_dw.fact_inventory_snapshot
    )
    SELECT
        p.plant_name,
        pr.product_name,
        sum(i.quantity_available) AS quantity_available
    FROM manufacturing_dw.fact_inventory_snapshot i
    INNER JOIN latest_snapshot ls
        ON i.snapshot_ts = ls.max_snapshot_ts
    LEFT JOIN manufacturing_dw.dim_plant p
        ON i.plant_key = p.plant_key
    LEFT JOIN manufacturing_dw.dim_product pr
        ON i.product_key = pr.product_key
    GROUP BY
        p.plant_name,
        pr.product_name
    ORDER BY
        p.plant_name,
        pr.product_name;', 'Use this for current-state inventory reporting by plant and product.', 'Do not sum across multiple snapshots for current inventory questions.', 1),
('inventory_trend_by_month', 'inventory', 'How has inventory on hand changed over time?', 'trend', 'fact_inventory_snapshot', 'dim_date, dim_plant, dim_product', 'snapshot_ts', 'One row per snapshot timestamp, plant, warehouse, product, and batch before aggregation', 'date range', 'plant, warehouse, product', 'snapshot_month', 'Use sum(quantity_on_hand) by snapshot month', 'SELECT
        toStartOfMonth(snapshot_ts) AS snapshot_month,
        sum(quantity_on_hand) AS quantity_on_hand
    FROM manufacturing_dw.fact_inventory_snapshot
    WHERE snapshot_ts >= {start_date}
      AND snapshot_ts < {end_date}
    GROUP BY snapshot_month
    ORDER BY snapshot_month;', 'Use this for month-over-month inventory movement trends.', 'If snapshots are more frequent than daily, results show month-end-style aggregated snapshot totals, not transactional movement.', 1),
('inventory_trend_by_month', 'inventory', 'How has inventory on hand changed over time?', 'trend', 'fact_inventory_snapshot', 'dim_date, dim_plant, dim_product', 'snapshot_ts', 'One row per snapshot timestamp, plant, warehouse, product, and batch before aggregation', 'date range', 'plant, warehouse, product', 'snapshot_month', 'Use sum(quantity_on_hand) by snapshot month', 'SELECT
        toStartOfMonth(snapshot_ts) AS snapshot_month,
        sum(quantity_on_hand) AS quantity_on_hand
    FROM manufacturing_dw.fact_inventory_snapshot
    WHERE snapshot_ts >= {start_date}
      AND snapshot_ts < {end_date}
    GROUP BY snapshot_month
    ORDER BY snapshot_month;', 'Use this for month-over-month inventory movement trends.', 'If snapshots are more frequent than daily, results show month-end-style aggregated snapshot totals, not transactional movement.', 1),
('inventory_value_by_warehouse', 'inventory', 'Which warehouses have the highest inventory value?', 'ranking', 'fact_inventory_snapshot', 'dim_warehouse, dim_plant', 'snapshot_ts', 'One row per snapshot timestamp, plant, warehouse, product, and batch before aggregation', 'latest snapshot', 'plant, product', 'warehouse_name', 'Use sum(inventory_value) at the latest snapshot timestamp and rank descending', 'WITH latest_snapshot AS (
        SELECT max(snapshot_ts) AS max_snapshot_ts
        FROM manufacturing_dw.fact_inventory_snapshot
    )
    SELECT
        w.warehouse_name,
        sum(i.inventory_value) AS inventory_value
    FROM manufacturing_dw.fact_inventory_snapshot i
    INNER JOIN latest_snapshot ls
        ON i.snapshot_ts = ls.max_snapshot_ts
    LEFT JOIN manufacturing_dw.dim_warehouse w
        ON i.warehouse_key = w.warehouse_key
    GROUP BY w.warehouse_name
    ORDER BY inventory_value DESC;', 'Useful for identifying where the most inventory value is stored.', 'Use caution if multiple currencies exist; current schema assumes a single comparable currency context.', 1),
('inventory_value_by_warehouse', 'inventory', 'Which warehouses have the highest inventory value?', 'ranking', 'fact_inventory_snapshot', 'dim_warehouse, dim_plant', 'snapshot_ts', 'One row per snapshot timestamp, plant, warehouse, product, and batch before aggregation', 'latest snapshot', 'plant, product', 'warehouse_name', 'Use sum(inventory_value) at the latest snapshot timestamp and rank descending', 'WITH latest_snapshot AS (
        SELECT max(snapshot_ts) AS max_snapshot_ts
        FROM manufacturing_dw.fact_inventory_snapshot
    )
    SELECT
        w.warehouse_name,
        sum(i.inventory_value) AS inventory_value
    FROM manufacturing_dw.fact_inventory_snapshot i
    INNER JOIN latest_snapshot ls
        ON i.snapshot_ts = ls.max_snapshot_ts
    LEFT JOIN manufacturing_dw.dim_warehouse w
        ON i.warehouse_key = w.warehouse_key
    GROUP BY w.warehouse_name
    ORDER BY inventory_value DESC;', 'Useful for identifying where the most inventory value is stored.', 'Use caution if multiple currencies exist; current schema assumes a single comparable currency context.', 1),
('receipt_volume_by_product', 'procurement', 'Which products had the highest inbound receipt volume?', 'ranking', 'fact_material_receipt', 'dim_product, dim_supplier, dim_plant', 'receipt_ts', 'One row per material receipt transaction before aggregation', 'date range', 'supplier, plant', 'product_name', 'Use sum(quantity_received)', 'SELECT
        pr.product_name,
        sum(r.quantity_received) AS quantity_received
    FROM manufacturing_dw.fact_material_receipt r
    LEFT JOIN manufacturing_dw.dim_product pr
        ON r.product_key = pr.product_key
    WHERE r.receipt_ts >= {start_date}
      AND r.receipt_ts < {end_date}
    GROUP BY pr.product_name
    ORDER BY quantity_received DESC;', 'Useful for understanding inbound material mix and procurement volume.', 'Compare only products with comparable units of measure.', 1),
('receipt_volume_by_product', 'procurement', 'Which products had the highest inbound receipt volume?', 'ranking', 'fact_material_receipt', 'dim_product, dim_supplier, dim_plant', 'receipt_ts', 'One row per material receipt transaction before aggregation', 'date range', 'supplier, plant', 'product_name', 'Use sum(quantity_received)', 'SELECT
        pr.product_name,
        sum(r.quantity_received) AS quantity_received
    FROM manufacturing_dw.fact_material_receipt r
    LEFT JOIN manufacturing_dw.dim_product pr
        ON r.product_key = pr.product_key
    WHERE r.receipt_ts >= {start_date}
      AND r.receipt_ts < {end_date}
    GROUP BY pr.product_name
    ORDER BY quantity_received DESC;', 'Useful for understanding inbound material mix and procurement volume.', 'Compare only products with comparable units of measure.', 1),
('supplier_acceptance_rate_by_month', 'procurement', 'What is the supplier acceptance rate by month?', 'trend', 'fact_material_receipt', 'dim_supplier', 'receipt_ts', 'One row per material receipt transaction before aggregation', 'date range', 'plant, product, supplier', 'receipt_month, supplier_name', 'Use sum(quantity_accepted) / nullIf(sum(quantity_received), 0)', 'SELECT
        toStartOfMonth(r.receipt_ts) AS receipt_month,
        s.supplier_name,
        sum(r.quantity_received) AS quantity_received,
        sum(r.quantity_accepted) AS quantity_accepted,
        sum(r.quantity_accepted) / nullIf(sum(r.quantity_received), 0) AS acceptance_rate
    FROM manufacturing_dw.fact_material_receipt r
    LEFT JOIN manufacturing_dw.dim_supplier s
        ON r.supplier_key = s.supplier_key
    WHERE r.receipt_ts >= {start_date}
      AND r.receipt_ts < {end_date}
    GROUP BY
        receipt_month,
        s.supplier_name
    ORDER BY
        receipt_month,
        s.supplier_name;', 'Shows inbound quality trend by supplier over time.', 'Interpret together with receipt volume to avoid overreacting to low-volume suppliers.', 1),
('supplier_acceptance_rate_by_month', 'procurement', 'What is the supplier acceptance rate by month?', 'trend', 'fact_material_receipt', 'dim_supplier', 'receipt_ts', 'One row per material receipt transaction before aggregation', 'date range', 'plant, product, supplier', 'receipt_month, supplier_name', 'Use sum(quantity_accepted) / nullIf(sum(quantity_received), 0)', 'SELECT
        toStartOfMonth(r.receipt_ts) AS receipt_month,
        s.supplier_name,
        sum(r.quantity_received) AS quantity_received,
        sum(r.quantity_accepted) AS quantity_accepted,
        sum(r.quantity_accepted) / nullIf(sum(r.quantity_received), 0) AS acceptance_rate
    FROM manufacturing_dw.fact_material_receipt r
    LEFT JOIN manufacturing_dw.dim_supplier s
        ON r.supplier_key = s.supplier_key
    WHERE r.receipt_ts >= {start_date}
      AND r.receipt_ts < {end_date}
    GROUP BY
        receipt_month,
        s.supplier_name
    ORDER BY
        receipt_month,
        s.supplier_name;', 'Shows inbound quality trend by supplier over time.', 'Interpret together with receipt volume to avoid overreacting to low-volume suppliers.', 1),
('supplier_rejection_rate_last_90_days', 'procurement', 'Which suppliers have the highest rejection rate over the last 90 days?', 'ranking', 'fact_material_receipt', 'dim_supplier, dim_product', 'receipt_ts', 'One row per material receipt transaction before aggregation', 'last 90 days', 'plant, product, supplier', 'supplier_name', 'Use sum(quantity_rejected) / nullIf(sum(quantity_received), 0)', 'SELECT
        s.supplier_name,
        sum(r.quantity_received) AS quantity_received,
        sum(r.quantity_rejected) AS quantity_rejected,
        sum(r.quantity_rejected) / nullIf(sum(r.quantity_received), 0) AS rejection_rate
    FROM manufacturing_dw.fact_material_receipt r
    LEFT JOIN manufacturing_dw.dim_supplier s
        ON r.supplier_key = s.supplier_key
    WHERE r.receipt_ts >= now() - INTERVAL 90 DAY
    GROUP BY s.supplier_name
    ORDER BY rejection_rate DESC, quantity_rejected DESC;', 'Higher rejection_rate indicates poorer inbound quality performance.', 'Suppliers with very small receipt volumes can appear extreme; consider minimum volume thresholds.', 1),
('supplier_rejection_rate_last_90_days', 'procurement', 'Which suppliers have the highest rejection rate over the last 90 days?', 'ranking', 'fact_material_receipt', 'dim_supplier, dim_product', 'receipt_ts', 'One row per material receipt transaction before aggregation', 'last 90 days', 'plant, product, supplier', 'supplier_name', 'Use sum(quantity_rejected) / nullIf(sum(quantity_received), 0)', 'SELECT
        s.supplier_name,
        sum(r.quantity_received) AS quantity_received,
        sum(r.quantity_rejected) AS quantity_rejected,
        sum(r.quantity_rejected) / nullIf(sum(r.quantity_received), 0) AS rejection_rate
    FROM manufacturing_dw.fact_material_receipt r
    LEFT JOIN manufacturing_dw.dim_supplier s
        ON r.supplier_key = s.supplier_key
    WHERE r.receipt_ts >= now() - INTERVAL 90 DAY
    GROUP BY s.supplier_name
    ORDER BY rejection_rate DESC, quantity_rejected DESC;', 'Higher rejection_rate indicates poorer inbound quality performance.', 'Suppliers with very small receipt volumes can appear extreme; consider minimum volume thresholds.', 1),
('downtime_by_work_center', 'production', 'Which work centers had the most downtime?', 'ranking', 'fact_production_operation', 'dim_work_center, dim_plant', 'event_ts', 'One row per production order operation record before aggregation', 'date range', 'plant, product, operation_status', 'work_center_name, plant_name', 'Use sum(downtime_minutes)', 'SELECT
        wc.work_center_name,
        p.plant_name,
        sum(op.downtime_minutes) AS downtime_minutes
    FROM manufacturing_dw.fact_production_operation op
    LEFT JOIN manufacturing_dw.dim_work_center wc
        ON op.work_center_key = wc.work_center_key
    LEFT JOIN manufacturing_dw.dim_plant p
        ON op.plant_key = p.plant_key
    WHERE op.event_ts >= {start_date}
      AND op.event_ts < {end_date}
    GROUP BY
        wc.work_center_name,
        p.plant_name
    ORDER BY downtime_minutes DESC;', 'Highlights the biggest downtime contributors.', 'Not a full OEE model by itself.', 1),
('downtime_by_work_center', 'production', 'Which work centers had the most downtime?', 'ranking', 'fact_production_operation', 'dim_work_center, dim_plant', 'event_ts', 'One row per production order operation record before aggregation', 'date range', 'plant, product, operation_status', 'work_center_name, plant_name', 'Use sum(downtime_minutes)', 'SELECT
        wc.work_center_name,
        p.plant_name,
        sum(op.downtime_minutes) AS downtime_minutes
    FROM manufacturing_dw.fact_production_operation op
    LEFT JOIN manufacturing_dw.dim_work_center wc
        ON op.work_center_key = wc.work_center_key
    LEFT JOIN manufacturing_dw.dim_plant p
        ON op.plant_key = p.plant_key
    WHERE op.event_ts >= {start_date}
      AND op.event_ts < {end_date}
    GROUP BY
        wc.work_center_name,
        p.plant_name
    ORDER BY downtime_minutes DESC;', 'Highlights the biggest downtime contributors.', 'Not a full OEE model by itself.', 1),
('production_completion_rate_by_plant', 'production', 'What is the production completion rate by plant?', 'summary', 'fact_production_order', 'dim_plant, dim_product', 'planned_start_ts', 'One row per production order before aggregation', 'date range', 'plant, product, order_status', 'plant_name', 'Use sum(completed_quantity) / nullIf(sum(order_quantity), 0)', 'SELECT
        p.plant_name,
        sum(o.order_quantity) AS order_quantity,
        sum(o.completed_quantity) AS completed_quantity,
        sum(o.completed_quantity) / nullIf(sum(o.order_quantity), 0) AS completion_rate
    FROM manufacturing_dw.fact_production_order o
    LEFT JOIN manufacturing_dw.dim_plant p
        ON o.plant_key = p.plant_key
    WHERE o.planned_start_ts >= {start_date}
      AND o.planned_start_ts < {end_date}
    GROUP BY p.plant_name
    ORDER BY p.plant_name;', 'Higher completion_rate indicates more planned output was achieved.', 'Exclude cancelled orders when appropriate.', 1),
('production_completion_rate_by_plant', 'production', 'What is the production completion rate by plant?', 'summary', 'fact_production_order', 'dim_plant, dim_product', 'planned_start_ts', 'One row per production order before aggregation', 'date range', 'plant, product, order_status', 'plant_name', 'Use sum(completed_quantity) / nullIf(sum(order_quantity), 0)', 'SELECT
        p.plant_name,
        sum(o.order_quantity) AS order_quantity,
        sum(o.completed_quantity) AS completed_quantity,
        sum(o.completed_quantity) / nullIf(sum(o.order_quantity), 0) AS completion_rate
    FROM manufacturing_dw.fact_production_order o
    LEFT JOIN manufacturing_dw.dim_plant p
        ON o.plant_key = p.plant_key
    WHERE o.planned_start_ts >= {start_date}
      AND o.planned_start_ts < {end_date}
    GROUP BY p.plant_name
    ORDER BY p.plant_name;', 'Higher completion_rate indicates more planned output was achieved.', 'Exclude cancelled orders when appropriate.', 1),
('production_cost_variance_by_month', 'production', 'How is production cost variance trending by month?', 'trend', 'fact_production_order', 'dim_plant, dim_product', 'planned_start_ts', 'One row per production order before aggregation', 'date range', 'plant, product, order_status', 'production_month', 'Use sum(actual_cost_total) - sum(standard_cost_total)', 'SELECT
        toStartOfMonth(o.planned_start_ts) AS production_month,
        sum(o.actual_cost_total) AS actual_cost_total,
        sum(o.standard_cost_total) AS standard_cost_total,
        sum(o.actual_cost_total) - sum(o.standard_cost_total) AS cost_variance
    FROM manufacturing_dw.fact_production_order o
    WHERE o.planned_start_ts >= {start_date}
      AND o.planned_start_ts < {end_date}
    GROUP BY production_month
    ORDER BY production_month;', 'Positive cost_variance means actual costs exceeded standard costs.', 'Interpret alongside output and scrap volume.', 1),
('production_cost_variance_by_month', 'production', 'How is production cost variance trending by month?', 'trend', 'fact_production_order', 'dim_plant, dim_product', 'planned_start_ts', 'One row per production order before aggregation', 'date range', 'plant, product, order_status', 'production_month', 'Use sum(actual_cost_total) - sum(standard_cost_total)', 'SELECT
        toStartOfMonth(o.planned_start_ts) AS production_month,
        sum(o.actual_cost_total) AS actual_cost_total,
        sum(o.standard_cost_total) AS standard_cost_total,
        sum(o.actual_cost_total) - sum(o.standard_cost_total) AS cost_variance
    FROM manufacturing_dw.fact_production_order o
    WHERE o.planned_start_ts >= {start_date}
      AND o.planned_start_ts < {end_date}
    GROUP BY production_month
    ORDER BY production_month;', 'Positive cost_variance means actual costs exceeded standard costs.', 'Interpret alongside output and scrap volume.', 1),
('production_scrap_rate_by_product', 'production', 'Which products have the highest production scrap rate?', 'ranking', 'fact_production_order', 'dim_product, dim_plant', 'planned_start_ts', 'One row per production order before aggregation', 'date range', 'plant, order_status', 'product_name', 'Use sum(scrapped_quantity) / nullIf(sum(completed_quantity + scrapped_quantity), 0)', 'SELECT
        pr.product_name,
        sum(o.completed_quantity) AS completed_quantity,
        sum(o.scrapped_quantity) AS scrapped_quantity,
        sum(o.scrapped_quantity) / nullIf(sum(o.completed_quantity + o.scrapped_quantity), 0) AS scrap_rate
    FROM manufacturing_dw.fact_production_order o
    LEFT JOIN manufacturing_dw.dim_product pr
        ON o.product_key = pr.product_key
    WHERE o.planned_start_ts >= {start_date}
      AND o.planned_start_ts < {end_date}
    GROUP BY pr.product_name
    ORDER BY scrap_rate DESC, scrapped_quantity DESC;', 'Useful for identifying products with poor manufacturing yield.', 'Interpret with volume; high rates on tiny volumes may not be meaningful.', 1),
('production_scrap_rate_by_product', 'production', 'Which products have the highest production scrap rate?', 'ranking', 'fact_production_order', 'dim_product, dim_plant', 'planned_start_ts', 'One row per production order before aggregation', 'date range', 'plant, order_status', 'product_name', 'Use sum(scrapped_quantity) / nullIf(sum(completed_quantity + scrapped_quantity), 0)', 'SELECT
        pr.product_name,
        sum(o.completed_quantity) AS completed_quantity,
        sum(o.scrapped_quantity) AS scrapped_quantity,
        sum(o.scrapped_quantity) / nullIf(sum(o.completed_quantity + o.scrapped_quantity), 0) AS scrap_rate
    FROM manufacturing_dw.fact_production_order o
    LEFT JOIN manufacturing_dw.dim_product pr
        ON o.product_key = pr.product_key
    WHERE o.planned_start_ts >= {start_date}
      AND o.planned_start_ts < {end_date}
    GROUP BY pr.product_name
    ORDER BY scrap_rate DESC, scrapped_quantity DESC;', 'Useful for identifying products with poor manufacturing yield.', 'Interpret with volume; high rates on tiny volumes may not be meaningful.', 1),
('good_yield_by_inspection_type', 'quality', 'What is the good yield by inspection type?', 'summary', 'fact_quality_inspection', 'dim_product, dim_supplier, dim_plant', 'inspection_ts', 'One row per inspection event before aggregation', 'date range', 'plant, supplier, product', 'inspection_type', 'Use sum(accepted_quantity) / nullIf(sum(inspected_quantity), 0)', 'SELECT
        q.inspection_type,
        sum(q.inspected_quantity) AS inspected_quantity,
        sum(q.accepted_quantity) AS accepted_quantity,
        sum(q.accepted_quantity) / nullIf(sum(q.inspected_quantity), 0) AS good_yield
    FROM manufacturing_dw.fact_quality_inspection q
    WHERE q.inspection_ts >= {start_date}
      AND q.inspection_ts < {end_date}
    GROUP BY q.inspection_type
    ORDER BY q.inspection_type;', 'Shows where yield is strongest or weakest across inspection stages.', 'Compare incoming, in-process, and final separately for meaningful interpretation.', 1),
('good_yield_by_inspection_type', 'quality', 'What is the good yield by inspection type?', 'summary', 'fact_quality_inspection', 'dim_product, dim_supplier, dim_plant', 'inspection_ts', 'One row per inspection event before aggregation', 'date range', 'plant, supplier, product', 'inspection_type', 'Use sum(accepted_quantity) / nullIf(sum(inspected_quantity), 0)', 'SELECT
        q.inspection_type,
        sum(q.inspected_quantity) AS inspected_quantity,
        sum(q.accepted_quantity) AS accepted_quantity,
        sum(q.accepted_quantity) / nullIf(sum(q.inspected_quantity), 0) AS good_yield
    FROM manufacturing_dw.fact_quality_inspection q
    WHERE q.inspection_ts >= {start_date}
      AND q.inspection_ts < {end_date}
    GROUP BY q.inspection_type
    ORDER BY q.inspection_type;', 'Shows where yield is strongest or weakest across inspection stages.', 'Compare incoming, in-process, and final separately for meaningful interpretation.', 1),
('supplier_quality_reject_rate', 'quality', 'Which suppliers have the worst incoming quality reject rate?', 'ranking', 'fact_quality_inspection', 'dim_supplier, dim_product', 'inspection_ts', 'One row per inspection event before aggregation', 'date range, incoming inspection', 'plant, product', 'supplier_name', 'Use sum(rejected_quantity) / nullIf(sum(inspected_quantity), 0) with inspection_type = incoming', 'SELECT
        s.supplier_name,
        sum(q.inspected_quantity) AS inspected_quantity,
        sum(q.rejected_quantity) AS rejected_quantity,
        sum(q.rejected_quantity) / nullIf(sum(q.inspected_quantity), 0) AS reject_rate
    FROM manufacturing_dw.fact_quality_inspection q
    LEFT JOIN manufacturing_dw.dim_supplier s
        ON q.supplier_key = s.supplier_key
    WHERE q.inspection_ts >= {start_date}
      AND q.inspection_ts < {end_date}
      AND q.inspection_type = \'incoming\'
    GROUP BY s.supplier_name
    ORDER BY reject_rate DESC, rejected_quantity DESC;', 'Useful for supplier quality monitoring.', 'Apply minimum inspected volume thresholds for fair ranking.', 1),
('supplier_quality_reject_rate', 'quality', 'Which suppliers have the worst incoming quality reject rate?', 'ranking', 'fact_quality_inspection', 'dim_supplier, dim_product', 'inspection_ts', 'One row per inspection event before aggregation', 'date range, incoming inspection', 'plant, product', 'supplier_name', 'Use sum(rejected_quantity) / nullIf(sum(inspected_quantity), 0) with inspection_type = incoming', 'SELECT
        s.supplier_name,
        sum(q.inspected_quantity) AS inspected_quantity,
        sum(q.rejected_quantity) AS rejected_quantity,
        sum(q.rejected_quantity) / nullIf(sum(q.inspected_quantity), 0) AS reject_rate
    FROM manufacturing_dw.fact_quality_inspection q
    LEFT JOIN manufacturing_dw.dim_supplier s
        ON q.supplier_key = s.supplier_key
    WHERE q.inspection_ts >= {start_date}
      AND q.inspection_ts < {end_date}
      AND q.inspection_type = \'incoming\'
    GROUP BY s.supplier_name
    ORDER BY reject_rate DESC, rejected_quantity DESC;', 'Useful for supplier quality monitoring.', 'Apply minimum inspected volume thresholds for fair ranking.', 1),
('top_defect_codes_finished_goods', 'quality', 'What are the top defect codes for finished goods?', 'ranking', 'fact_quality_inspection', 'dim_product, dim_plant, dim_supplier', 'inspection_ts', 'One row per inspection event before aggregation', 'date range', 'plant, supplier, inspection_type, product_type', 'defect_code, defect_description', 'Use sum(rejected_quantity) or count of inspections by defect code', 'SELECT
        q.defect_code,
        q.defect_description,
        sum(q.rejected_quantity) AS rejected_quantity
    FROM manufacturing_dw.fact_quality_inspection q
    LEFT JOIN manufacturing_dw.dim_product pr
        ON q.product_key = pr.product_key
    WHERE q.inspection_ts >= {start_date}
      AND q.inspection_ts < {end_date}
      AND pr.product_type = \'finished_good\'
    GROUP BY
        q.defect_code,
        q.defect_description
    ORDER BY rejected_quantity DESC;', 'Useful for root cause prioritization on finished goods quality.', 'Null or blank defect codes may need separate handling.', 1),
('top_defect_codes_finished_goods', 'quality', 'What are the top defect codes for finished goods?', 'ranking', 'fact_quality_inspection', 'dim_product, dim_plant, dim_supplier', 'inspection_ts', 'One row per inspection event before aggregation', 'date range', 'plant, supplier, inspection_type, product_type', 'defect_code, defect_description', 'Use sum(rejected_quantity) or count of inspections by defect code', 'SELECT
        q.defect_code,
        q.defect_description,
        sum(q.rejected_quantity) AS rejected_quantity
    FROM manufacturing_dw.fact_quality_inspection q
    LEFT JOIN manufacturing_dw.dim_product pr
        ON q.product_key = pr.product_key
    WHERE q.inspection_ts >= {start_date}
      AND q.inspection_ts < {end_date}
      AND pr.product_type = \'finished_good\'
    GROUP BY
        q.defect_code,
        q.defect_description
    ORDER BY rejected_quantity DESC;', 'Useful for root cause prioritization on finished goods quality.', 'Null or blank defect codes may need separate handling.', 1),
('average_freight_per_unit_by_plant', 'shipment', 'What is the average freight per unit by plant?', 'summary', 'fact_shipment', 'dim_plant, dim_customer, dim_product', 'shipment_ts', 'One row per outbound shipment transaction line before aggregation', 'date range', 'customer, warehouse, product', 'plant_name', 'Use sum(freight_amount) / nullIf(sum(shipped_quantity), 0)', 'SELECT
        p.plant_name,
        sum(s.freight_amount) AS freight_amount,
        sum(s.shipped_quantity) AS shipped_quantity,
        sum(s.freight_amount) / nullIf(sum(s.shipped_quantity), 0) AS average_freight_per_unit
    FROM manufacturing_dw.fact_shipment s
    LEFT JOIN manufacturing_dw.dim_plant p
        ON s.plant_key = p.plant_key
    WHERE s.shipment_ts >= {start_date}
      AND s.shipment_ts < {end_date}
    GROUP BY p.plant_name
    ORDER BY p.plant_name;', 'Useful for logistics efficiency comparisons across plants.', 'Sensitive to shipment mix and units of measure.', 1),
('average_freight_per_unit_by_plant', 'shipment', 'What is the average freight per unit by plant?', 'summary', 'fact_shipment', 'dim_plant, dim_customer, dim_product', 'shipment_ts', 'One row per outbound shipment transaction line before aggregation', 'date range', 'customer, warehouse, product', 'plant_name', 'Use sum(freight_amount) / nullIf(sum(shipped_quantity), 0)', 'SELECT
        p.plant_name,
        sum(s.freight_amount) AS freight_amount,
        sum(s.shipped_quantity) AS shipped_quantity,
        sum(s.freight_amount) / nullIf(sum(s.shipped_quantity), 0) AS average_freight_per_unit
    FROM manufacturing_dw.fact_shipment s
    LEFT JOIN manufacturing_dw.dim_plant p
        ON s.plant_key = p.plant_key
    WHERE s.shipment_ts >= {start_date}
      AND s.shipment_ts < {end_date}
    GROUP BY p.plant_name
    ORDER BY p.plant_name;', 'Useful for logistics efficiency comparisons across plants.', 'Sensitive to shipment mix and units of measure.', 1),
('net_sales_by_customer_month', 'shipment', 'How are net sales trending by customer over time?', 'trend', 'fact_shipment', 'dim_customer, dim_product, dim_plant', 'shipment_ts', 'One row per outbound shipment transaction line before aggregation', 'date range', 'plant, warehouse, product, customer', 'shipment_month, customer_name', 'Use sum(net_sales_amount)', 'SELECT
        toStartOfMonth(s.shipment_ts) AS shipment_month,
        c.customer_name,
        sum(s.net_sales_amount) AS net_sales_amount
    FROM manufacturing_dw.fact_shipment s
    LEFT JOIN manufacturing_dw.dim_customer c
        ON s.customer_key = c.customer_key
    WHERE s.shipment_ts >= {start_date}
      AND s.shipment_ts < {end_date}
    GROUP BY
        shipment_month,
        c.customer_name
    ORDER BY
        shipment_month,
        c.customer_name;', 'Useful for trend analysis of commercial shipment value.', 'Shipment-based sales may differ from invoiced revenue.', 1),
('net_sales_by_customer_month', 'shipment', 'How are net sales trending by customer over time?', 'trend', 'fact_shipment', 'dim_customer, dim_product, dim_plant', 'shipment_ts', 'One row per outbound shipment transaction line before aggregation', 'date range', 'plant, warehouse, product, customer', 'shipment_month, customer_name', 'Use sum(net_sales_amount)', 'SELECT
        toStartOfMonth(s.shipment_ts) AS shipment_month,
        c.customer_name,
        sum(s.net_sales_amount) AS net_sales_amount
    FROM manufacturing_dw.fact_shipment s
    LEFT JOIN manufacturing_dw.dim_customer c
        ON s.customer_key = c.customer_key
    WHERE s.shipment_ts >= {start_date}
      AND s.shipment_ts < {end_date}
    GROUP BY
        shipment_month,
        c.customer_name
    ORDER BY
        shipment_month,
        c.customer_name;', 'Useful for trend analysis of commercial shipment value.', 'Shipment-based sales may differ from invoiced revenue.', 1),
('shipment_volume_by_customer', 'shipment', 'Which customers received the highest shipped quantity?', 'ranking', 'fact_shipment', 'dim_customer, dim_product, dim_plant', 'shipment_ts', 'One row per outbound shipment transaction line before aggregation', 'date range', 'plant, warehouse, product, customer', 'customer_name', 'Use sum(shipped_quantity)', 'SELECT
        c.customer_name,
        sum(s.shipped_quantity) AS shipped_quantity
    FROM manufacturing_dw.fact_shipment s
    LEFT JOIN manufacturing_dw.dim_customer c
        ON s.customer_key = c.customer_key
    WHERE s.shipment_ts >= {start_date}
      AND s.shipment_ts < {end_date}
    GROUP BY c.customer_name
    ORDER BY shipped_quantity DESC;', 'Highlights top customers by outbound shipment volume.', 'Use caution if shipped_quantity mixes incompatible units.', 1),
('shipment_volume_by_customer', 'shipment', 'Which customers received the highest shipped quantity?', 'ranking', 'fact_shipment', 'dim_customer, dim_product, dim_plant', 'shipment_ts', 'One row per outbound shipment transaction line before aggregation', 'date range', 'plant, warehouse, product, customer', 'customer_name', 'Use sum(shipped_quantity)', 'SELECT
        c.customer_name,
        sum(s.shipped_quantity) AS shipped_quantity
    FROM manufacturing_dw.fact_shipment s
    LEFT JOIN manufacturing_dw.dim_customer c
        ON s.customer_key = c.customer_key
    WHERE s.shipment_ts >= {start_date}
      AND s.shipment_ts < {end_date}
    GROUP BY c.customer_name
    ORDER BY shipped_quantity DESC;', 'Highlights top customers by outbound shipment volume.', 'Use caution if shipped_quantity mixes incompatible units.', 1);

INSERT INTO `manufacturing_dw`.`kpi_definitions` (`kpi_name`, `kpi_category`, `source_table`, `grain_note`, `formula_sql`, `numerator_definition`, `denominator_definition`, `unit_of_measure`, `preferred_time_column`, `dimensions_supported`, `filters_supported`, `interpretation`, `caveats`) VALUES
('Inventory Available', 'inventory', 'fact_inventory_snapshot', 'Use the latest snapshot for current-state reporting', 'sum(quantity_available)', 'Stock available for use after reservations', '', 'quantity', 'snapshot_ts', 'plant, warehouse, product, batch, date', 'snapshot_ts, plant_key, warehouse_key, product_key, batch_number', 'Higher values indicate more usable stock', 'May differ from quantity_on_hand due to reservations'),
('Inventory On Hand', 'inventory', 'fact_inventory_snapshot', 'Use the latest snapshot for current-state reporting or aggregate by snapshot date for trends', 'sum(quantity_on_hand)', 'Total physical stock quantity', '', 'quantity', 'snapshot_ts', 'plant, warehouse, product, batch, date', 'snapshot_ts, plant_key, warehouse_key, product_key, batch_number', 'Higher values indicate more stock on hand', 'Avoid summing the same inventory across multiple snapshots unless analyzing a time series'),
('Inventory Value', 'inventory', 'fact_inventory_snapshot', 'Use the latest snapshot when reporting current value', 'sum(inventory_value)', 'Total inventory value', '', 'currency', 'snapshot_ts', 'plant, warehouse, product, date', 'snapshot_ts, plant_key, warehouse_key, product_key', 'Higher values indicate more value tied up in inventory', 'Interpret together with stock turns and aging where possible'),
('Receipt Acceptance Rate', 'procurement', 'fact_material_receipt', 'Aggregate receipts over the requested date range before computing the ratio', 'sum(quantity_accepted) / nullIf(sum(quantity_received), 0)', 'Accepted received quantity', 'Total received quantity', 'ratio', 'receipt_ts', 'supplier, plant, warehouse, product, date', 'receipt_ts, supplier_key, plant_key, warehouse_key, product_key', 'Higher is better because more inbound material passed receiving checks', 'Use only where quantity_received is nonzero'),
('Receipt Rejection Rate', 'procurement', 'fact_material_receipt', 'Aggregate receipts over the requested date range before computing the ratio', 'sum(quantity_rejected) / nullIf(sum(quantity_received), 0)', 'Rejected received quantity', 'Total received quantity', 'ratio', 'receipt_ts', 'supplier, plant, warehouse, product, date', 'receipt_ts, supplier_key, plant_key, warehouse_key, product_key', 'Lower is better because less inbound material was rejected', 'Can be compared with supplier quality trends'),
('Production Completion Rate', 'production', 'fact_production_order', 'Aggregate completed and ordered quantities over the requested set of orders', 'sum(completed_quantity) / nullIf(sum(order_quantity), 0)', 'Completed production quantity', 'Planned production quantity', 'ratio', 'planned_start_ts', 'plant, product, order_status, due_date', 'planned_start_ts, plant_key, product_key, order_status', 'Higher is better because more planned output was completed', 'Use with care when cancelled orders are included'),
('Production Cost Variance', 'production', 'fact_production_order', 'Aggregate actual and standard costs over the requested orders', 'sum(actual_cost_total) - sum(standard_cost_total)', 'Actual total production cost', 'Standard total production cost', 'currency', 'planned_start_ts', 'plant, product, order_status, due_date', 'planned_start_ts, plant_key, product_key, order_status', 'Positive values indicate actual cost exceeded standard cost', 'Interpret together with output volume and scrap'),
('Production Scrap Rate', 'production', 'fact_production_order', 'Aggregate scrap and total attempted output over the requested orders', 'sum(scrapped_quantity) / nullIf(sum(completed_quantity + scrapped_quantity), 0)', 'Scrapped quantity', 'Completed quantity plus scrapped quantity', 'ratio', 'planned_start_ts', 'plant, product, order_status, due_date', 'planned_start_ts, plant_key, product_key, order_status', 'Lower is better because less production was lost as scrap', 'Can also be calculated at operation level from fact_production_operation'),
('Work Center Downtime Rate', 'production', 'fact_production_operation', 'Aggregate downtime and runtime over the requested operations', 'sum(downtime_minutes) / nullIf(sum(run_time_minutes + downtime_minutes), 0)', 'Downtime minutes', 'Runtime minutes plus downtime minutes', 'ratio', 'event_ts', 'work_center, plant, product, operation_status, operation_name', 'event_ts, work_center_key, plant_key, product_key, operation_status', 'Lower is better because less time was lost to downtime', 'This is a simplified operational KPI and not a full OEE measure'),
('Good Yield', 'quality', 'fact_quality_inspection', 'Aggregate accepted and inspected quantities over the requested inspections', 'sum(accepted_quantity) / nullIf(sum(inspected_quantity), 0)', 'Accepted quantity', 'Inspected quantity', 'ratio', 'inspection_ts', 'plant, product, supplier, inspection_type, defect_code, date', 'inspection_ts, plant_key, product_key, supplier_key, inspection_type', 'Higher is better because more inspected units passed', 'Compare incoming and in-process inspections separately when possible'),
('Reject Rate', 'quality', 'fact_quality_inspection', 'Aggregate rejected and inspected quantities over the requested inspections', 'sum(rejected_quantity) / nullIf(sum(inspected_quantity), 0)', 'Rejected quantity', 'Inspected quantity', 'ratio', 'inspection_ts', 'plant, product, supplier, inspection_type, defect_code, date', 'inspection_ts, plant_key, product_key, supplier_key, inspection_type', 'Lower is better because fewer inspected units failed', 'Use defect_code to identify top quality drivers'),
('Rework Rate', 'quality', 'fact_quality_inspection', 'Aggregate reworked and inspected quantities over the requested inspections', 'sum(reworked_quantity) / nullIf(sum(inspected_quantity), 0)', 'Reworked quantity', 'Inspected quantity', 'ratio', 'inspection_ts', 'plant, product, supplier, inspection_type, date', 'inspection_ts, plant_key, product_key, supplier_key, inspection_type', 'Lower is generally better because less rework was needed', 'Sometimes rework is preferable to outright rejection; interpret in context'),
('Average Freight per Unit', 'shipment', 'fact_shipment', 'Aggregate freight and shipped quantity over the requested shipment rows', 'sum(freight_amount) / nullIf(sum(shipped_quantity), 0)', 'Total freight amount', 'Total shipped quantity', 'currency per unit', 'shipment_ts', 'customer, plant, warehouse, product, date', 'shipment_ts, customer_key, plant_key, warehouse_key, product_key', 'Lower is better for logistics efficiency', 'Sensitive to product mix and unit-of-measure differences'),
('Net Sales Amount', 'shipment', 'fact_shipment', 'Aggregate sales amount over the requested shipment rows', 'sum(net_sales_amount)', 'Total net sales amount', '', 'currency', 'shipment_ts', 'customer, plant, warehouse, product, date', 'shipment_ts, customer_key, plant_key, warehouse_key, product_key', 'Higher values indicate more commercial value shipped', 'This is shipment-based and may not equal invoiced revenue'),
('Shipment Volume', 'shipment', 'fact_shipment', 'Aggregate shipped quantity over the requested shipment rows', 'sum(shipped_quantity)', 'Total shipped quantity', '', 'quantity', 'shipment_ts', 'customer, plant, warehouse, product, date', 'shipment_ts, customer_key, plant_key, warehouse_key, product_key', 'Higher values indicate more outbound fulfillment volume', 'Make sure products with different units are compared only when compatible');

INSERT INTO `manufacturing_dw`.`table_ai_context` (`database_name`, `table_name`, `table_role`, `business_grain`, `business_purpose`, `primary_time_column`, `default_dimensions`, `default_measures`, `common_filters`, `join_instructions`, `data_freshness_expectation`, `ai_usage_notes`) VALUES
('manufacturing_dw', 'bom_component', 'bridge', 'One row per parent product, component product, plant, BOM version, and validity range', 'Represents the bill of materials structure between parent products and required components', 'valid_from', 'parent_product_key, component_product_key, plant_key, bom_version', 'component_quantity, scrap_factor_pct', 'plant_key, bom_version, is_current, valid_from, valid_to', 'Join parent_product_key and component_product_key separately to dim_product.product_key. Join plant_key to dim_plant.plant_key.', 'as needed', 'Use for component explosion, material requirements, and cost rollup logic.'),
('manufacturing_dw', 'dim_customer', 'dimension', 'One row per customer version', 'Stores customer master data used for outbound shipment and sales analysis', '', 'customer_id, customer_name, customer_segment, country, region, channel', '', 'is_active, is_current, customer_segment, region, channel', 'Join from fact_shipment using customer_key to dim_customer.customer_key.', 'daily', 'Use for shipment, sales mix, and regional performance analysis.'),
('manufacturing_dw', 'dim_date', 'dimension', 'One row per calendar date', 'Standard reporting calendar used for date-based grouping and filtering', 'full_date', 'year, quarter, month, month_name, week_of_year, day_name, is_weekend', '', 'year, quarter, month, week_of_year, is_weekend', 'Join from fact tables using date_key to dim_date.date_key.', 'static', 'Use for consistent calendar-based reporting. Preferred for rollups by month, quarter, and year.'),
('manufacturing_dw', 'dim_plant', 'dimension', 'One row per plant version', 'Provides descriptive attributes for manufacturing plants used in filtering and grouping', '', 'plant_id, plant_name, country, state_region, city, plant_type', '', 'is_active, is_current, country, plant_type', 'Join from fact tables using plant_key to dim_plant.plant_key. Prefer rows where is_current = 1 for current-state reporting.', 'daily', 'Use this as the source of plant names and locations. Do not aggregate measures from this table.'),
('manufacturing_dw', 'dim_product', 'dimension', 'One row per product version', 'Describes raw materials, components, subassemblies, and finished goods', '', 'product_id, product_name, product_type, product_family, product_category, base_uom', 'standard_cost, standard_price, weight_kg, shelf_life_days', 'is_active, is_current, product_type, product_family, product_category', 'Join from all inventory, production, quality, receipt, shipment, and BOM tables using product_key.', 'daily', 'This is the central business dimension. Use product_type to separate raw materials from finished goods.'),
('manufacturing_dw', 'dim_supplier', 'dimension', 'One row per supplier version', 'Stores supplier master data and sourcing attributes used in procurement and quality analysis', '', 'supplier_id, supplier_name, supplier_category, country, payment_terms', 'lead_time_days, quality_rating', 'is_active, is_current, supplier_category, country, is_preferred', 'Join from fact_material_receipt and fact_quality_inspection using supplier_key to dim_supplier.supplier_key.', 'daily', 'Use quality_rating and lead_time_days for supplier performance analysis.'),
('manufacturing_dw', 'dim_warehouse', 'dimension', 'One row per warehouse version', 'Describes physical and logical storage locations such as raw material, WIP, and finished goods warehouses', '', 'warehouse_id, warehouse_name, warehouse_type, temperature_zone, plant_key', '', 'is_active, is_current, warehouse_type, temperature_zone', 'Join from fact tables using warehouse_key to dim_warehouse.warehouse_key, then to dim_plant through plant_key if needed.', 'daily', 'Useful for inventory and shipment analysis by storage location.'),
('manufacturing_dw', 'dim_work_center', 'dimension', 'One row per work center version', 'Describes machine groups and operational work centers used in production execution', '', 'work_center_id, work_center_name, department_name, work_center_type, plant_key', 'capacity_hours_per_day', 'is_active, is_current, department_name, work_center_type, is_bottleneck', 'Join from fact_production_operation using work_center_key to dim_work_center.work_center_key.', 'daily', 'Use for throughput, downtime, bottleneck, and labor analysis.'),
('manufacturing_dw', 'fact_inventory_snapshot', 'fact', 'One row per snapshot timestamp, plant, warehouse, product, and batch', 'Stores inventory balances and values at periodic snapshot times', 'snapshot_ts', 'date_key, plant_key, warehouse_key, product_key, batch_number, inventory_uom', 'quantity_on_hand, quantity_reserved, quantity_available, inventory_value', 'snapshot_ts, plant_key, warehouse_key, product_key, batch_number', 'Join to dim_plant via plant_key, dim_warehouse via warehouse_key, dim_product via product_key, dim_date via date_key.', 'hourly or daily snapshot', 'Do not sum across multiple snapshots unless the question explicitly asks for a time trend. For current inventory, use the latest snapshot.'),
('manufacturing_dw', 'fact_material_receipt', 'fact', 'One row per material receipt transaction', 'Captures inbound receipts from suppliers including accepted and rejected quantities', 'receipt_ts', 'date_key, supplier_key, plant_key, warehouse_key, product_key, purchase_order_number, batch_number, receipt_uom', 'quantity_received, quantity_accepted, quantity_rejected, unit_cost, total_cost', 'receipt_ts, supplier_key, plant_key, warehouse_key, product_key, purchase_order_number', 'Join to dim_supplier, dim_plant, dim_warehouse, dim_product, and dim_date using the corresponding surrogate keys.', 'near realtime or hourly', 'Useful for supplier performance, receiving volume, and incoming quality analysis.'),
('manufacturing_dw', 'fact_production_operation', 'fact', 'One row per production order operation event or summarized operation record', 'Captures operation-level execution metrics such as setup, runtime, downtime, and output', 'event_ts', 'production_order_id, operation_sequence, work_center_key, plant_key, product_key, operation_name, operation_status', 'setup_time_minutes, run_time_minutes, downtime_minutes, labor_hours, machine_hours, good_quantity, scrap_quantity', 'event_ts, work_center_key, plant_key, product_key, operation_status', 'Join to dim_work_center, dim_plant, and dim_product using surrogate keys. Join to fact_production_order by production_order_id when order context is needed.', 'near realtime', 'Use for OEE-style analysis, downtime analysis, and work-center productivity.'),
('manufacturing_dw', 'fact_production_order', 'fact', 'One row per production order', 'Tracks planned versus actual production order execution, quantities, and costs', 'planned_start_ts', 'plant_key, product_key, order_status, due_date_key, order_uom', 'order_quantity, completed_quantity, scrapped_quantity, standard_cost_total, actual_cost_total', 'order_status, planned_start_ts, planned_end_ts, actual_start_ts, actual_end_ts, plant_key, product_key', 'Join to dim_plant and dim_product using surrogate keys. Join to dim_date through due_date_key for due-date reporting.', 'near realtime or hourly', 'Use this for order-level KPIs such as completion rate, scrap rate, and cost variance.'),
('manufacturing_dw', 'fact_quality_inspection', 'fact', 'One row per quality inspection event', 'Captures inspection outcomes for incoming, in-process, final, and audit checks', 'inspection_ts', 'date_key, plant_key, product_key, supplier_key, production_order_id, batch_number, inspection_type, defect_code, inspection_result', 'inspected_quantity, accepted_quantity, rejected_quantity, reworked_quantity', 'inspection_ts, inspection_type, plant_key, product_key, supplier_key, defect_code, inspection_result', 'Join to dim_plant, dim_product, dim_supplier, and dim_date using surrogate keys. Optionally join to fact_production_order through production_order_id.', 'near realtime', 'Use for yield, defect, supplier quality, and rework analysis.'),
('manufacturing_dw', 'fact_shipment', 'fact', 'One row per outbound shipment transaction line', 'Captures outbound shipments to customers with quantities and financial amounts', 'shipment_ts', 'date_key, customer_key, plant_key, warehouse_key, product_key, sales_order_number, batch_number, shipment_uom', 'shipped_quantity, net_sales_amount, freight_amount', 'shipment_ts, customer_key, plant_key, warehouse_key, product_key, sales_order_number', 'Join to dim_customer, dim_plant, dim_warehouse, dim_product, and dim_date using the corresponding surrogate keys.', 'near realtime or hourly', 'Use for fulfillment, outbound volume, revenue proxy, and customer mix analysis.'),
('manufacturing_dw', 'table_descriptions', 'metadata', 'One row per documented table', 'Stores table-level business descriptions used for metadata and AI guidance', '', 'database_name, table_name', '', 'database_name, table_name', 'Join to metadata views by database_name and table_name.', 'manual', 'Supplemental metadata registry.');

INSERT INTO `manufacturing_dw`.`table_descriptions` (`database_name`, `table_name`, `table_description`) VALUES
('manufacturing_dw', 'bom_component', 'Bridge table representing the bill of materials between parent products and component products'),
('manufacturing_dw', 'dim_customer', 'Dimension table with customer master data for outbound shipments'),
('manufacturing_dw', 'dim_date', 'Calendar date dimension used for reporting and time-based analysis'),
('manufacturing_dw', 'dim_plant', 'Dimension table with descriptive information about manufacturing plants'),
('manufacturing_dw', 'dim_product', 'Dimension table with product, material, and item master attributes'),
('manufacturing_dw', 'dim_supplier', 'Dimension table with supplier master data and sourcing attributes'),
('manufacturing_dw', 'dim_warehouse', 'Dimension table with descriptive information about warehouses and storage areas'),
('manufacturing_dw', 'dim_work_center', 'Dimension table with work center and machine group attributes'),
('manufacturing_dw', 'fact_inventory_snapshot', 'Snapshot fact table with inventory balances by time, plant, warehouse, product, and batch'),
('manufacturing_dw', 'fact_material_receipt', 'Transactional fact table with inbound supplier receipts and receiving quality outcomes'),
('manufacturing_dw', 'fact_production_operation', 'Fact table with operation-level execution metrics such as runtime, downtime, and output'),
('manufacturing_dw', 'fact_production_order', 'Fact table with production order planning, execution, output, and cost metrics'),
('manufacturing_dw', 'fact_quality_inspection', 'Fact table with incoming, in-process, and final quality inspection results'),
('manufacturing_dw', 'fact_shipment', 'Transactional fact table with outbound customer shipments and commercial amounts'),
('manufacturing_dw', 'table_descriptions', 'Registry table containing table-level business descriptions for the warehouse');

