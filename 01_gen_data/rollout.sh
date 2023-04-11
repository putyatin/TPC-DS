#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")

if [ "${GEN_DATA_SCALE}" == "" ]; then
  echo "You must provide the scale as a parameter in terms of Gigabytes."
  echo "Example: ./rollout.sh 100"
  echo "This will create 100 GB of data for this test."
  exit 1
fi

function get_count_generate_data() {
  count=$(ps -ef | grep generate_data.sh | grep -v grep | wc -l)
}

function kill_orphaned_data_gen() {
  echo "kill any orphaned dsdgen processes on segment hosts"
  # always return true even if no processes were killed
  pkill dsdgen || true
}

function gen_data() {
  echo "parallel: $PARALLEL"
  for i in $(seq 1 $PARALLEL); do
    CHILD=${i}
    echo "./generate_data.sh ${GEN_DATA_SCALE} ${CHILD} ${PARALLEL} ${GEN_DATA_PATH} &> generate_data.${CHILD}.log &"
    ./01_gen_data/generate_data.sh ${GEN_DATA_SCALE} ${CHILD} ${PARALLEL} ${GEN_DATA_PATH} &> generate_data.${CHILD}.log &
  done
  wait
}

step="gen_data"
init_log "${step}"
start_log

if [ "${GEN_NEW_DATA}" == "true" ]; then
  kill_orphaned_data_gen
  gen_data

  echo ""
  get_count_generate_data
  echo "Now generating data.  This may take a while."
  minutes=0
  echo -ne "Generating data duration: "
  tput sc
  while [ "$count" -gt "0" ]; do
    tput rc
    echo -ne "${minutes} minute(s)"
    sleep 60
    minutes=$((minutes + 1))
    get_count_generate_data
  done

  echo ""
  echo "Done generating data"
  echo ""
fi

echo "Generate queries based on scale"
cd "${PWD}"
# "${PWD}"/generate_queries.sh

print_log "1" "tpcds" "gen_data" "0"

echo "Finished ${step}"
