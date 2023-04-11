#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")

step="single_user_reports"

psql -v ON_ERROR_STOP=1 -af "${PWD}"/ddl_tpcds_reports.sql

for logstep in gen_data ddl load analyze sql compile_tpcds; do
   sed "s/^/$logstep|/g" ${TPC_DS_DIR}/log/rollout_${logstep}.log | psql -ac "COPY tpcds_reports.report FROM STDIN DELIMITER '|'"
done

psql -v ON_ERROR_STOP=1 -q -t -A -c "select 'analyze ' || n.nspname || '.' || c.relname || ';' from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'tpcds_reports'" | psql -v ON_ERROR_STOP=1 -t -A -e

echo "********************************************************************************"
echo "Generate Data"
echo "********************************************************************************"
psql -F $'\t' -v ON_ERROR_STOP=1 -P pager=off -f "${PWD}"/gen_data_report.sql
echo ""
echo "********************************************************************************"
echo "Data Loads"
echo "********************************************************************************"
psql -F $'\t' -v ON_ERROR_STOP=1 -P pager=off -f "${PWD}"/loads_report.sql
echo ""
echo "********************************************************************************"
echo "Analyze"
echo "********************************************************************************"
psql -F $'\t' -v ON_ERROR_STOP=1 -P pager=off -f "${PWD}"/analyze_report.sql
echo ""
echo ""
echo "********************************************************************************"
echo "Queries"
echo "********************************************************************************"
psql -F $'\t' -v ON_ERROR_STOP=1 -P pager=off -f "${PWD}"/queries_report.sql
echo ""
echo "Finished ${step}"
