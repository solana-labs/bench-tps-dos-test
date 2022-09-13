#!/usr/bin/env bash
## solana-bench-tps config
set -ex
# read env
source dos-report-env.sh
if [[ ! $SLACK_WEBHOOK ]];then
	echo SLACK_WEBHOOK env not found, exit
	exit 1
fi

if [[ ! $START_TIME ]];then
	echo START_TIME env not found, exit
	exit 1
fi

if [[ ! $START_TIME2 ]];then
	echo START_TIME2 env not found, exit
	exit 1
fi
if [[ ! $STOP_TIME ]];then
	echo STOP_TIME env not found, exit
	exit 1
fi

if [[ ! $STOP_TIME2 ]];then
	echo STOP_TIME2 env not found, exit
	exit 1
fi

# check ENV
if [[ ! $INFLUX_TOKEN ]];then
	echo INFLUX_TOKEN env not found, exit
	exit 1
fi
if [[ ! $INFLUX_ORG_NAME ]];then
	echo INFLUX_ORG_NAME env not found, exit
	exit 1
fi

if [[ ! $KEYPAIR_FILE ]];then
	KEYPAIR_FILE="NA"
	echo KEYPAIR_FILE env not found, use $KEYPAIR_FILE
fi

if [[ ! $INFLUX_HOST ]];then
	INFLUX_HOST="https://us-west-2-2.aws.cloud2.influxdata.com"
	echo INFLUX_HOST env not found, use $INFLUX_HOST
fi
if [[ ! $DURATION ]];then
	DURATION="NA"
	echo DURATION env not found, use $DURATION
fi
if [[ ! $TX_COUNT ]];then
	TX_COUNT="NA"
	echo TX_COUNT env not found, use $TX_COUNT
fi

if [[ ! $TEST_TYPE ]];then
	TEST_TYPE="NA"
	echo TEST_TYPE env not found, use $TEST_TYPE
fi

if [[ ! $NUM_CLIENT ]];then
	NUM_CLIENT="NA"
	echo NUM_CLIENT env not found, use $NUM_CLIENT
fi
if [[ ! $GIT_COMMIT ]];then
	GIT_COMMIT="NA"
	echo GIT_COMMIT env not found, use $GIT_COMMIT
fi
if [[ ! $CLUSTER_VERSION ]];then
	CLUSTER_VERSION="NA"
	echo CLUSTER_VERSION env not found, use $CLUSTER_VERSION
fi

if [[ ! $SOLANA_BUILD_BRANCH ]];then
	SOLANA_BUILD_BRANCH="NA"
	echo SOLANA_BUILD_BRANCH env not found, use $SOLANA_BUILD_BRANCH
fi
if [[ ! $USE_DURABLE_NONCE ]];then
	USE_DURABLE_NONCE="false"
	echo USE_DURABLE_NONCE env not found, use $USE_DURABLE_NONCE
fi
if [[ ! $THREAD_BATCH_SLEEP_MS ]];then
	THREAD_BATCH_SLEEP_MS=NA
	echo THREAD_BATCH_SLEEP_MS env not found, use $THREAD_BATCH_SLEEP_MS
fi

if [[ -n $BUILDKITE_BUILD_URL ]] ; then
	BUILD_BUTTON_TEXT="Build Kite Job"
else
	BUILD_BUTTON_TEXT="Build URL not defined"
    BUILDKITE_BUILD_URL="https://buildkite.com/solana-labs/"
fi

## Configuration
test_type=$TEST_TYPE
client="tpu"
git_commit=$GIT_COMMIT
cluster_version=$CLUSTER_VERSION
num_clients=$NUM_CLIENT
client_keypair_path="keypair-configs/$KEYPAIR_FILE"
duration=$DURATION
tx_count=$TX_COUNT
thread_batch_sleep_ms=$THREAD_BATCH_SLEEP_MS
API_V2_HOST="${INFLUX_HOST}/api/v2/query?org=${INFLUX_ORG_NAME}"
HEADER_AUTH="Authorization: Token ${INFLUX_TOKEN}"
CURL_TIMEOUT=12
start_time=$START_TIME
start_time2=$START_TIME2
stop_time=$STOP_TIME
stop_time2=$STOP_TIME2

## make sure 
source influx_data.sh

query(){
	local retry=0
	for retry in 0 1 2
	do
		if [[ $retry -gt 0 ]];then
			printf "start retry:%s\n%s\n" $retry
			sleep 2
		fi
		if [[ -z "$1" ]];then
			echo "query command is empty!"
			echo "$1"
		fi
		curl --connect-timeout ${CURL_TIMEOUT} --request POST \
		"${API_V2_HOST}" \
		--header "${HEADER_AUTH}" \
		--header 'Accept: application/csv' \
		--header 'Content-type: application/vnd.flux' \
		--data "$1" > query.result
		local n=0
		local arr=()
		local line
		while IFS= read -r line
		do
			if [[ ${#line} -gt 1 ]];then # last line is empty but length=1
				arr+=("$line")
				let n=n+1
			fi
		done < query.result
		
		if [[ $n -gt 1 ]]; then
			printf "%s\n" "valid return"
			break
		else # empty or error
			printf "*retry:%s\nquery error:%s\n" $retry ${arr[0]}
		fi
	done 
}

for f in "${!FLUX[@]}"
do
	echo "----FLUX ($count) $f----"
	echo "${FLUX[$f]}"
done

declare -A FLUX_RESULT # collect results
for f in "${!FLUX[@]}"
do

	if [[ -z "${FLUX[${f}]}" ]];then
		printf "***%s %s\n%s\n" $f "is return zero-length" ${FLUX[${f}]}
	fi
	query "${FLUX[${f}]}"
	if [[ -f 'query.result' ]];then
			
		FLUX_RESULT[${f}]="`cat query.result`"
		printf "%s %s\n" $f ${FLUX_RESULT[${f}]}
	else
		printf "%s%s\n" "$f" "no query.result"
	fi
	sleep 1
done

## For debug , printout each result of
# for r in "${!FLUX_RESULT[@]}"
# do
#   result=${FLUX_RESULT[${r}]}
# 	echo "---- $r result ----"
# 	echo "$result"
# 	echo "-----$r end-------"
# done

##  result should be like this 
## ,result,table,_value
## ,_result,0,137371131

get_value() {
	local arr=()
	local n=0
	local line
	while IFS= read -r line
	do
		if [[ ${#line} -gt 1 ]];then # last line is empty but length=1
			arr+=("$line")
			let n=n+1
		fi
	done <<< $result_input

	if [[ $n -gt 1 ]]; then
		while IFS=, read -r empty result table val host_id
		do	
		_value="$(echo "$val"|tr -d '\r\n')" #return value include a new line
		done <<< "${arr[1]}"
	else
		_value="na"
	fi
}
result_detail=""
# slot
result_input=${FLUX_RESULT['start_slot']}
get_value
start_slot_txt="start_slot: $_value"
result_input=${FLUX_RESULT['end_slot']}
get_value
end_slot_txt="end_slot: $_value"

#  TPS
result_input=${FLUX_RESULT['mean_tx_count']}
get_value
mean_tx_count_txt="mean_tps: $_value"
result_input=${FLUX_RESULT['max_tx_count']}
get_value
max_tx_count_txt="max_tps: $_value"
result_input=${FLUX_RESULT['p90_tx_count']}
get_value
p90_tx_count_txt="90th_tx_count: $_value"
result_input="${FLUX_RESULT['p99_tx_count']}"
get_value
p99_tx_count_txt="99th_tx_count: $_value"

# tower distance
result_input="${FLUX_RESULT['mean_tower_vote_distance']}"
echo "${FLUX_RESULT['mean_tower_vote_distance']}"
get_value
mean_tower_vote_distance_txt="mean_tower_vote_distance: $_value"
result_input="${FLUX_RESULT['max_tower_vote_distance']}"
get_value
max_tower_vote_distance_txt="max_tower_vote_distance: $_value"
result_input="${FLUX_RESULT['min_tower_vote_distance']}"
get_value
result_input="${FLUX_RESULT['p90_tower_vote_distance']}"
get_value
p90_tower_vote_distance_txt="90th_tower_vote_distance: $_value"
result_input="${FLUX_RESULT['p99_tower_vote_distance']}"
get_value
p99_tower_vote_distance_txt="99th_tower_vote_distance: $_value"

# optimistic_slot_elapsed
result_input="${FLUX_RESULT['mean_optimistic_slot_elapsed']}"
get_value
mean_optimistic_slot_elapsed_txt="mean_optimistic_slot_elapsed: $_value"
result_input="${FLUX_RESULT['max_optimistic_slot_elapsed']}"
get_value
max_optimistic_slot_elapsed_txt="max_optimistic_slot_elapsed: $_value"
result_input="${FLUX_RESULT['p90_optimistic_slot_elapsed']}"
get_value
p90_optimistic_slot_elapsed_txt="90th_optimistic_slot_elapsed: $_value"
result_input="${FLUX_RESULT['p99_optimistic_slot_elapsed']}"
get_value
p99_optimistic_slot_elapsed_txt="99th_optimistic_slot_elapsed: $_value"

# ct_stats_block_cost
result_input="${FLUX_RESULT['mean_ct_stats_block_cost']}"
get_value
mean_ct_stats_block_cost_txt="mean_cost_tracker_stats_block_cost: $_value"
result_input="${FLUX_RESULT['max_ct_stats_block_cost']}"
get_value
max_ct_stats_block_cost_txt="max_cost_tracker_stats_block_cost: $_value"
result_input="${FLUX_RESULT['p90_ct_stats_block_cost']}"
get_value
p90_ct_stats_block_cost_txt="90th_cost_tracker_stats_block_cost: $_value"
result_input="${FLUX_RESULT['p99_ct_stats_block_cost']}"
get_value
p99_ct_stats_block_cost_txt="99th_cost_tracker_stats_block_cost: $_value"

# ct_stats_block_cost
result_input="${FLUX_RESULT['mean_ct_stats_transaction_count']}"
get_value
mean_mean_ct_stats_tx_count_txt="mean_cost_tracker_stats_transaction_count: $_value"
result_input="${FLUX_RESULT['max_ct_stats_transaction_count']}"
get_value
max_mean_ct_stats_tx_count_txt="max_cost_tracker_stats_transaction_count: $_value"
result_input="${FLUX_RESULT['p90_ct_stats_transaction_count']}"
get_value
p90_mean_ct_stats_tx_count_txt="90th_cost_tracker_stats_transaction_count: $_value"
result_input="${FLUX_RESULT['p99_ct_stats_transaction_count']}"
get_value
p99_mean_ct_stats_tx_count_txt="99th_cost_tracker_stats_transaction_count: $_value"

# ct_stats_number_of_accounts
result_input="${FLUX_RESULT['mean_ct_stats_number_of_accounts']}"
get_value
mean_ct_stats_num_of_accts_txt="mean_cost_tracker_stats_number_of_accounts: $_value"
result_input="${FLUX_RESULT['max_ct_stats_number_of_accounts']}"
get_value
max_ct_stats_num_of_accts_txt="max_cost_tracker_stats_number_of_accounts: $_value"
result_input="${FLUX_RESULT['p90_ct_stats_number_of_accounts']}"
get_value
p90_ct_stats_num_of_accts_txt="90th_cost_tracker_stats_number_of_accounts: $_value"
result_input="${FLUX_RESULT['p99_ct_stats_number_of_accounts']}"
get_value
p99_ct_stats_num_of_accts_txt="99th_cost_tracker_stats_number_of_accounts: $_value"

# # blocks fill
result_input="${FLUX_RESULT['total_blocks']}"
get_value
if [[ "$_value" == "na" ]];then
	_value=0
fi
total_blocks_tmp=$_value
total_blocks_txt="numb_total_blocks: $_value"

result_input="${FLUX_RESULT['blocks_fill_50']}"
get_value
blocks_fill_50_txt="numb_blocks_50_full: $_value"
if [[ "$_value" == "na" || $total_blocks_tmp -eq 0 ]];then
	percent_value="0%"
else 
	echo value : $(echo "($_value/$total_blocks_tmp)*100" | bc)
	printf -v percent_value "%.0f%s" $(echo "scale=2;($_value/$total_blocks_tmp)*100" | bc) "%"
fi
blocks_fill_50_percent_txt="blocks_50_full: $percent_value"

result_input="${FLUX_RESULT['blocks_fill_90']}"
get_value
blocks_fill_90_txt="numb_blocks_90_full: $_value"
if [[ "$_value" == "na" || $total_blocks_tmp -eq 0 ]];then
	percent_value="0%"
else 
	printf -v percent_value "%.0f%s" $(echo "scale=2;($_value/$total_blocks_tmp)*100" | bc) "%"
fi
blocks_fill_90_percent_txt="blocks_90_full: $percent_value"

## Construct Grafana button
gf_from=$(echo "scale=2;${start_time}*1000" | bc)
gf_to=$(echo "scale=2;${stop_time}*1000" | bc)
gf_prefix="https://metrics.solana.com:3000/d/monitor-beta2/cluster-telemetry-beta-1s-aggregation?orgId=1&var-datasource=InfluxDB-testnet&var-testnet=tds&var-hostid=All&from="
printf -v gf_url "%s%s%s%s" $gf_prefix $gf_from "&to=" $gf_to

## Construct Test_Configuration
printf -v test_config "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
		"test-type = $test_type" "client = $client" "branch = $SOLANA_BUILD_BRANCH" "commit = $git_commit" \
		"cluster version = $cluster_version" "bench-tps-clients = $num_clients" "read-client-keys = $client_keypair_path" \
		"duration = $duration" "tx_count = $tx_count" "thread_batch_sleep_ms = $thread_batch_sleep_ms" "durable_nonce = $USE_DURABLE_NONCE"
		
# Construct Slack Result_Details Report
printf -v s_time_start "%s%s" "time_start: $(date --rfc-3339=seconds -u -d @$start_time)" "\\n"
printf -v s_time_end "%s%s" "time_end: $(date --rfc-3339=seconds -u -d @$stop_time)" "\\n"
printf -v s_slot "%s%s%s%s" $start_slot_txt "\\n" $end_slot_txt "\\n"
printf -v s_tx_count "%s%s%s%s%s%s%s%s%s%s" $mean_tx_count_txt "\\n" $max_tx_count_txt "\\n" $p90_tx_count_txt "\\n" $p99_tx_count_txt "\\n"
printf -v s_tower_vote_distance "%s%s%s%s%s%s%s%s" $mean_tower_vote_distance_txt "\\n" $max_tower_vote_distance_txt "\\n" $p90_tower_vote_distance_txt "\\n" $p99_tower_vote_distance_txt "\\n"
printf -v s_optimistic_slot_elapsed "%s%s%s%s%s%s%s%s" $mean_optimistic_slot_elapsed_txt "\\n" $max_optimistic_slot_elapsed_txt "\\n" $p90_optimistic_slot_elapsed_txt "\\n" $p99_optimistic_slot_elapsed_txt "\\n"
printf -v s_ct_stats_block_cost "%s%s%s%s%s%s%s%s" $mean_ct_stats_block_cost_txt "\\n" $max_ct_stats_block_cost_txt "\\n" $p90_ct_stats_block_cost_txt "\\n" $p99_ct_stats_block_cost_txt "\\n"
printf -v s_ct_stats_tx_count "%s%s%s%s%s%s%s%s" $mean_mean_ct_stats_tx_count_txt "\\n" $max_mean_ct_stats_tx_count_txt "\\n" $p90_mean_ct_stats_tx_count_txt "\\n" $p99_mean_ct_stats_tx_count_txt "\\n"
printf -v s_ct_stats_number_of_accts "%s%s%s%s%s%s%s%s" $mean_ct_stats_num_of_accts_txt "\\n" $max_ct_stats_num_of_accts_txt "\\n" $p90_ct_stats_num_of_accts_txt "\\n" $p99_ct_stats_num_of_accts_txt "\\n"
printf -v blocks_fill "%s%s%s%s%s%s%s%s%s%s" $total_blocks_txt "\\n" $blocks_fill_50_txt "\\n" $blocks_fill_90_txt "\\n" $blocks_fill_50_percent_txt "\\n"  $blocks_fill_90_percent_txt "\\n"
# combine all data
printf -v s_detail_ret "%s%s%s%s%s%s%s%s%s%s" $s_time_start $s_time_end $s_slot $s_tx_count $s_tower_vote_distance $s_optimistic_slot_elapsed $s_ct_stats_block_cost $s_ct_stats_tx_count $s_ct_stats_number_of_accts $blocks_fill

## Compose and Send Slack
conf='"```'${test_config}'```"'
detail='"```'${s_detail_ret}'```"'
source slack.sh
act_elem="[${b1},${b2},${b3},${b4},${b5}]"
# echo $act_elem | jq .
slack_text=$act_elem
slack_alert
