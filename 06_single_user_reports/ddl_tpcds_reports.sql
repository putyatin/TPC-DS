DROP SCHEMA IF EXISTS tpcds_reports CASCADE;
CREATE SCHEMA tpcds_reports;
CREATE TABLE tpcds_reports.report
(step varchar(20), id int, description varchar, tuples bigint, duration time, start_epoch_seconds bigint, end_epoch_seconds bigint)
DISTRIBUTED BY (id);

