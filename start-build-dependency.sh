#!/usr/bin/env bash
set -ex
## arg 1: wheather to build solana-bench-tps
## arg 2: ARTIFACT BUCKET
## arg 3: NAME OF ENV ARTIFACT FILE
## env

## fiunctions
## s1: bucket name s2: file name s3: local directory
# s1: local file s2: bucket name
upload_file() {
	gsutil cp  "$1" "$2"
}

download_file() {
    for retry in 0 1 2 3
    do
        if [[ $retry -gt 2 ]];then
            break
        fi
        gsutil cp "$1/$2" "$3"
        if [[ ! -f "$2" ]];then
            echo NO "$2" found, retry
        else
            echo "$2" dowloaded
            break
        fi
        sleep 5
    done
}

## Download key files from gsutil
echo "arg1"="$1"
[[ "$1" != "true" && "$1" != "false" ]] && build_binary="false" || build_binary="$1"
[[ ! "$2" ]]&& echo "No artifact bucket" && exit 1
[[ ! "$3" ]]&& echo "No artifact filename" && exit 1
# Download env-artifact.sh
download_file "gs://$2" "$3" "$HOME"
sleep 1
[[ ! -f "$3" ]] && echo no "$3" downloaded && exit 2
# shellcheck source=/dev/null
source $HOME/.profile
# shellcheck source=env-artifact.sh
source $HOME/env-artifact.sh

## preventing lock-file build fail, 
## also need to disable software upgrade in image
sudo fuser -vki -TERM /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend || true
sudo dpkg --configure -a
sudo apt update
## pre-install and rust version
sudo apt-get install -y libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler
rustup default stable
rustup update

echo ------- stage: git clone bench-tps-dos ------
cd $HOME
[[ -d "$GIT_REPO_DIR" ]]&& rm -rf $GIT_REPO_DIR
git clone "$BUILDKITE_REPO"
cd "$GIT_REPO_DIR"
git checkout "$BUILDKITE_BRANCH"
git branch
echo ------- stage: download solana repos and build solana-bench-tps ------
cd "$HOME"

if  [[ "$build_binary" == "true" ]];then 
    echo ------- build solana-bench-tps ------
    [[ -d "$HOME/solana" ]]&& rm -rf "$HOME/solana"
    git clone "$SOLANA_REPO"

    [[ -d "$HOME/solana" ]] || exit 1
    cd "$HOME/solana"
    if [[ "$GIT_COMMIT" ]];then
        git checkout "$GIT_COMMIT"
    elif [[ "$SOLANA_BUILD_BRANCH" ]];then
        git checkout "$SOLANA_BUILD_BRANCH"
    fi
    cd "$HOME/solana/bench-tps"
    [[ -f "$HOME/solana/target/release/solana-bench-tps" ]]&& rm "$HOME/solana/target/release/solana-bench-tps"
    res=$(cargo build --release > bench-tps-build.output)
    echo "$res"
    if [[ -f "$HOME/solana/target/release/solana-bench-tps" ]];then
        cp "$HOME/solana/target/release/solana-bench-tps"  "$HOME"
        upload_file "$HOME/solana-bench-tps" "gs://$ARTIFACT_BUCKET/$BUILDKITE_PIPELINE_ID/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID" 
    else
        echo "build solana-bench-tps fail"
        exit 1
    fi   
else
    echo ------- download from bucket ------
    download_file "gs://$ARTIFACT_BUCKET/$BUILDKITE_PIPELINE_ID/$BUILDKITE_BUILD_ID/$BUILDKITE_JOB_ID" "$BENCH_TPS_ARTIFACT_FILE" "$HOME"
    [[ ! -f "$HOME/solana-bench-tps" ]] && echo no solana-bench-tps && exit 1
    chmod +x "$HOME/solana-bench-tps"
fi 

echo ---- stage: copy files to HOME and mkdir log folder ----
cp "$HOME/$GIT_REPO_DIR/start-dos-test.sh" $HOME/start-dos-test.sh
cp "$HOME/$GIT_REPO_DIR/start-upload-logs.sh" $HOME/start-upload-logs.sh
[[ -d "$HOME/$HOSTNAME" ]] && rm -rf "$HOME/$HOSTNAME"
mkdir -p "$HOME/$HOSTNAME"

echo ---- stage: download id, accounts and authority file in HOME ----
cd "$HOME"
download_file "gs://$DOS_BENCH_TPS_PRIVATE_BUCKET" "$ID_FILE" "$HOME"
[[ ! -f "$ID_FILE" ]]&&echo no "$ID_FILE" file && exit 1
download_file "gs://$DOS_BENCH_TPS_PRIVATE_BUCKET" "$KEYPAIR_TAR_FILE" "$HOME"
[[ ! -f "$KEYPAIR_TAR_FILE" ]]&&echo no "$KEYPAIR_TAR_FILE" file && exit 1
tar -xzvf $KEYPAIR_TAR_FILE
[[ ! -f "$HOME/keypair-configs/$KEYPAIR_FILE" ]]&&echo no "$KEYPAIR_FILE" file && exit 1
cp "$HOME/keypair-configs/$KEYPAIR_FILE" "$HOME"
exit 0
