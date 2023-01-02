#!/usr/bin/env bash
# slot
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
					|> filter(fn: (r) => r._measurement == "bank-process_transactions")
  					|> group(columns: ["count"])
  					|> mean()|>toInt()
					|>drop(columns: ["_start", "_stop","count"])'
_max_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "bank-process_transactions")
  					|> group(columns: ["count"])
  					|> max()|>toInt()
					|>drop(columns: ["_measurement", "_field", "_start", "_stop","_time","host_id","count"])'
_min_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "bank-process_transactions")
  					|> group(columns: ["count"])
  					|> min()|>toInt()
					|>drop(columns: ["_measurement", "_field", "_start", "_stop","_time","host_id","count"])'

_90_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "bank-process_transactions")
  					|> group(columns: ["count"])
  					|> quantile(column: "_value", q:0.9)|>toInt()
					|>drop(columns: ["_measurement", "_field", "_start", "_stop","count"])'

_99_tx_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "bank-process_transactions")
  					|> group(columns: ["count"])
  					|> quantile(column: "_value", q:0.99)|>toInt()
					|>drop(columns: ["_measurement", "_field", "_start", "_stop","count"])'

# tower distance
_mean_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "tower-vote")
					 |> aggregateWindow(every: 1s,fn: mean)
					 |> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					 |> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					 |> group()|> mean()|>toInt()'
_max_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "tower-vote")
					 |> aggregateWindow(every: 1s,fn: max)
					 |> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					 |> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					 |> group()|> max()|>toInt()
					 |>drop(columns: ["_measurement", "_start", "_stop","count","host_id","latest","root"])'
_min_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "tower-vote")
					 |> aggregateWindow(every: 1s,fn: min)
					 |> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					 |> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					 |> group()|> min()|>toInt()
					 |>drop(columns: ["_measurement", "_start", "_stop","count","host_id","latest","root"])'
_90_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "tower-vote")
					 |> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					 |> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					 |> group()|> quantile(column: "_value", q:0.9)|>toInt()'
_99_tower_vote_distance='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "tower-vote")
					 |> pivot(rowKey:["host_id"], columnKey: ["_field"], valueColumn: "_value")
					 |> map(fn: (r) => ({ r with _value: r.latest - r.root}))
					 |> group()|> quantile(column: "_value", q:0.99)|>toInt()'
# optimistic_slot_elapsed
_mean_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					 |> group()|> mean()|>toInt()
					 |> drop(columns: ["_start", "_stop"])'

_max_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					|> group()|> max()|>toInt()
					|> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'

_min_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					 |> group()|>min()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","latest","_time"])'
_90_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					 |> group()|>quantile(column: "_value", q:0.9)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
_99_optimistic_slot_elapsed='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "optimistic_slot_elapsed")
					 |> group()|>quantile(column: "_value", q:0.99)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
# ct_stats_block_cost
_mean_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "block_cost")
					 |> group()|> mean()|>toInt()
					 |> drop(columns:["_start", "_stop"])'
_max_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "block_cost")
					 |> group()|> max()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_min_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "block_cost")
					 |> group()|> min()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_90_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "block_cost")
					 |> group()|>quantile(column: "_value", q:0.90)
					 |> group()|> min()|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
_99_ct_stats_block_cost='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "block_cost")
					 |> group()|>quantile(column: "_value", q:0.99)
					 |> group()|> min()|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
# ct_stats_transaction_count
_mean_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "transaction_count")
					 |> group()|> mean()|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
_max_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "transaction_count")
					 |> group()|> max()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","latest","_time"])'
_min_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "transaction_count")
					 |> group()|> min()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","latest","_time"])'
_90_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "transaction_count")
					 |> group()|>quantile(column: "_value", q:0.90)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
_99_ct_stats_transaction_count='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "transaction_count")
					 |> group()|>quantile(column: "_value", q:0.99)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
# ct_stats_number_of_accounts
_mean_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					|> filter(fn: (r) => r["_field"] == "number_of_accounts")
					|> group()|> mean()|>toInt()
					|> drop(columns: ["_start", "_stop"])'
_max_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "number_of_accounts")
					 |> group()|> max()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_min_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r["_measurement"] == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "number_of_accounts")
					 |> group()|> min()|>toInt()
					 |> drop(columns: ["_measurement","_field", "_start", "_stop","host_id","_time"])'
_90_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "number_of_accounts")
					 |> group()|>quantile(column: "_value", q:0.90)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
_99_ct_stats_number_of_accounts='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					 |> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					 |> filter(fn: (r) => r["_field"] == "number_of_accounts")
					 |> group()|>quantile(column: "_value", q:0.99)|>toInt()
					 |> drop(columns: ["_start", "_stop"])'
#blocks fill
_total_blocks='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
					|> filter(fn: (r) => r._measurement == "cost_tracker_stats")
					|> filter(fn: (r) => r["_field"] == "bank_slot")
					|> group()|> count()
					|> drop(columns: ["_start", "_stop"])'
					
_blocks_fill_50='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
  				|> filter(fn: (r) => r._measurement == "cost_tracker_stats")
  				|> filter(fn: (r) => r._field == "bank_slot" or r._field == "block_cost")
  				|> pivot(rowKey:["_time", "host_id"], columnKey: ["_field"], valueColumn: "_value")
  				|> group()
  				|> filter(fn: (r) => r.block_cost > (48000000.0*0.5))
  				|> count(column: "bank_slot")'
_blocks_fill_90='from(bucket: "tds")|> range(start:'${start_time}' ,stop:'${stop_time}')
  				|> filter(fn: (r) => r._measurement == "cost_tracker_stats")
  				|> filter(fn: (r) => r._field == "bank_slot" or r._field == "block_cost")
  				|> pivot(rowKey:["_time", "host_id"], columnKey: ["_field"], valueColumn: "_value")
  				|> group()
  				|> filter(fn: (r) => r.block_cost > (48000000.0*0.9))
  				|> count(column: "bank_slot")'

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
