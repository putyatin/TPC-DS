set gp_autostats_mode=none;
INSERT INTO tpcds.catalog_sales SELECT * FROM ext_tpcds.catalog_sales;
