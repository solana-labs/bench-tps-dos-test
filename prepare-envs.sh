#!/usr/bin/env bash
set -ex
echo ----- stage: checkout buildkite Steps Env ------ 
## Buckets Memo
## There are 3 buckets in total
## 1.ARTIFACT_BUCKET : dos-agent bucket, share with other program use dos-agent as buildkite agent
## 2.DOS_BENCH_TPS_PRIVATE_BUCKET : private bucket, store private data
## 3.DOS_BENCH_TPS_LOG_BUCKET : log bucket

# Check ENVs
[[ ! "$ENDPOINT" ]]&& echo ENDPOINT env not found && exit 1
[[ ! "$TX_COUNT" ]] && echo TX_COUNT env not found && exit 1
[[ ! "$DURATION" ]] && echo DURATION env not found && exit 1
[[ ! "$USE_TPU_CLIENT" ]] && USE_TPU_CLIENT="true"
[[ ! "$TPU_USE_QUIC" ]]&& TPU_USE_QUIC="false" && echo TPU_USE_QUIC env not found, use $TPU_USE_QUIC
[[ ! "$THREAD_BATCH_SLEEP_MS" ]]&& THREAD_BATCH_SLEEP_MS=10 && echo THREAD_BATCH_SLEEP_MS env not found, use $TPU_DISABLE_QUIC
[[ ! "$SUSTAINED" ]] && SUSTAINED="false"
[[ ! "$USE_DURABLE_NONCE" ]] && USE_DURABLE_NONCE="false"
# CI ENVs
[[ ! "$TEST_TYPE" ]] && TEST_TYPE="QUIC"
[[ ! "$GIT_TOKEN" ]]&& echo GIT_TOKEN env not found && exit 1
[[ ! "$NUM_CLIENT" ]]&& echo NUM_CLIENT env not found && exit 1
[[ ! "$TERMINATION_CHECK_INTERVAL" ]]&& TERMINATION_CHECK_INTERVAL=10 && echo TERMINATION_CHECK_INTERVAL env not found, use $TERMINATION_CHECK_INTERVAL
[[ ! "$GIT_REPO_DIR" ]]&& GIT_REPO_DIR="bench-tps-dos-test"
[[ ! "$SOLANA_BUILD_BRANCH" ]]&& SOLANA_BUILD_BRANCH=master
[[ ! "$AVAILABLE_ZONE" ]]&& AVAILABLE_ZONE="us-central1-a us-west1-b asia-east1-b europe-west4-a" && echo  no AVAILABLE_ZONE and use $AVAILABLE_ZONE
[[ ! "$KEYPAIR_DIR" ]]&&KEYPAIR_DIR="keypair-configs"
[[ ! "$KEYPAIR_FILE" ]]&&KEYPAIR_FILE="large-keypairs.yaml"
[[ ! "$KEYPAIR_TAR_FILE" ]] && KEYPAIR_TAR_FILE=keypair-configs.tgz 
[[ ! "$ID_FILE" ]]&&ID_FILE="id_ed25519_dos_test"
[[ ! "$BENCH_TPS_ARTIFACT_FILE" ]]&& BENCH_TPS_ARTIFACT_FILE="solana-bench-tps"
[[ ! "$DOS_BENCH_TPS_PRIVATE_BUCKET" ]]&& DOS_BENCH_TPS_PRIVATE_BUCKET=bench-tps-dos-private
[[ ! "$DOS_BENCH_TPS_LOG_BUCKET" ]]&& DOS_BENCH_TPS_LOG_BUCKET="bench-tps-dos-log"
[[ ! "$SOLANA_REPO" ]]&& SOLANA_REPO=https://github.com/solana-labs/solana.git
[[ ! "$KEEP_INSTANCES" ]]&& KEEP_INSTANCES="false" && echo KEEP_INSTANCES env not found, use $KEEP_INSTANCES
[[ ! "$RUN_BENCH_AT_TS_UTC" ]]&& RUN_BENCH_AT_TS_UTC=0 && echo RUN_BENCH_AT_TS_UTC env not found, use $RUN_BENCH_AT_TS_UTC
[[ ! "$SLACK_WEBHOOK" ]]&&[[ ! "$DISCORD_WEBHOOK" ]]&& echo no WEBHOOK found&&exit 1
ARTIFACT_BUCKET=buildkite-dos-agent 
export ARTIFACT_BUCKET="$ARTIFACT_BUCKET"
ENV_ARTIFACT_FILE=env-artifact.sh
export ENV_ARTIFACT_FILE="$ENV_ARTIFACT_FILE"

source utils.sh
echo ----- stage: prepare metrics env ------ 
[[ -f "dos-metrics-env.sh" ]]&& rm dos-metrics-env.sh
download_file "gs://$DOS_BENCH_TPS_PRIVATE_BUCKET" dos-metrics-env.sh ./
[[ ! -f "dos-metrics-env.sh" ]]&& echo "NO dos-metrics-env.sh found" && exit 1

echo ----- stage: prepare ssh key to dynamic clients ------
download_file "gs://$DOS_BENCH_TPS_PRIVATE_BUCKET" id_ed25519_dos_test ./
[[ ! -f "id_ed25519_dos_test" ]]&& echo "no id_ed25519_dos_test found" && exit 1
chmod 600 id_ed25519_dos_test

echo ----- stage: prepare env-artifact for clients ------
## bench-tps Envs
echo "ENDPOINT=$ENDPOINT" >> env-artifact.sh
echo "TPU_USE_QUIC=$TPU_USE_QUIC" >> env-artifact.sh
echo "TX_COUNT=$TX_COUNT" >> env-artifact.sh
echo "DURATION=$DURATION" >> env-artifact.sh
echo "USE_TPU_CLIENT=$USE_TPU_CLIENT" >> env-artifact.sh
echo "THREAD_BATCH_SLEEP_MS=$THREAD_BATCH_SLEEP_MS" >> env-artifact.sh
echo "USE_DURABLE_NONCE=$USE_DURABLE_NONCE" >> env-artifact.sh
echo "SUSTAINED=$SUSTAINED" >> env-artifact.sh
echo "TPU_DISABLE_QUIC=$TPU_DISABLE_QUIC" >> env-artifact.sh
## CI Envs
echo "NUM_CLIENT=$NUM_CLIENT" >> env-artifact.sh
echo "GIT_TOKEN=$GIT_TOKEN" >> env-artifact.sh
echo "GIT_REPO_DIR=$GIT_REPO_DIR" >> env-artifact.sh
echo "SOLANA_REPO=$SOLANA_REPO" >> env-artifact.sh
echo "SOLANA_BUILD_BRANCH=$SOLANA_BUILD_BRANCH" >> env-artifact.sh
echo "KEEP_INSTANCES=$KEEP_INSTANCES" >> env-artifact.sh
echo "RUN_BENCH_AT_TS_UTC=$RUN_BENCH_AT_TS_UTC" >> env-artifact.sh
echo "SLACK_WEBHOOK=$SLACK_WEBHOOK" >> env-artifact.sh
##  downloaded files
echo "KEYPAIR_DIR=$KEYPAIR_DIR" >> env-artifact.sh
echo "KEYPAIR_FILE=$KEYPAIR_FILE" >> env-artifact.sh
echo "KEYPAIR_TAR_FILE=$KEYPAIR_TAR_FILE" >> env-artifact.sh
echo "ID_FILE=$ID_FILE" >> env-artifact.sh
# buildkite build envs
echo "BUILDKITE_BRANCH=$BUILDKITE_BRANCH" >> env-artifact.sh
echo "BUILDKITE_REPO=$BUILDKITE_REPO" >> env-artifact.sh
echo "BUILDKITE_PIPELINE_ID=$BUILDKITE_PIPELINE_ID" >> env-artifact.sh
echo "BUILDKITE_BUILD_ID=$BUILDKITE_BUILD_ID" >> env-artifact.sh
echo "BUILDKITE_JOB_ID=$BUILDKITE_JOB_ID" >> env-artifact.sh
echo "BUILDKITE_BUILD_NUMBER=$BUILDKITE_BUILD_NUMBER" >> env-artifact.sh
## artifact address
echo "DOS_BENCH_TPS_PRIVATE_BUCKET=$DOS_BENCH_TPS_PRIVATE_BUCKET" >> env-artifact.sh
echo "DOS_BENCH_TPS_LOG_BUCKET=$DOS_BENCH_TPS_LOG_BUCKET" >> env-artifact.sh
echo "ARTIFACT_BUCKET=$ARTIFACT_BUCKET" >> env-artifact.sh
echo "ENV_ARTIFACT_FILE=$ENV_ARTIFACT_FILE" >> env-artifact.sh
echo "BENCH_TPS_ARTIFACT_FILE=solana-bench-tps" >> env-artifact.sh
cat dos-metrics-env.sh >> env-artifact.sh
exit 0
