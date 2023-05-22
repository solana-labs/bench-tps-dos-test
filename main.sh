#!/usr/bin/env bash
set -ex
## Directory settings
dos_program_dir=$(pwd)
source utils.sh

artifact_bucket="$ARTIFACT_BUCKET/$BUILDKITE_PIPELINE_ID/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID"
artifact_file="$ENV_ARTIFACT_FILE"
download "$artifact_bucket" "$artifact_file" "$dos_program_dir"
if [[ -f "$artifact_file" ]];then
    # shellcheck source=/dev/null
    source "$artifact_file" 
else
    echo "No $artifact_file found"
    exit 1
fi

echo ----- stage: machines and build and upload mango-simulation ---
cd "$dos_program_dir"
# shellcheck source=/dev/null
source create-instance.sh
create_machines "$NUM_CLIENT"
echo ----- stage: build dependency mango_bencher configure_mango for machine------
client_num=1
# ARTIFACT_BUCKET must in the step
for sship in "${instance_ip[@]}"
do
    [[ $client_num -eq 1 ]] && arg1="true" || arg1="false"
    # run start-build-dependency.sh which in agent machine
    ret_build_dependency=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@"$sship" 'bash -s' < start-build-dependency.sh "$arg1" "$artifact_bucket" "$artifact_file")
    (( client_num++ )) || true
done

echo ----- stage: run dos test ---
client_num=1
for sship in "${instance_ip[@]}"
do
    (( idx=$client_num -1 )) || true
    [[ $client_num -eq 1 ]] && arg2="true" || arg2="false"
    [[ $RUN_KEEPER != "true" ]] && arg2="false" # override the arg2 base on input from Steps
    acct=${accounts[$idx]}
    # run start-dos-test.sh which in client machine
    ret_run_dos=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship "nohup /home/sol/start-dos-test.sh $acct $arg2 1> start-dos-test.nohup 2> start-dos-test.nohup &")
    (( client_num++ )) || true
    [[ $client_num -gt ${#accounts[@]} ]] && client_num=1    
done

exit 0



