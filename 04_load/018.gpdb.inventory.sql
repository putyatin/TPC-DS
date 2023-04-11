set gp_autostats_mode=none;
INSERT INTO tpcds.inventory SELECT * FROM ext_tpcds.inventory;
