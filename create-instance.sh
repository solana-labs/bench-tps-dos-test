#!/usr/bin/env bash
set -ex
declare -a instance_ip
declare -a instance_name
declare -a instance_zone
create_interval=60
[[ ! "$GC_IMAGE" ]] && GC_IMAGE=mango-simulation-client-230508 && echo GC_IMAGE env not found, use $GC_IMAGE
[[ ! "$AVAILABLE_ZONE" ]]&&	available_zone=( us-west2-b asia-east1-b asia-northeast1-a ) || available_zone=( $AVAILABLE_ZONE )


function create_gce() {
	local vm_name=bench-tps-client-$(date +%y%m%d-%H-%M-%S)
	local project=principal-lane-200702
	local img_name=$GC_IMAGE
	local machine_type=n1-standard-32
	local network_tag=allow-everything,allow-everything-egress
	if [[ ! "$1" ]];then
		zone=asia-east1-b
	fi
	ret_create=$(gcloud beta compute instances create "$vm_name" \
		--project=$project \
		--source-machine-image="$img_name" \
		--zone="$1" \
		--machine-type="$machine_type" \
		--network-interface=network-tier=PREMIUM,subnet=default \
		--maintenance-policy=MIGRATE \
		--service-account=dos-test@principal-lane-200702.iam.gserviceaccount.com \
		--scopes=https://www.googleapis.com/auth/cloud-platform \
		--tags="$network_tag" \
		--no-shielded-secure-boot \
		--shielded-vtpm \
		--shielded-integrity-monitoring \
		--format="flattened(name,networkInterfaces[0].accessConfigs[0].natIP)" \
		--reservation-affinity=any)
	echo $ret_create > ret_create.out # will be used for parsing ip and name
    gce_create_exit="$?"
    # testing
    # ret_create="--- name: mango-bencher-tester-221219-07-44-58 nat_ip: 34.83.208.239"
    # echo $ret_create > ret_create.out
    # gce_create_exit=0
	if [[ $gce_create_exit -eq 0 || $gce_create_exit == "0" ]];then
		instance_zone+=("$zone")
		sship=$(sed 's/^.*nat_ip: //g' ret_create.out)
		instance_ip+=("$sship")
		gc_name=$(sed 's/^.*--- name: //g' ret_create.out | sed 's/ nat_ip:.*//g')
		instance_name+=("$gc_name")
	else
		exit $gce_create_exit
	fi 
}

function create_machines() {
    instance_ip=()
    instance_name=()
    instance_zone=()
    for _ in $(seq 1 "$1")
    do
        if [[ $count -ge ${#available_zone[@]} ]];then
            count=0
        fi 
        zone=${available_zone[$count]}
        create_gce "$zone"
		(( count+=1 )) || true
        echo "gc instance is created in $zone"
        sleep $create_interval # avoid too quick build
    done
    echo "${instance_ip[@]}" > instance_ip.out
    echo "${instance_zone[@]}" > instance_name.out
    echo "${instance_zone[@]}" > instance_zone.out
}

function append_machines() {
    for _ in $(seq 1 "$1")
    do
        if [[ $count -ge ${#available_zone[@]} ]];then
            count=0
        fi 
        zone=${available_zone[$count]}
        create_gce "$zone" "append"
       (( count+=1 )) || true
        echo "gc instance is created in $zone"
        sleep $create_interval # avoid too quick build
    done
    echo "${instance_ip[@]}" > instance_ip.out
    echo "${instance_zone[@]}" > instance_name.out
    echo "${instance_zone[@]}" > instance_zone.out
}


function delete_machines(){
    echo ----- stage: remove gc instances ------
	echo instance_name : "${instance_name[@]}"
	echo instance_zone : "${instance_zone[@]}"
	for idx in "${!instance_name[@]}"
	do
		gcloud compute instances delete --quiet "${instance_name[$idx]}" --zone="${instance_zone[$idx]}"
	done
}