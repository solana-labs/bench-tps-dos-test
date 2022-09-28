#!/usr/bin/env bash
set -x
declare -a instance_ip
declare -a instance_name
declare -a instance_zone

# Check ENVs
[[ ! "$GIT_TOKEN" ]]&& echo GIT_TOKEN env not found && exit 1
[[ ! "$ENDPOINT" ]]&& echo ENDPOINT env not found && exit 1
[[ ! "$NUM_CLIENT" ]]&& echo NUM_CLIENT env not found && exit 1
[[ ! "$TEST_TYPE" ]]&& echo TEST_TYPE env not found && exit 1
[[ ! $SLACK_WEBHOOK ]]&&[[ ! $DISCORD_WEBHOOK ]]&& echo no WEBHOOK found&&exit 1

[[ ! "$SOLANA_BUILD_BRANCH" ]]&& SOLANA_BUILD_BRANCH=same-as-cluster&& echo SOLANA_BUILD_BRANCH env not found, use $SOLANA_BUILD_BRANCH
[[ ! "$RUN_BENCH_AT_TS_UTC" ]]&& RUN_BENCH_AT_TS_UTC=0 && echo RUN_BENCH_AT_TS_UTC env not found, use $RUN_BENCH_AT_TS_UTC
[[ ! "$TPU_USE_QUIC" ]]&& TPU_USE_QUIC="false" && echo TPU_USE_QUIC env not found, use $TPU_USE_QUIC
[[ ! "$TPU_DISABLE_QUIC" ]]&& TPU_DISABLE_QUIC=0 && echo TPU_DISABLE_QUIC env not found, use $TPU_DISABLE_QUIC
[[ ! "$KEEP_INSTANCES" ]]&& KEEP_INSTANCES="false" && echo KEEP_INSTANCES env not found, use $KEEP_INSTANCES
[[ ! "$SOLANA_REPO"]]&& SOLANA_REPO=https://github.com/solana-labs/solana.git

get_time_after() {
	outcom_in_sec=$(echo ${given_ts} + ${add_secs} | bc) 
}

get_time_before() {
	outcom_in_sec=$(echo ${given_ts} - ${minus_secs} | bc) 
}

download_file() {
	for retry in 0 1
	do
		if [[ $retry -gt 1 ]];then
			break
		fi

		gsutil cp  gs://bench-tps-dos/$file_in_bucket ./

		if [[ ! -f "$file_in_bucket" ]];then
			echo "NO $file_in_bucket found, retry"
		else
			break
		fi
	done
}

function get_testnet_ver() {
    local ret
    for retry in 0 1 2
    do
        if [[ $retry -gt 1 ]];then
            break
        fi
        ret=$(curl $ENDPOINT -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getVersion"}
        ' | jq '.result."solana-core"' | sed 's/\"//g') || true
        echo get_testnet_ver ret: $ret
        if [[ $ret =~ [0-9]+.[0-9]+.[0-9]+ ]];then
            echo get version
            break
        fi
        sleep 3
    done
    if [[ ! $ret =~ ^[0-9]+.[0-9]+.[0-9]+ ]];then
        testnet_ver=master
        break
    else
        #adding a v because the branch has a v
        testnet_ver=$(echo v$ret)
    fi
}

create_gce() {
	vm_name=dos-test-`date +%y%m%d-%H-%M-%S`
	project=principal-lane-200702
	img_name=bnech-tps-dos-img-220829
	if [[ ! "$zone" ]];then
		zone=asia-east1-b
	fi
	machine_type=n1-standard-32
	network_tag=allow-everything,allow-everything-egress
	ret_create=$(gcloud beta compute instances create $vm_name \
		--project=$project \
		--source-machine-image=$img_name \
		--zone=$zone \
		--machine-type=$machine_type \
		--network-interface=network-tier=PREMIUM,subnet=default \
		--maintenance-policy=MIGRATE \
		--service-account=dos-test@principal-lane-200702.iam.gserviceaccount.com \
		--scopes=https://www.googleapis.com/auth/cloud-platform \
		--tags=$network_tag \
		--no-shielded-secure-boot \
		--shielded-vtpm \
		--shielded-integrity-monitoring \
		--format="flattened(name,networkInterfaces[0].accessConfigs[0].natIP)" \
		--reservation-affinity=any)
	echo $ret_create > ret_create.out
	sship=$(sed 's/^.*nat_ip: //g' ret_create.out)
	instance_ip+=($sship)
	gc_name=$(sed 's/^.*--- name: //g' ret_create.out | sed 's/ nat_ip:.*//g')
	instance_name+=($gc_name)
	instance_zone+=($zone)
}

### Main ###
echo ----- stage: get cluster version and git information --- 
get_testnet_ver
TESTNET_VER=$testnet_ver
if [[ "$SOLANA_BUILD_BRANCH" == "same-as-cluster" ]];then
	SOLANA_BUILD_BRANCH=$TESTNET_VER
fi
if [[ -d "./solana" ]];then
    rm -rf solana
fi
ret=$(git clone https://github.com/solana-labs/solana.git)
if [[ -d solana ]];then
	cd ./solana
	ret=$(git checkout $SOLANA_BUILD_BRANCH)
	GIT_COMMIT=$(git rev-parse HEAD)
	cd ../
else
	echo "can not clone https://github.com/solana-labs/solana.git"
	exit 1
fi

echo ----- stage: prepare metrics env ------ 
if [[ -f "dos-metrics-env.sh" ]];then
    rm dos-metrics-env.sh
fi
file_in_bucket=dos-metrics-env.sh
download_file
if [[ ! -f "dos-metrics-env.sh" ]];then
	echo "NO dos-metrics-env.sh found"
	exit 1
fi
echo $file_in_bucket is download
source dos-metrics-env.sh

echo ----- stage: prepare execute scripts ------
file_in_bucket=id_ed25519_dos_test
download_file

if [[ ! -f "id_ed25519_dos_test" ]];then
	echo "no id_ed25519_dos_test found"
	exit 1
fi
echo id_ed25519_dos_test is download
chmod 600 id_ed25519_dos_test
ls -al id_ed25519_dos_test

if [[ -f "exec-start-solana-build.sh" ]];then
    rm exec-start-solana-build.sh
fi

if [[ -f "exec-start-dos-test.sh" ]];then
    rm exec-start-dos-test.sh
fi
# add git repo to exe-start-template
echo "git clone https://github.com/solana-labs/bench-tps-dos-test.git" >> exec-start-template.sh
echo "cd bench-tps-dos-test" >> exec-start-template.sh
echo "git checkout $BUILDKITE_BRANCH" >> exec-start-template.sh
echo "cd ~" >> exec-start-template.sh
echo 'cp ~/bench-tps-dos-test/start-build-solana.sh .' >> exec-start-template.sh
echo 'cp ~/bench-tps-dos-test/start-dos-test.sh .' >> exec-start-template.sh
echo "export SOLANA_METRICS_CONFIG=\"$SOLANA_METRICS_CONFIG\"" >> exec-start-template.sh
if [[ ! "$BUILD_SOLANA" ]];then
	BUILD_SOLANA="false"
fi
# add information to exec-start-build-solana.sh
if [[ "$BUILD_SOLANA" == "true" ]];then
	[[ ! "$CHANNEL" ]]&& CHANNEL=edge
	[[ -f "exec-start-build-solana.sh" ]]&& rm  exec-start-build-solana.sh 
	sed  -e 19a\\"export CHANNEL=$CHANNEL" exec-start-template.sh > exec-start-build-solana.sh 
	echo "export SOLANA_BUILD_BRANCH=$SOLANA_BUILD_BRANCH" >> exec-start-build-solana.sh
	echo "export GIT_COMMIT=$GIT_COMMIT" >> exec-start-build-solana.sh
	echo "export SOLANA_REPO=$SOLANA_REPO" >> exec-start-build-solana.sh
	chmod +x exec-start-build-solana.sh
	cat exec-start-build-solana.sh
	[[ ! -f "exec-start-build-solana.sh" ]]&& echo "no exec-build-solana.sh found"&& exit 1
	echo 'exec  ./start-build-solana.sh > start-build-solana.log' >> exec-start-build-solana.sh
fi
# add information to exec-start-dos-test.sh
[[ -f "exec-start-dos-test.sh" ]]&&	rm  exec-start-dos-test.sh

sed  -e 19a\\"export RPC_ENDPOINT=$ENDPOINT" exec-start-template.sh > exec-start-dos-test.sh

chmod +x exec-start-dos-test.sh

echo "export TEST_TYPE=$TEST_TYPE" >> exec-start-dos-test.sh 
if [[ "$USE_TPU_CLIENT" == "true" ]];then
	 echo "export USE_TPU_CLIENT=\"true\"" >> exec-start-dos-test.sh
else 
	echo "export USE_TPU_CLIENT=\"false\"" >> exec-start-dos-test.sh
fi
if [[ "$TPU_USE_QUIC" == "true" ]];then
	 echo "export TPU_USE_QUIC=\"true\"" >> exec-start-dos-test.sh
else
	 echo "export TPU_USE_QUIC=\"false\"" >> exec-start-dos-test.sh
fi

if [[ "$TPU_DISABLE_QUIC" == "true" ]];then
	 echo "export TPU_DISABLE_QUIC=\"true\"" >> exec-start-dos-test.sh
else
	 echo "export TPU_DISABLE_QUIC=\"false\"" >> exec-start-dos-test.sh
fi
if [[ "$DURATION" ]];then
    echo "export DURATION=$DURATION" >> exec-start-dos-test.sh
fi
if [[ "$TX_COUNT" ]];then
    echo "export TX_COUNT=$TX_COUNT" >> exec-start-dos-test.sh
fi
if [[ "$THREAD_BATCH_SLEEP_MS" ]];then
    echo "export THREAD_BATCH_SLEEP_MS=$THREAD_BATCH_SLEEP_MS" >> exec-start-dos-test.sh
fi
if [[ "$SUSTAINED" ]];then
    echo "export SUSTAINED=$SUSTAINED" >> exec-start-dos-test.sh
fi
if [[ "$USE_DURABLE_NONCE" ]];then
    echo "export USE_DURABLE_NONCE=$USE_DURABLE_NONCE" >> exec-start-dos-test.sh
fi
if [[ "$KEYPAIR_FILE" ]];then
    echo "export KEYPAIR_FILE=$KEYPAIR_FILE" >> exec-start-dos-test.sh
fi

cat exec-start-dos-test.sh

# in order to do none-blocking  run nohup in background
echo 'exec nohup ./start-dos-test.sh > start-dos-test.log 2>start-dos-test.nohup &' >> exec-start-dos-test.sh

echo ----- stage: create gc instances ------
declare -a available_zone
if [[ ! "$AVAILABLE_ZONE" ]];then
	available_zone=( us-west2-b asia-east1-b asia-northeast1-a )
else
	available_zone=( $AVAILABLE_ZONE )
fi

for i in $(seq 1 $NUM_CLIENT)
do
	if [[ $count -ge ${#available_zone[@]} ]];then
    	count=0
    fi 
	zone=${available_zone[$count]}
	create_gce
	let count+=1
	echo "gc instance is created in $zone"
	sleep 20 # avoid too quick build
done
sleep 60 # delay for ssh to be ready 
echo "instance_ip ${instance_ip[@]}"
echo "instance_name ${instance_name[@]}"
echo "instance_zone ${instance_zone[@]}"

if [[ "$BUILD_SOLANA" == "true" ]];then
	echo ----- stage: pre-build solana ------
	for sship in "${instance_ip[@]}"
	do
		echo run pre start:$sship
		ret_pre_build=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'bash -s' < exec-start-build-solana.sh)
	done
fi
echo ----- stage: timed to start benchmark ------
if [[ $RUN_BENCH_AT_TS_UTC -gt 0 ]];then
	cur_time=$(echo `date -u +%s`)
	if [[ $cur_time -gt $RUN_BENCH_AT_TS_UTC ]];then
		echo "current timestamp ($cur_time) has passed specified $RUN_BENCH_AT_TS_UTC timestamp. Abort!"
		exit 1
	fi
	while [[ $cur_time -lt $RUN_BENCH_AT_TS_UTC ]];
	do
		sleep 1
		cur_time=$(echo `date -u +%s`)
	done

fi


echo ----- stage: run benchmark-tps background ------
# Get Time Start
adjust_ts=5
start_time=$(echo `date -u +%s`)
given_ts=$start_time
add_secs=$adjust_ts
get_time_after
start_time2=$outcom_in_sec

for sship in "${instance_ip[@]}"
do
	ret_benchmark=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@$sship 'bash -s' < exec-start-dos-test.sh)
done

echo ----- stage: wait for benchmark to end ------
sleep_time=$(echo "$DURATION+2" | bc)
sleep $sleep_time

### Get Time Stop
adjust_ts=10
stop_time=$(echo `date -u +%s`)
given_ts=$stop_time
minus_secs=$adjust_ts
get_time_before
stop_time2=$outcom_in_sec

echo ----- stage: DOS report ------
## PASS ENV
if [[ ! "$TPU_USE_QUIC" ]];then
	TPU_USE_QUIC="false"
fi

echo "CLUSTER_VERSION=$TESTNET_VER" >> dos-report-env.sh
echo "GIT_COMMIT=$GIT_COMMIT" >> dos-report-env.sh
echo "NUM_CLIENT=$NUM_CLIENT" >> dos-report-env.sh
if [[ ! "$KEYPAIR_FILE" ]];then # use default
    KEYPAIR_FILE=large-keypairs.yaml
fi
echo "KEYPAIR_FILE=$KEYPAIR_FILE" >> dos-report-env.sh
if [[ ! "$DURATION" ]];then
	DURATION=1800
fi
echo "DURATION=$DURATION" >> dos-report-env.sh
if [[ ! "$TX_COUNT" ]];then
	TX_COUNT=10000
fi
echo "TX_COUNT=$TX_COUNT" >> dos-report-env.sh

if [[ ! "$THREAD_BATCH_SLEEP_MS" ]];then
	THREAD_BATCH_SLEEP_MS=1
fi

echo "THREAD_BATCH_SLEEP_MS=$THREAD_BATCH_SLEEP_MS" >> dos-report-env.sh
echo "SOLANA_BUILD_BRANCH=$SOLANA_BUILD_BRANCH" >> dos-report-env.sh

if [[ ! "$SUSTAINED" ]];then
    SUSTAINED="false"
fi
echo "SUSTAINED=$SUSTAINED" >> dos-report-env.sh
[[ $SLACK_WEBHOOK ]]&&echo "SLACK_WEBHOOK=$SLACK_WEBHOOK" >> dos-report-env.sh
[[ $DISCORD_WEBHOOK ]]&&echo "DISCORD_WEBHOOK=$DISCORD_WEBHOOK" >> dos-report-env.sh
[[ $DISCORD_AVATAR_URL ]]&&echo "DISCORD_AVATAR_URL=$DISCORD_AVATAR_URL" >> dos-report-env.sh
echo "START_TIME=${start_time}" >> dos-report-env.sh
echo "START_TIME2=${start_time2}" >> dos-report-env.sh
echo "STOP_TIME=${stop_time}" >> dos-report-env.sh
echo "STOP_TIME2=${stop_time2}" >> dos-report-env.sh
cat dos-report-env.sh
ret_dos_report=$(exec ./dos-report.sh)
echo $ret_dos_report

echo ----- stage: printout run log ------
if [[ "$PRINT_LOG" == "true" ]];then
	ret_log=$(ssh -i id_ed25519_dos_test -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sol@${instance_ip[0]} 'cat /home/sol/start-dos-test.nohup')
fi

echo ----- stage: remove gc instances ------
if [[ ! "$KEEP_INSTANCES" == "true" ]];then
	echo "instance_name : ${instance_name[@]}"
	echo "instance_zone : ${instance_zone[@]}"
	for idx in "${!instance_name[@]}"
	do
		gcloud compute instances delete --quiet ${instance_name[$idx]} --zone=${instance_zone[$idx]}
		echo delete $vms
	done
fi

exit 0
