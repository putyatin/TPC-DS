#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")


get_version
filter="gpdb"

gpfdist -p "${GPFDIST_PORT}" -d "${GEN_DATA_PATH}" &> "gpfdist.${GPFDIST_PORT}.log" &
gpfdist_pid=$!

if [ "${gpfdist_pid}" -ne "0" ]; then
  sleep 0.4
  count=$(pgrep gpfdist | grep -c "${gpfdist_pid}" || true)
  if [ "${count}" -eq "1" ]; then
    echo "Started gpfdist on port ${GPFDIST_PORT}"
  else
    echo "Unable to start gpfdist on port ${GPFDIST_PORT}"
    exit 1
  fi
else
  echo "Unable to start background process for gpfdist on port ${GPFDIST_PORT}"
  exit 1
fi

# truncate table
echo "truncating all tables ..."
psql -v ON_ERROR_STOP=1 -af "${PWD}/000.truncate.tables.sql"
echo "finished truncate ..."

step="load"
init_log "${step}"
schema_name=tpcds

for i in "${PWD}"/*."${filter}".*.sql; do
  start_log
  id=$(basename "${i}" | awk -F '.' '{print $1}')
  table_name=$(basename "${i}" | awk -F '.' '{print $3}')

  log_time "psql -v ON_ERROR_STOP=1 -f ${i} | grep INSERT | awk -F ' ' '{print \$3}'"
  tuples=$(
    psql -v ON_ERROR_STOP=1 -f "${i}" | grep INSERT | awk -F ' ' '{print $3}'
    exit "${PIPESTATUS[0]}"
  )

  print_log "${id}" "${schema_name}" "${table_name}" "${tuples}"
  
done

# stop_gpfdist
kill ${gpfdist_pid}
log_time "finished loading tables"

step="analyze"
init_log "${step}"

for i in "${PWD}"/*."${filter}".*.sql; do
  start_log
  id=$(basename "${i}" | awk -F '.' '{print $1}')
  table_name=$(basename "${i}" | awk -F '.' '{print $3}')

  log_time "psql -v ON_ERROR_STOP=1 -f ${i} | grep INSERT | awk -F ' ' '{print \$3}'"
  psql -v ON_ERROR_STOP=1 -c "ANALYZE ${schema_name}.${table_name}"

  print_log "${id}" "${schema_name}" "${table_name}" 0
  
done




echo "Finished ${step}"
