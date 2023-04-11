set gp_autostats_mode=none;
INSERT INTO tpcds.store_sales SELECT * FROM ext_tpcds.store_sales;
