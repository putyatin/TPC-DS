#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${PWD}/../functions.sh
source_bashrc

GEN_DATA_SCALE=${1}
EXPLAIN_ANALYZE=${2}
RANDOM_DISTRIBUTION=${3}
MULTI_USER_COUNT=${4}
SINGLE_USER_ITERATIONS=${5}

if [[ "${GEN_DATA_SCALE}" == "" || "${EXPLAIN_ANALYZE}" == "" || "${RANDOM_DISTRIBUTION}" == "" || "${MULTI_USER_COUNT}" == "" || "${SINGLE_USER_ITERATIONS}" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false false 5 1"
	exit 1
fi

STEP="score"
init_log ${STEP}

LOAD_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples > 0")
ANALYZE_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples = 0")
QUERIES_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from (SELECT split_part(description, '.', 2) AS id, min(duration) AS duration FROM tpcds_reports.sql GROUP BY split_part(description, '.', 2)) as sub")
CONCURRENT_QUERY_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_testing.sql")

THROUGHPUT_ELAPSED_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select max(end_epoch_seconds) - min(start_epoch_seconds) from tpcds_testing.sql")

S_Q=${MULTI_USER_COUNT}
SF=${GEN_DATA_SCALE}

# Calculate operands for v1.3.1 of the TPC-DS score
Q_1_3_1=$(( 3 * S_Q * 99 ))
TPT_1_3_1=$(( QUERIES_TIME * S_Q ))
TTT_1_3_1=$(( 2 * CONCURRENT_QUERY_TIME ))
TLD_1_3_1=$(( S_Q * LOAD_TIME / 100 ))

# Calculate operands for v2.2.0 of the TPC-DS score
Q_2_2_0=$(( S_Q * 99 ))
TPT_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select ${QUERIES_TIME} * ${S_Q} / 3600.0")
TTT_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select 2 * ${THROUGHPUT_ELAPSED_TIME} / 3600.0")
TLD_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select 0.01 * ${S_Q} * ${LOAD_TIME} / 3600.0")

# Calculate scores using aggregation functions in psql
SCORE_1_3_1=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor( ${Q_1_3_1} * ${SF} / (${TPT_1_3_1} + ${TTT_1_3_1} + ${TLD_1_3_1}) )")
SCORE_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor( ${Q_2_2_0} * ${SF} / exp( (ln(${TPT_2_2_0}) + ln(${TTT_2_2_0}) + ln(${TLD_2_2_0})) / 3.0) )")

printf "Number of Streams (Sq)\t%d\n" "${S_Q}"
printf "Scale Factor (SF)\t%d\n" "${SF}"
printf "Load\t\t\t%d\n" "${LOAD_TIME}"
printf "Analyze\t\t\t%d\n" "${ANALYZE_TIME}"
printf "1 User Queries\t\t%d\n" "${QUERIES_TIME}"
printf "Concurrent Queries\t%d\n" "${CONCURRENT_QUERY_TIME}"
printf "Throughput Test Elapsed Time\t%d\n" "${THROUGHPUT_ELAPSED_TIME}"
printf "\n"
printf "TPC-DS v1.3.1 (QphDS@SF = floor(SF * Q / sum(TPT, TTT, TLD)))\n"
printf "Q (3 * Sq * 99)\t\t%d\n" "${Q_1_3_1}"
printf "TPT (seconds)\t\t%d\n" "${TPT_1_3_1}"
printf "TTT (seconds)\t\t%d\n" "${TTT_1_3_1}"
printf "TLD (seconds)\t\t%d\n" "${TLD_1_3_1}"
printf "Score\t\t\t%d\n" "${SCORE_1_3_1}"
printf "\n"
printf "TPC-DS v2.2.0 (QphDS@SF = floor(SF * Q / geomean(TPT, TTT, TLD)))\n"
printf "Q (Sq * 99)\t\t%d\n" "${Q_2_2_0}"
printf "TPT (hours)\t\t%.3f\n" "${TPT_2_2_0}"
printf "TTT (hours)\t\t%.3f\n" "${TTT_2_2_0}"
printf "TLD (hours)\t\t%.3f\n" "${TLD_2_2_0}"
printf "Score\t\t\t%d\n" "${SCORE_2_2_0}"

echo "Finished ""$step"
