#!/usr/bin/env bash
# benchmark
set -ex
# shellcheck source=/dev/null
source $HOME/.profile
# shellcheck source=/dev/null
source $HOME/env-artifact.sh

[[ ! "$ENDPOINT" ]]&& echo "No ENDPOINT" && exit 1
[[ ! "$SOLANA_METRICS_CONFIG" ]] && echo no SOLANA_METRICS_CONFIG ENV && exit 1
[[ ! "$KEYPAIR_FILE" ]]&& KEYPAIR_FILE=large-keypairs.yaml && echo No KEYPAIR_FILE Env , use $KEYPAIR_FILE
#### bench-tps ENV ####
echo --- stage:setup bench-tps parameters ---
args=(
  -u "$ENDPOINT"
  --identity "$HOME/$ID_FILE"
  --read-client-keys "$HOME/$KEYPAIR_FILE"
  --duration "$TX_COUNT"
  --tx_count "$DURATION" 
  --thread-batch-sleep-ms "$THREAD_BATCH_SLEEP_MS"
)
# b) use_tpu_client (boolean, if true --use-tpu-client, if false --use-rpc-client)
# c) tpu_use_quic (boolean, if true --tpu-use-quic, if false nothing) --> false does UDP
# c.1) quic is default so tpu_use_quic is no longer exist for some branches (master at 8/20)
# f) tx_count (--tx_count 10000 for the UDP test and --tx_count 2000 per client for the QUIC ) 
# f1.1) tx_count no longer bound to test type. 8/20/2022
# g) thread_batch_sleep ( --thread-batch-sleep-ms 1 for UDP --thread-batch-sleep-ms 10 for QUIC)
# g.1) no longer bound to test type
[[ ! "$TX_COUNT" ]] && TX_COUNT=10000 && echo No TX_COUNT Env , use $TX_COUNT
# e) duration (default --duration 1800) 
[[ ! "$DURATION" ]] && DURATION=1800 && echo No DURATION Env , use $DURATION
[[ ! "$THREAD_BATCH_SLEEP_MS" ]]&& THREAD_BATCH_SLEEP_MS=1 && echo No THREAD_BATCH_SLEEP_MS Env , use $THREAD_BATCH_SLEEP_MS
[[ "$USE_TPU_CLIENT" == "true" ]] && args+=(--use-tpu-client) || args+=(--use-rpc-client)
[[ "$TPU_USE_QUIC" == "true" ]] && args+=(--tpu-use-quic)
[[ "$USE_DURABLE_NONCE" == "true" ]] &&	args+=(--use-durable-nonce)
# d) sustained (boolean, if true --sustained, if false nothing)
[[ "$SUSTAINED" == "true" ]]&& args+=(--sustained)
# benchmark exec
# cd $HOME/solana/solana-release/bin
cd $HOME/solana/target/release
echo --- start of benchmark $(date)
benchmark=$(./solana-bench-tps "${args[@]}" &)
sleep 2
cd $HOME
ret_ps=$(ps aux | grep solana-bench-tps)
echo $ret_ps > ps.out
echo --- end of benchmark $(date)

