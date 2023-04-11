set gp_autostats_mode=none;
INSERT INTO tpcds.web_sales SELECT * FROM ext_tpcds.web_sales;
