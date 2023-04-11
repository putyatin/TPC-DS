set gp_autostats_mode=none;
INSERT INTO tpcds.customer_demographics SELECT * FROM ext_tpcds.customer_demographics;
