#!/usr/bin/env bash
# slot
source utils.sh
_start_slot='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${start_time2}')
			|> filter(fn: (r) => r._measurement == "optimistic_slot")
 			|> group(columns: ["slot"])|> median()
			|>drop(columns: ["_measurement", "_field", "_start", "_stop","_time","host_id", "slot"])'
			
_end_slot='from(bucket: "tds")|> range(start:'${stop_time2}' ,stop:'${stop_time}')
			|> filter(fn: (r) => r._measurement == "optimistic_slot")
			|> group(columns: ["slot"])|> median()
			|> drop(columns: ["_measurement", "_field", "_start", "_stop","_time","host_id", "slot"])'

# TPS
_mean_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
    				|> filter(fn: (r) => r._measurement == "replay-slot-stats" and r._field == "total_transactions")
    				|> aggregateWindow(every:'${window_interval}', fn: mean)
    				|> median()|> group() |> mean()'

_max_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
    				|> filter(fn: (r) => r._measurement == "replay-slot-stats" and r._field == "total_transactions")
    				|> aggregateWindow(every:'${window_interval}', fn: max)
    				|> median()|> group() |> max()'
_min_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
    				|> filter(fn: (r) => r._measurement == "replay-slot-stats" and r._field == "total_transactions")
    				|> aggregateWindow(every:'${window_interval}', fn: min)
    				|> median()|> group() |> min()'
_90_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "replay-slot-stats" and r._field == "total_transactions")
    				|> aggregateWindow(every: '${window_interval_long}',  fn: (column, tables=<-) => tables |> quantile(q: 0.9))
    				|> group()|> quantile(column: "_value", q:0.9)|>toInt()'

_99_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "replay-slot-stats" and r._field == "total_transactions")
    				|> aggregateWindow(every: '${window_interval_long}',  fn: (column, tables=<-) => tables |> quantile(q: 0.99))
    				|> group()|> quantile(column: "_value", q:0.99)|>toInt()'

# tower_vote_distance
_mean_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "tower-vote")
					|> aggregateWindow(every: '${window_interval}',fn: last)
					|> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					|> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					|> group()|> mean()|>toInt()'
_max_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "tower-vote")
					|> aggregateWindow(every: '${window_interval}',fn: last)
					|> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					|> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					|> group()|> max()|>toInt()
					|>drop(columns: ["_measurement", "_start", "_stop","count","host_id","latest","root"])'
_min_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "tower-vote")
					|> aggregateWindow(every: '${window_interval}',fn: last)
					|> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					|> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					|> group()|> min()|>toInt()
					|>drop(columns: ["_measurement", "_start", "_stop","count","host_id","latest","root"])'
_90_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "tower-vote")
					|> aggregateWindow(every: '${window_interval}',fn: last)
					|> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					|> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					|> group()|> quantile(column: "_value", q:0.9)|>toInt()'
_99_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "tower-vote")
					|> aggregateWindow(every: '${window_interval}',fn: last)
					|> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					|> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					|> group()|> quantile(column: "_value", q:0.99)|>toInt()'
# optimistic_slot_elapsed
_mean_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					|> aggregateWindow(every: '${window_interval}', fn: mean)
					|> group()|> mean()|>toInt()
					|> drop(columns: ["_start", "_stop"])'

_max_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					|> group()|> max()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'

_min_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					|> aggregateWindow(every: '${window_interval}', fn: min)
					|> group()|>min()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","latest","_time"])'
_90_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					|> aggregateWindow(every: '${window_interval_long}',  fn: mean)
					|> group()|>quantile(column: "_value", q:0.9)|>toInt()
					|> drop(columns: ["_start", "_stop"])'
_99_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					|> aggregateWindow(every: '${window_interval_long}',  fn: mean)
					|> group()|>quantile(column: "_value", q:0.99)|>toInt()
					|> drop(columns: ["_start", "_stop"])'
# ct_stats_block_cost
_mean_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "block_cost")
					|> aggregateWindow(every: '${window_interval}', fn: mean)
					|> group()|> mean()|>toInt()
					|> drop(columns:["_start", "_stop"])'
_max_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "block_cost")
					|> aggregateWindow(every: '${window_interval}', fn: max)
					|> group()|> max()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_min_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "block_cost")
					|> aggregateWindow(every: '${window_interval}', fn: min)
					|> group()|> min()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_90_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "block_cost")
					|> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |> quantile(q: 0.9))
					|> group()|>quantile(column: "_value", q:0.90)
					|> group()|> min()|>toInt()
					|> drop(columns: ["_start", "_stop"])'
_99_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "block_cost")
					|> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |> quantile(q: 0.99))
					|> group()|>quantile(column: "_value", q:0.99)
					|> group()|> min()|>toInt()
					|> drop(columns: ["_start", "_stop"])'
# ct_stats_transaction_count
_mean_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats" and r["_field"] == "transaction_count")
					|> aggregateWindow(every: '${window_interval}', fn: mean)
					|> group()|> mean()|>toInt()
					|> drop(columns: ["_start", "_stop"])'
_max_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats" and r["_field"] == "transaction_count")
					|> aggregateWindow(every: '${window_interval}', fn: max)
					|> group()|> max()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","latest","_time"])'
_min_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats" and r["_field"] == "transaction_count")
					|> aggregateWindow(every: '${window_interval}', fn: min)
					|> group()|> min()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","latest","_time"])'
_90_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats" and r["_field"] == "transaction_count")
					|> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |> quantile(q: 0.9))
					|> group()|>quantile(column: "_value", q:0.90)|>toInt()
					|> drop(columns: ["_start", "_stop"])'
_99_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats" and r["_field"] == "transaction_count")
					|> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |> quantile(q: 0.99))
					|> filter(fn: (r) => r["_field"] == "transaction_count")
					|> group()|>quantile(column: "_value", q:0.99)|>toInt()
					|> drop(columns: ["_start", "_stop"])'
# ct_stats_number_of_accounts
_mean_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "number_of_accounts")
				 	|> aggregateWindow(every: '${window_interval}', fn: mean)
					|> group()|> mean()|>toInt()
					|> drop(columns: ["_start", "_stop"])'
_max_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "number_of_accounts")
				 	 |> aggregateWindow(every: '${window_interval}', fn: max)
					 |> group()|> max()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_min_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "number_of_accounts")
				 	 |> aggregateWindow(every: '${window_interval}', fn: min)
					 |> group()|> min()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_90_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "number_of_accounts")
					 |> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |> quantile(q: 0.90))
					 |> group()|>quantile(column: "_value", q:0.90)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
_99_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "number_of_accounts")
					 |> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |> quantile(q: 0.90))
					 |> group()|>quantile(column: "_value", q:0.99)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
#blocks fill
_total_blocks='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
				|> filter(fn: (r) => r._measurement == "cost_tracker_stats" and r["_field"] == "bank_slot")
    			|> group()
    			|> aggregateWindow(every: '${window_interval}',  fn: count)
				|> sum()
				|> drop(columns: ["_start", "_stop"])'
					
_blocks_fill_50='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
  				|> filter(fn: (r) => r._measurement == "cost_tracker_stats")
  				|> filter(fn: (r) => r._field == "bank_slot" or r._field == "block_cost")
  				|> pivot(rowKey:["_time", "host_id"], columnKey: ["_field"], valueColumn: "_value")
  				|> group()
  				|> filter(fn: (r) => r.block_cost > (48000000.0*0.5))
				|> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |>  count(column: "bank_slot"))
  				|> sum(column: "bank_slot")
				|> drop(columns: ["_start", "_stop"])'
_blocks_fill_90='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
  				|> filter(fn: (r) => r._measurement == "cost_tracker_stats")
  				|> filter(fn: (r) => r._field == "bank_slot" or r._field == "block_cost")
  				|> pivot(rowKey:["_time", "host_id"], columnKey: ["_field"], valueColumn: "_value")
  				|> group()
  				|> filter(fn: (r) => r.block_cost > (48000000.0*0.9))
  				|> aggregateWindow(every: '${window_interval}',  fn: (column, tables=<-) => tables |>  count(column: "bank_slot"))
    			|> sum(column: "bank_slot")
				|> drop(columns: ["_start", "_stop"])'
#skip_rate
# $1:start_time
# $2: stop_time
# $3: oversize_window
# $4: type of statistic (mean/max/percentile90)
function skip_rate_query() {
	skip_rate_q_prefix='data_max=from(bucket: "tds")|> range(start:'$1' ,stop:'$2')
				|> filter(fn: (r) => r["_measurement"] == "bank-new_from_parent-heights")
				|> filter(fn: (r) => r["_field"] == "slot" or r["_field"] == "block_height")
				|> aggregateWindow(every:'$3', fn:max)
				|> max()
				|> group(columns: ["host_id"], mode:"by")
				data_min=from(bucket: "tds")
				|> range(start:'$1' ,stop:'$2')
				|> filter(fn: (r) => r["_measurement"] == "bank-new_from_parent-heights")
				|> filter(fn: (r) => r["_field"] == "slot" or r["_field"] == "block_height")
				|> aggregateWindow(every: '$3', fn:min)
				|> max()
				|> group(columns: ["host_id"], mode:"by")
				block_max=data_max|> filter(fn: (r) => r["_field"] == "block_height")|> set(key: "_field", value: "block_max")
				block_min=data_min|> filter(fn: (r) => r["_field"] == "block_height")|> set(key: "_field", value: "block_min")
				slot_max=data_max|> filter(fn: (r) => r["_field"] == "slot")|> set(key: "_field", value: "slot_max")
				slot_min=data_min|> filter(fn: (r) => r["_field"] == "slot")|> set(key: "_field", value: "slot_min")
				union(tables: [block_max, block_min, slot_max, slot_min])
				|> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
				|> map(fn: (r) => ({ r with block_diff: r.block_max - r.block_min }))
				|> map(fn: (r) => ({ r with slot_diff: r.slot_max - r.slot_min }))
				|> map(fn: (r) => ({ r with skip_slot: r.slot_diff - r.block_diff }))
				|> filter(fn: (r) => r.slot_diff > 0)
				|> map(fn: (r) => ({ r with skip_rate_percent: r.skip_slot*100/r.slot_diff }))
				|> keep(columns: ["skip_rate_percent"])|> group()'
	case "$4" in 
		'mean')
			skip_rate_query=$skip_rate_q_prefix'|> mean(column: "skip_rate_percent")'
		;;
		'max')
			skip_rate_query=$skip_rate_q_prefix'|> max(column: "skip_rate_percent")'
		;;
		'percentile90')
			skip_rate_query=$skip_rate_q_prefix'|> quantile(q: 0.9, column: "skip_rate_percent")'
		;;
	esac
}
skip_rate_query "$start_time" "$stop_time" "$oversize_window" "mean"
_mean_skip_rate=$skip_rate_query
skip_rate_query "$start_time" "$stop_time" "$oversize_window" "max"
_max_skip_rate=$skip_rate_query
skip_rate_query "$start_time" "$stop_time" "$oversize_window" "percentile90"
_skip_rate_90=$skip_rate_query
start_time_b4_test=$(get_time_before "$start_time" 3600)
b4_stop_time_b4_test="$start_time"
skip_rate_query "$start_time_b4_test" "$b4_stop_time_b4_test" "$oversize_window" "mean"
_mean_skip_rate_b4_test=$skip_rate_query

declare -A FLUX  # FLUX command
FLUX[start_slot]=$_start_slot
FLUX[end_slot]=$_end_slot
# TPS
FLUX[mean_tx_count]=$_mean_tx_count
FLUX[max_tx_count]=$_max_tx_count
#FLUX[min_tx_count]=$_min_tx_count
FLUX[p90_tx_count]=$_90_tx_count
FLUX[p99_tx_count]=$_99_tx_count
# # tower distance
FLUX[mean_tower_vote_distance]=$_mean_tower_vote_distance
FLUX[max_tower_vote_distance]=$_max_tower_vote_distance
#FLUX[min_tower_vote_distance]=$_min_tower_vote_distance
FLUX[p90_tower_vote_distance]=$_90_tower_vote_distance
FLUX[p99_tower_vote_distance]=$_99_tower_vote_distance
# # optimistic_slot_elapsed
FLUX[mean_optimistic_slot_elapsed]=$_mean_optimistic_slot_elapsed
FLUX[max_optimistic_slot_elapsed]=$_max_optimistic_slot_elapsed
# FLUX[min_optimistic_slot_elapsed]=$_min_optimistic_slot_elapsed
FLUX[p90_optimistic_slot_elapsed]=$_90_optimistic_slot_elapsed
FLUX[p99_optimistic_slot_elapsed]=$_99_optimistic_slot_elapsed
# # ct_stats_block_cost
FLUX[mean_ct_stats_block_cost]=$_mean_ct_stats_block_cost
FLUX[max_ct_stats_block_cost]=$_max_ct_stats_block_cost
# FLUX[min_ct_stats_block_cost]=$_min_ct_stats_block_cost
FLUX[p90_ct_stats_block_cost]=$_90_ct_stats_block_cost
FLUX[p99_ct_stats_block_cost]=$_99_ct_stats_block_cost
# ct_stats_transaction_count
FLUX[mean_ct_stats_transaction_count]=$_mean_ct_stats_transaction_count
FLUX[max_ct_stats_transaction_count]=$_max_ct_stats_transaction_count
# FLUX[min_ct_stats_transaction_count]=$_min_ct_stats_transaction_count
FLUX[p90_ct_stats_transaction_count]=$_90_ct_stats_transaction_count
FLUX[p99_ct_stats_transaction_count]=$_99_ct_stats_transaction_count

# ct_stats_number_of_accounts
FLUX[mean_ct_stats_number_of_accounts]=$_mean_ct_stats_number_of_accounts
FLUX[max_ct_stats_number_of_accounts]=$_max_ct_stats_number_of_accounts
# FLUX[min_ct_stats_number_of_accounts]=$_min_ct_stats_number_of_accounts
FLUX[p90_ct_stats_number_of_accounts]=$_90_ct_stats_number_of_accounts
FLUX[p99_ct_stats_number_of_accounts]=$_99_ct_stats_number_of_accounts

# blocks fill
FLUX[total_blocks]=$_total_blocks
FLUX[blocks_fill_50]=$_blocks_fill_50
FLUX[blocks_fill_90]=$_blocks_fill_90

# skip rate
FLUX[mean_skip_rate]=$_mean_skip_rate
FLUX[max_skip_rate]=$_max_skip_rate
FLUX[skip_rate_90]=$_skip_rate_90
FLUX[mean_skip_rate_b4_test]=$_mean_skip_rate_b4_test

# Dos Report write to Influxdb

declare -A FIELD_MEASUREMENT
# measurement range
FIELD_MEASUREMENT[start_time]=range
FIELD_MEASUREMENT[stop_time]=range
FIELD_MEASUREMENT[time_range]=range
FIELD_MEASUREMENT[start_slot]=range
FIELD_MEASUREMENT[end_slot]=range
# tps
FIELD_MEASUREMENT[mean_tps]=tps
FIELD_MEASUREMENT[max_tps]=tps
FIELD_MEASUREMENT[90th_tx_count]=tps
FIELD_MEASUREMENT[99th_tx_count]=tps
# tower_vote
FIELD_MEASUREMENT[mean_tower_vote_distance]=tower_vote
FIELD_MEASUREMENT[max_tower_vote_distance]=tower_vote
FIELD_MEASUREMENT[90th_tower_vote_distance]=tower_vote
FIELD_MEASUREMENT[99th_tower_vote_distance]=tower_vote
# optimistic_slot_elapsed
FIELD_MEASUREMENT[mean_optimistic_slot_elapsed]=optimistic_slot_elapsed
FIELD_MEASUREMENT[max_optimistic_slot_elapsed]=optimistic_slot_elapsed
FIELD_MEASUREMENT[90th_optimistic_slot_elapsed]=optimistic_slot_elapsed
FIELD_MEASUREMENT[99th_optimistic_slot_elapsed]=optimistic_slot_elapsed
# cost_tracker_stats
FIELD_MEASUREMENT[mean_cost_tracker_stats_block_cost]=block_cost
FIELD_MEASUREMENT[max_cost_tracker_stats_block_cost]=block_cost
FIELD_MEASUREMENT[90th_cost_tracker_stats_block_cost]=block_cost
FIELD_MEASUREMENT[99th_cost_tracker_stats_block_cost]=block_cost
# transaction_count
FIELD_MEASUREMENT[mean_cost_tracker_stats_transaction_count]=transaction_count
FIELD_MEASUREMENT[max_cost_tracker_stats_transaction_count]=transaction_count
FIELD_MEASUREMENT[90th_cost_tracker_stats_transaction_count]=transaction_count
FIELD_MEASUREMENT[99th_cost_tracker_stats_transaction_count]=transaction_count
# ct_stats_number_of_accounts
FIELD_MEASUREMENT[mean_cost_tracker_stats_number_of_accounts]=number_of_accounts
FIELD_MEASUREMENT[max_cost_tracker_stats_number_of_accounts]=number_of_accounts
FIELD_MEASUREMENT[90th_cost_tracker_stats_number_of_accounts]=number_of_accounts
FIELD_MEASUREMENT[99th_cost_tracker_stats_number_of_accounts]=number_of_accounts
# blocks fill
FIELD_MEASUREMENT[numb_total_blocks]=block_fill
FIELD_MEASUREMENT[numb_blocks_50_full]=block_fill
FIELD_MEASUREMENT[numb_blocks_90_full]=block_fill
FIELD_MEASUREMENT[blocks_50_full]=block_fill
FIELD_MEASUREMENT[blocks_90_full]=block_fill

# skip rate
FIELD_MEASUREMENT[mean_skip_rate]=skip_rate
FIELD_MEASUREMENT[max_skip_rate]=skip_rate
FIELD_MEASUREMENT[skip_rate_90]=skip_rate
FIELD_MEASUREMENT[mean_skip_rate_b4_test]=skip_rate
