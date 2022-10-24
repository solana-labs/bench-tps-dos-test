#!/usr/bin/env bash
set -ex
discord_bot_name="bench-tps dos ${test_type}"
discord_avatar_url="$DISCORD_AVATAR_URL"
[[ -z "$DISCORD_WEBHOOK"  ]]&&echo "ERROR : DISCORD_WEBHOOK=$DISCORD_WEBHOOK"&&exit 1

# give discord_txt a value to send to discord channel via webhook
function discord_send(){
    curl -H "Content-Type: application/json" -H "Expect: application/json" -X POST "${DISCORD_WEBHOOK}" -d "${discord_txt}" 2>/dev/null
}

printf -v test_config '**Test Configuration:**\\n```%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n```' \
		"test-type = $test_type" "client = $client" "branch = $SOLANA_BUILD_BRANCH" "commit = $git_commit" \
		"cluster version = $cluster_version" "bench-tps-clients = $num_clients" "read-client-keys = $client_keypair_path" \
		"duration = $duration" "tx_count = $tx_count" "thread_batch_sleep_ms = $thread_batch_sleep_ms" "durable_nonce = $USE_DURABLE_NONCE"

# Construct Slack Result_Details Report
printf -v time_range 'time range: %s ~ %s' \
        "$(date --rfc-3339=seconds -u -d @$start_time)" "$(date --rfc-3339=seconds -u -d @$stop_time)"
printf -v slot_range '%s\\n%s' \
        "$start_slot_txt" "$end_slot_txt"
printf -v s_tx_count '%s\\n%s\\n%s\\n%s' \
         "$mean_tx_count_txt" "$max_tx_count_txt" "$p90_tx_count_txt" "$p99_tx_count_txt"
printf -v s_tower_vote_dist '%s\\n%s\\n%s\\n%s' \
        "$mean_tower_vote_distance_txt" "$max_tower_vote_distance_txt" "$p90_tower_vote_distance_txt" "$p99_tower_vote_distance_txt"
printf -v s_optimistic_slot_elapsed '%s\\n%s\\n%s\\n%s' \
        "$mean_optimistic_slot_elapsed_txt" "$max_optimistic_slot_elapsed_txt" "$p90_optimistic_slot_elapsed_txt" "$p99_optimistic_slot_elapsed_txt"
printf -v s_ct_stats_block_cost '%s\\n%s\\n%s\\n%s' \
        "$mean_ct_stats_block_cost_txt" "$max_ct_stats_block_cost_txt" "$p90_ct_stats_block_cost_txt" "$p99_ct_stats_block_cost_txt"
printf -v s_ct_stats_tx_count '%s\\n%s\\n%s\\n%s' \
        "$mean_mean_ct_stats_tx_count_txt" "$max_mean_ct_stats_tx_count_txt" "$p90_mean_ct_stats_tx_count_txt" "$p99_mean_ct_stats_tx_count_txt"
printf -v s_ct_stats_number_of_accts '%s\\n%s\\n%s\\n%s' \
        "$mean_ct_stats_num_of_accts_txt" "$max_ct_stats_num_of_accts_txt" "$p90_ct_stats_num_of_accts_txt" "$p99_ct_stats_num_of_accts_txt"
printf -v blocks_fill '%s\\n%s\\n%s\\n%s\\n%s' \
        "$total_blocks_txt" "$blocks_fill_50_txt" "$blocks_fill_90_txt" "$blocks_fill_50_percent_txt" "$blocks_fill_90_percent_txt"
printf -v buildkite_link  '%s' "[Buildkite]($BUILDKITE_BUILD_URL)"
printf -v grafana_link  '%s' "[Grafana]($gf_url)"
# compose report without link
printf -v test_report '%s    %s\\n%s\\n**Test Details:**\\n```%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n```' \
        "$grafana_link" "$buildkite_link" \
        "$test_config" "$time_range" "$slot_range" \
        "$s_tx_count" "$s_tower_vote_dist" "$s_optimistic_slot_elapsed" \
        "$s_ct_stats_block_cost" "$s_ct_stats_tx_count" "$s_ct_stats_number_of_accts" "$blocks_fill" 

# compose discord message
d_username="\"username\": \"${discord_bot_name}\""
d_content="\"content\": \"${test_report}\""
d_avatar="\"avatar_url\": \"${discord_avatar_url}\""
discord_txt="{${d_avatar},${d_username},${d_content}}"
