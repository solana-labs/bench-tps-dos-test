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

echo ----- stage: run bench-tps test ---
client_num=1
for sship in "${instance_ip[@]}"
do
    # run start-dos-test.sh which in client machine
    ret_run_dos=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship "nohup /home/sol/start-dos-test.sh  1> start-dos-test.nohup 2> start-dos-test.nohup &")
    (( client_num++ )) || true 
done

# # Get Time Start
start_time=$(date -u +%s)
start_time_adjust=$(get_time_after $start_time 5)

echo ----- stage: wait for bencher concurrently ------
sleep $DURATION
echo ----- stage: check finish of process ---
sleep 5
for sship in "${instance_ip[@]}"
do
    ret_pid=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'pgrep --full "bash /home/sol/start-dos-test.sh*"' > pid.txt) || true
    pid=$(cat pid.txt)
    [[ $pid == "" ]] && echo "$sship has finished run mango-simulation" || echo "pid=$pid"
    while [ "$pid" != "" ]
    do
        sleep $TERMINATION_CHECK_INTERVAL
        ret_pid=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'pgrep --full "bash /home/sol/start-dos-test.sh*"' > pid.txt) || true
        pid=$(cat pid.txt)
        [[ $pid == "" ]] && echo "$sship has finished run mango-simulation" || echo "pid=$pid"
    done
done
estimate_stop_time=$(get_time_after $star_time $DURATION)

### Get Time Stop
stop_time=$(date -u +%s)
stop_time_adjust=$(get_time_before $stop_time 5)
echo ----- stage: DOS report ------
testnet_version=$(get_testnet_ver $ENDPOINT)
# ## PASS ENV
[[ $SLACK_WEBHOOK ]]&&echo "SLACK_WEBHOOK=$SLACK_WEBHOOK" > dos-report-env.sh
[[ $DISCORD_WEBHOOK ]]&&echo "DISCORD_WEBHOOK=$DISCORD_WEBHOOK" >> dos-report-env.sh
[[ $DISCORD_AVATAR_URL ]]&&echo "DISCORD_AVATAR_URL=$DISCORD_AVATAR_URL" >> dos-report-env.sh

echo "START_TIME=${start_time}" >> dos-report-env.sh
echo "START_TIME2=${start_time_adjust}" >> dos-report-env.sh
echo "STOP_TIME=${stop_time}" >> dos-report-env.sh
echo "STOP_TIME2=${stop_time_adjust}" >> dos-report-env.sh
echo "DURATION=$DURATION" >> dos-report-env.sh                 
echo "QOUTES_PER_SECOND=$QOUTES_PER_SECOND" >> dos-report-env.sh
echo "NUM_CLIENT=$NUM_CLIENT" >> dos-report-env.sh
echo "CLUSTER_VERSION=$testnet_version" >> dos-report-env.sh
echo "BUILDKITE_BUILD_URL=$BUILDKITE_BUILD_URL" >> dos-report-env.sh
for n in "${instance_name[@]}"
do
    printf -v instances "%s %s " $instances $n
done
echo "INSTANCES=\"$instances\"" >> dos-report-env.sh
ret_dos_report=$(exec ./dos-report.sh)
echo ----- stage: upload logs ------
cnt=1
for sship in "${instance_ip[@]}"
do
    ret_pre_build=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship /home/sol/start-upload-logs.sh $cnt)
    (( cnt++ )) || true
done
sleep 5
echo ----- stage: delete instances ------
if [[ "$KEEP_INSTANCES" != "true" ]];then
    echo ----- stage: delete instances ------
    delete_machines
fi
exit 0




