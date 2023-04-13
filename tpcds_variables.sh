# shellcheck disable=SC2148
# environment options
export BENCH_ROLE="user01"
export GPFDIST_PORT=8080
export GEN_DATA_PATH=/tpcds-data
export PARALLEL=2

# to connect directly to GP
export PGPORT="5432"

# benchmark options
export GEN_DATA_SCALE=2
export MULTI_USER_COUNT=2

# step options
# step 00_compile_tpcds
export RUN_COMPILE_TPCDS="false"

# step 01_gen_data
# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# the queries need to be regenerated with the new role
# change BENCH_ROLE and set RUN_GEN_DATA to true and GEN_NEW_DATA to false
# GEN_NEW_DATA only takes affect when RUN_GEN_DATA is true, and the default setting
# should true under normal circumstances
export RUN_GEN_DATA="false"
export GEN_NEW_DATA="false"

# step 02_init
# For Managed Greenplum should be always false
export RUN_INIT="false"

# step 03_ddl
export RUN_DDL="false"

# step 04_load
export RUN_LOAD="false"

# step 05_sql
export RUN_SQL="false"

# step 06_single_user_reports
export RUN_SINGLE_USER_REPORTS="false"

# step 07_multi_user
export RUN_QGEN="false"
export RUN_MULTI_USER="true"

# step 08_multi_user_reports
export RUN_MULTI_USER_REPORTS="false"

# step 09_score
export RUN_SCORE="false"

# misc options
export SINGLE_USER_ITERATIONS="1"
export EXPLAIN_ANALYZE="false"
export RANDOM_DISTRIBUTION="false"


OSVERSION=$(uname)
MASTER_HOST=$(hostname -s)
export OSVERSION
export MASTER_HOST
