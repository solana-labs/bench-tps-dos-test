#!/usr/bin/env bash
set -ex
echo ----- stage: checkout buildkite Steps Env ------ 
## Buckets Memo
## There are 3 buckets in total
## 1.ARTIFACT_BUCKET : dos-agent bucket, share with other program use dos-agent as buildkite agent
## 2.DOS_BENCH_TPS_PRIVATE_BUCKET : private bucket, store private data
## 3.DOS_BENCH_TPS_LOG_BUCKET : log bucket

# Check ENVs
[[ ! "$TEST_TYPE" ]]&& echo TEST_TYPE env not found && exit 1
[[ ! "$ENDPOINT" ]]&& echo ENDPOINT env not found && exit 1
[[ ! "$TPU_USE_QUIC" ]]&& TPU_USE_QUIC="false" && echo TPU_USE_QUIC env not found, use $TPU_USE_QUIC
[[ ! "$TPU_DISABLE_QUIC" ]]&& TPU_DISABLE_QUIC=0 && echo TPU_DISABLE_QUIC env not found, use $TPU_DISABLE_QUIC
[[ ! "$USE_TPU_CLIENT" ]] && USE_TPU_CLIENT="true"

# CI ENVs
[[ ! "$GIT_TOKEN" ]]&& echo GIT_TOKEN env not found && exit 1
[[ ! "$GIT_REPO" ]]&& GIT_REPO="https://github.com/solana-labs/bench-tps-dos-test.git"
[[ ! "$GIT_REPO_DIR" ]]&& GIT_REPO_DIR="bench-tps-dos-test"
[[ ! "$DOS_FOUNDER_FILE" ]]&&DOS_FOUNDER_FILE="testnet-dos-funder.json"
[[ ! "$KEYPAIR_FILE" ]]&&KEYPAIR_FILE="large-keypairs.yaml"
[[ ! "$ID_FILE" ]]&&ID_FILE="id_ed25519_dos_test"
[[ ! "$BENCH_TPS_ARTIFACT_FILE" ]]&& BENCH_TPS_ARTIFACT_FILE=solan-bench-tps
[[ ! "$ARTIFACT_BUCKET" ]]&& ARTIFACT_BUCKET=buildkite-dos-agent && export ARTIFACT_BUCKET="$ARTIFACT_BUCKET"
[[ ! "$ENV_ARTIFACT_FILE" ]]&& ENV_ARTIFACT_FILE=buildkite-dos-agent && export ENV_ARTIFACT_FILE="$ENV_ARTIFACT_FILE"
[[ ! "$DOS_BENCH_TPS_PRIVATE_BUCKET" ]]&& DOS_BENCH_TPS_PRIVATE_BUCKET=bench-tps-dos-private
[[ ! "$DOS_BENCH_TPS_LOG_BUCKET" ]]&& DOS_BENCH_TPS_LOG_BUCKET="bench-tps-dos-log"
[[ ! "$SOLANA_REPO" ]]&& SOLANA_REPO=https://github.com/solana-labs/solana.git
[[ ! "$SOLANA_BUILD_BRANCH" ]]&& SOLANA_BUILD_BRANCH=master
[[ ! "$NUM_CLIENT" ]]&& echo NUM_CLIENT env not found && exit 1
[[ ! "$KEEP_INSTANCES" ]]&& KEEP_INSTANCES="false" && echo KEEP_INSTANCES env not found, use $KEEP_INSTANCES
[[ ! "$RUN_BENCH_AT_TS_UTC" ]]&& RUN_BENCH_AT_TS_UTC=0 && echo RUN_BENCH_AT_TS_UTC env not found, use $RUN_BENCH_AT_TS_UTC

[[ ! "$SLACK_WEBHOOK" ]]&&[[ ! "$DISCORD_WEBHOOK" ]]&& echo no WEBHOOK found&&exit 1

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
## Mango-simulation Envs
echo "ENDPOINT=$ENDPOINT" >> "$ENV_ARTIFACT_FILE"
echo "NUM_CLIENT=$NUM_CLIENT" >> "$ENV_ARTIFACT_FILE"
echo "TEST_TYPE=$TEST_TYPE" >> "$ENV_ARTIFACT_FILE"
echo "TPU_USE_QUIC=$TPU_USE_QUIC" >> "$ENV_ARTIFACT_FILE"
echo "TPU_DISABLE_QUIC=$TPU_DISABLE_QUIC" >> "$ENV_ARTIFACT_FILE"

echo "GIT_TOKEN=$GIT_TOKEN" >> "$ENV_ARTIFACT_FILE"
echo "SOLANA_REPO=$SOLANA_REPO" >> "$ENV_ARTIFACT_FILE"
echo "SOLANA_BUILD_BRANCH=$SOLANA_BUILD_BRANCH" >> "$ENV_ARTIFACT_FILE"
echo "KEEP_INSTANCES=$KEEP_INSTANCES" >> "$ENV_ARTIFACT_FILE"
echo "RUN_BENCH_AT_TS_UTC=$RUN_BENCH_AT_TS_UTC" >> "$ENV_ARTIFACT_FILE"
echo "SLACK_WEBHOOK=$SLACK_WEBHOOK" >> "$ENV_ARTIFACT_FILE"

# buildkite build envs
echo "BUILDKITE_BRANCH=$BUILDKITE_BRANCH" >> "$ENV_ARTIFACT_FILE"
echo "BUILDKITE_PIPELINE_ID=$BUILDKITE_PIPELINE_ID" >> "$ENV_ARTIFACT_FILE"
echo "BUILDKITE_BUILD_ID=$BUILDKITE_BUILD_ID" >> "$ENV_ARTIFACT_FILE"
echo "BUILDKITE_JOB_ID=$BUILDKITE_JOB_ID" >> "$ENV_ARTIFACT_FILE"
echo "BUILDKITE_BUILD_NUMBER=$BUILDKITE_BUILD_NUMBER" >> "$ENV_ARTIFACT_FILE"
## artifact address
echo "DOS_BENCH_TPS_PRIVATE_BUCKET=$DOS_BENCH_TPS_PRIVATE_BUCKET" >> "$ENV_ARTIFACT_FILE"
echo "DOS_BENCH_TPS_LOG_BUCKET=$DOS_BENCH_TPS_LOG_BUCKET" >> "$ENV_ARTIFACT_FILE"
echo "ARTIFACT_BUCKET=$ARTIFACT_BUCKET" >> "$ENV_ARTIFACT_FILE"
echo "ENV_ARTIFACT_FILE=$ENV_ARTIFACT_FILE" >> "$ENV_ARTIFACT_FILE"
echo "BENCH_TPS_ARTIFACT_FILE=solana-bench-tps" >> "$ENV_ARTIFACT_FILE"
cat dos-metrics-env.sh >> "$ENV_ARTIFACT_FILE"
exit 0
