#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")

step="ddl"
init_log "${step}"
get_version

filter="gpdb"

#Create tables
for i in "${PWD}"/*."${filter}".*.sql; do
  start_log
  id=$(basename "${i}" | awk -F '.' '{print $1}')
  schema_name=$(basename "${i}" | awk -F '.' '{print $2}')
  table_name=$(basename "${i}" | awk -F '.' '{print $3}')

  if [ "${RANDOM_DISTRIBUTION}" == "true" ]; then
    DISTRIBUTED_BY="DISTRIBUTED RANDOMLY"
  else
    while IFS= read -r z; do
      table_name2=$(echo "${z}" | awk -F '|' '{print $2}')
      if [ "${table_name2}" == "${table_name}" ]; then
        distribution=$(echo "${z}" | awk -F '|' '{print $3}')
      fi
    done < "${PWD}"/distribution.txt
    DISTRIBUTED_BY="DISTRIBUTED BY (${distribution})"
  fi

  log_time "psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f ${i} -v SMALL_STORAGE=\"${SMALL_STORAGE}\" -v MEDIUM_STORAGE=\"${MEDIUM_STORAGE}\" -v LARGE_STORAGE=\"${LARGE_STORAGE}\" -v DISTRIBUTED_BY=\"${DISTRIBUTED_BY}\""
  psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f "${i}" -v SMALL_STORAGE="${SMALL_STORAGE}" -v MEDIUM_STORAGE="${MEDIUM_STORAGE}" -v LARGE_STORAGE="${LARGE_STORAGE}" -v DISTRIBUTED_BY="${DISTRIBUTED_BY}"

  print_log "${id}" "${schema_name}" "${table_name}" "0"
done

for i in "${PWD}"/*.ext_tpcds.*.sql; do
  start_log

  id=$(basename "${i}" | awk -F '.' '{print $1}')
  schema_name=$(basename "${i}" | awk -F '.' '{print $2}')
  table_name=$(basename "${i}" | awk -F '.' '{print $3}')

  counter=0


  # specify location of data foir exttables
  LOCATION="'gpfdist://$(hostname):${GPFDIST_PORT}/${table_name}_[0-9]*_[0-9]*.dat'"

  log_time "psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f ${i} -v LOCATION=\"${LOCATION}\""
  psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f "${i}" -v LOCATION="${LOCATION}"

  print_log "${id}" "${schema_name}" "${table_name}" "0"
done

SetSearchPath="ALTER DATABASE ${PGDATABASE} SET search_path=tpcds, \"\${user}\", public"
psql -c "${SetSearchPath}"

start_log

#log_time "Set search_path for database gpadmin"
#psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${SetSearchPath}"

print_log "${id}" "${schema_name}" "${table_name}" "0"

echo "Finished ${step}"
