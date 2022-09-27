#!/usr/bin/env bash
msg=$(jq -n --arg v "$header" '[$v]')

[[ -z "$SLACK_WEBHOOK"  ]]&&echo "ERROR : SLACK_WEBHOOK=$SLACK_WEBHOOK"&&exit 1

slack_send(){
    sdata=$(jq --null-input --arg val "$slack_text" '{"blocks":$val}')
    curl -X POST -H 'Content-type: application/json' --data "$sdata" $SLACK_WEBHOOK    
}


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
## Compose block content
conf='"```'${test_config}'```"'
detail='"```'${s_detail_ret}'```"'
## compose block
b1="{
		\"type\": \"actions\",
		\"elements\": [
			{
				\"type\": \"button\",
				\"text\": {
					\"type\": \"plain_text\",
					\"text\": \"Grafana\"
				},
				\"url\": \"${gf_url}\"
			},
			{
				\"type\": \"button\",
				\"text\": {
					\"type\": \"plain_text\",
					\"text\": \"Buildkite Job\"
				},
				\"url\": \"${BUILDKITE_BUILD_URL}\"
			}
		]
	}"
b2='{
			"type": "header",
			"text": {
				"type": "plain_text",
				"text": "Test_Configuration",
				"emoji": true
			}
	}'
b3="{\"type\": \"section\",\"text\": {\"type\":\"mrkdwn\",\"text\": ${conf}}}"
b4='{
	    "type": "header",
		"text": {
			"type": "plain_text",
			"text": "Result_Details",
			"emoji": true
		}
	}'
b5="{\"type\": \"section\",\"text\": {\"type\":\"mrkdwn\",\"text\": ${detail}}}"

# compose final message
act_elem="[${b1},${b2},${b3},${b4},${b5}]"
# echo $act_elem | jq .
slack_text=$act_elem
