#!/usr/bin/env bash
set -ex
echo ----- stage: checkout buildkite Steps Env ------ 
# Check ENVs
[[ ! "$TEST_TYPE" ]]&& echo TEST_TYPE env not found && exit 1
[[ ! "$ENDPOINT" ]]&& echo ENDPOINT env not found && exit 1
[[ ! "$NUM_CLIENT" ]]&& echo NUM_CLIENT env not found && exit 1
[[ ! "$TPU_USE_QUIC" ]]&& TPU_USE_QUIC="false" && echo TPU_USE_QUIC env not found, use $TPU_USE_QUIC
[[ ! "$TPU_DISABLE_QUIC" ]]&& TPU_DISABLE_QUIC=0 && echo TPU_DISABLE_QUIC env not found, use $TPU_DISABLE_QUIC
# CI ENVs
[[ ! "$GIT_TOKEN" ]]&& echo GIT_TOKEN env not found && exit 1
[[ ! "$SOLANA_REPO" ]]&& SOLANA_REPO=https://github.com/solana-labs/solana.git
[[ ! "$SOLANA_BUILD_BRANCH" ]]&& SOLANA_BUILD_BRANCH=same-as-cluster&& echo SOLANA_BUILD_BRANCH env not found, use $SOLANA_BUILD_BRANCH
[[ ! "$KEEP_INSTANCES" ]]&& KEEP_INSTANCES="false" && echo KEEP_INSTANCES env not found, use $KEEP_INSTANCES
[[ ! "$RUN_BENCH_AT_TS_UTC" ]]&& RUN_BENCH_AT_TS_UTC=0 && echo RUN_BENCH_AT_TS_UTC env not found, use $RUN_BENCH_AT_TS_UTC
[[ ! "$DOS_BENCH_TPS_BUCKET" ]]&& DOS_BENCH_TPS_BUCKET="bench-tps-dos"
[[ ! "$SLACK_WEBHOOK" ]]&&[[ ! "$DISCORD_WEBHOOK" ]]&& echo no WEBHOOK found&&exit 1

source utils.sh
echo ----- stage: prepare metrics env ------ 
[[ -f "dos-metrics-env.sh" ]]&& rm dos-metrics-env.sh
download_file "gs://$DOS_BENCH_TPS_BUCKET" dos-metrics-env.sh ./
[[ ! -f "dos-metrics-env.sh" ]]&& echo "NO dos-metrics-env.sh found" && exit 1

echo ----- stage: prepare ssh key to dynamic clients ------
download_file "gs://$DOS_BENCH_TPS_BUCKET" id_ed25519_dos_test ./
[[ ! -f "id_ed25519_dos_test" ]]&& echo "no id_ed25519_dos_test found" && exit 1
chmod 600 id_ed25519_dos_test

echo ----- stage: prepare env-artifact for clients ------
## Mango-simulation Envs
echo "ENDPOINT=$ENDPOINT" > env-artifact.sh
echo "NUM_CLIENT=$NUM_CLIENT" > env-artifact.sh
echo "TEST_TYPE=$TEST_TYPE" > env-artifact.sh
echo "TPU_USE_QUIC=$TPU_USE_QUIC" > env-artifact.sh
echo "TPU_DISABLE_QUIC=$TPU_DISABLE_QUIC" > env-artifact.sh

echo "GIT_TOKEN=$GIT_TOKEN" > env-artifact.sh
echo "SOLANA_REPO=$SOLANA_REPO" > env-artifact.sh
echo "SOLANA_BUILD_BRANCH=$SOLANA_BUILD_BRANCH" > env-artifact.sh
echo "KEEP_INSTANCES=$KEEP_INSTANCES" > env-artifact.sh
echo "DOS_BENCH_TPS_BUCKET=$DOS_BENCH_TPS_BUCKET" > env-artifact.sh
echo "RUN_BENCH_AT_TS_UTC=$RUN_BENCH_AT_TS_UTC" > env-artifact.sh
echo "SLACK_WEBHOOK=$SLACK_WEBHOOK" > env-artifact.sh

# buildkite build envs
echo "BUILDKITE_BRANCH=$BUILDKITE_BRANCH" >> env-artifact.sh
echo "BUILDKITE_PIPELINE_ID=$BUILDKITE_PIPELINE_ID" >> env-artifact.sh
echo "BUILDKITE_BUILD_ID=$BUILDKITE_BUILD_ID" >> env-artifact.sh
echo "BUILDKITE_JOB_ID=$BUILDKITE_JOB_ID" >> env-artifact.sh
echo "BUILDKITE_BUILD_NUMBER=$BUILDKITE_BUILD_NUMBER" >> env-artifact.sh
## artifact address
echo "ARTIFACT_BUCKET=$ARTIFACT_BUCKET" >> env-artifact.sh
echo "ENV_ARTIFACT_FILE=env-artifact.sh" >> env-artifact.sh
echo "MANGO_SIMULATION_ARTIFACT_FILE=mango-simulation" >> env-artifact.sh
cat dos-metrics-env.sh >> env-artifact.sh
exit 0
