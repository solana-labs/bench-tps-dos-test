#!/usr/bin/env bash
# benchmark
set -ex

if [[ ! "$RPC_ENDPOINT" ]];then
    echo "No RPC_ENDPOINT"
    exit 1
fi

if [[ ! "$ID_DIR" ]];then
    ID_DIR=id
    echo No ID_DIR Env , use $ID_DIR >> dos-env.out
fi
if [[ ! "$ID_FILE" ]];then
    ID_FILE=testnet-dos-funder.json
    echo No ID_FILE Env , use $ID_FILE >> dos-env.out
fi

if [[ ! "$KEYPAIR_DIR" ]];then
    KEYPAIR_DIR=keypair-configs
    echo No KEYPAIR_DIR Env , use $KEYPAIR_DIR >> dos-env.out
fi

if [[ ! "$KEYPAIR_FILE" ]];then
    KEYPAIR_FILE=large-keypairs.yaml
    echo No KEYPAIR_DIR Env , use $KEYPAIR_FILE >> dos-env.out
fi

if [[ ! "$KEYPAIR_TAR_FILE" ]];then
    KEYPAIR_TAR_FILE=keypair-configs.tgz
    echo No KEYPAIR_TAR_FILE Env , use $KEYPAIR_TAR_FILE >> dos-env.out
fi
#### bench-tps ENV ####
echo --- stage:setup ENV ---
# b) use_tpu_client (boolean, if true --use-tpu-client, if false --use-rpc-client)
if [[ ! "$USE_TPU_CLIENT" ]];then
    USE_TPU_CLIENT="false"
fi
if [[ "$USE_TPU_CLIENT" == "true" ]];then
    use_client="--use-tpu-client"
else
    use_client="--use-rpc-client"
fi

# c) tpu_use_quic (boolean, if true --tpu-use-quic, if false nothing) --> false does UDP
# f) tx_count (--tx_count 10000 for the UDP test and --tx_count 2000 per client for the QUIC 
# g) thread_batch_sleep ( --thread-batch-sleep-ms 1 for UDP --thread-batch-sleep-ms 10 for QUIC)

if [[ "$TPU_USE_QUIC" == "true" ]];then
    tpu_use_quic="--tpu-use-quic"
    thread_batch_sleep_ms=10
    if [[ ! "$TX_COUNT" ]];then
        tx_count=2000
    else
        tx_count=$TX_COUNT
    fi
else  
    tpu_use_quic=""
    thread_batch_sleep_ms=1
    if [[ ! "$TX_COUNT" ]];then
        tx_count=10000
    else
        tx_count=$TX_COUNT
    fi
fi
# d) sustained (boolean, if true --sustained, if false nothing)
if [[ ! "$SUSTAINED" ]];then
    SUSTAINED="false"
fi
if [[ "$SUSTAINED" == "true" ]];then
    sustained="--sustained"
else
    sustained=""
fi
# e) duration (default --duration 1800) 
if [[ ! "$DURATION" ]];then
    duration=1800
    echo No DURATION Env , use $DURATION >> dos-env.out
else
    duration=$DURATION
fi


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
# Prepare keys
cd ~
base=$(pwd)
if [[ -d "$ID_DIR" ]];then #remove old
       	rm -rf $ID_DIR   
fi
mkdir $ID_DIR
cd $ID_DIR
file_in_bucket=$ID_FILE
download_file

cd $base
if [[ -d "$KEYPAIR_DIR" ]];then
	rm -r $KEYPAIR_DIR
fi
file_in_bucket=$KEYPAIR_TAR_FILE
download_file
tar -xzvf $KEYPAIR_TAR_FILE

# benchmark exec
cd $base/solana/solana-release/bin
echo --- start of benchmark $(date)
echo KEYPAIR_FILE $KEYPAIR_FILE
echo keyfile : $base/$KEYPAIR_DIR/$KEYPAIR_FILE

benchmark=$(./solana-bench-tps -u $RPC_ENDPOINT --identity $base/$ID_DIR/$ID_FILE --read-client-keys $base/$KEYPAIR_DIR/$KEYPAIR_FILE \
		$use_client $sustained $tpu_use_quic  --duration $duration --tx_count $tx_count --thread-batch-sleep-ms $thread_batch_sleep_ms)

echo $benchmark
echo --- end of benchmark $(date)
