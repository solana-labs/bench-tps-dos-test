#!/usr/bin/env bash
set -ex
## Directory settings
dos_program_dir=$(pwd)
source utils.sh
# shellcheck source=/dev/null
source "env-artifact.sh" 

echo ----- stage: machines and build and upload mango-simulation ---
cd "$dos_program_dir"
# shellcheck source=/dev/null
source create-instance.sh
create_machines "$NUM_CLIENT"
echo ----- stage: build dependency mango_bencher configure_mango for machine------
client_num=1
# ARTIFACT_BUCKET must in the step
artifact_bucket="$ARTIFACT_BUCKET/$BUILDKITE_PIPELINE_ID/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID"
artifact_file="$ENV_ARTIFACT_FILE"
for sship in "${instance_ip[@]}"
do
    [[ $client_num -eq 1 ]] && arg1="true" || arg1="false"
    # run start-build-dependency.sh which in agent machine
    ret_build_dependency=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@"$sship" 'bash -s' < start-build-dependency.sh "$arg1" "$artifact_bucket" "$artifact_file")
    (( client_num++ )) || true
done

exit 0



