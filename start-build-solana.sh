#!/usr/bin/env bash
## env
set -ex
base=$(pwd)
## Check ENV
[[ ! "$SOLANA_BUILD_BRANCH" ]]&&[[ ! "$GIT_COMMIT" ]]&& echo No SOLANA_BUILD_BRANCH or GIT_COMMIT > env.output&&exit 1
[[ ! "$SOLANA_REPO" ]]&& echo no SOLANA_REPO=$SOLANA_REPO&& exit 1
[[ ! "$CHANNEL" ]]&& CHANNEL=edge&&echo No CHANNEL , use $CHANNEL >> env.output
[[ ! "$RUST_VER" ]]&& RUST_VER=default&&echo No RUST_VER use $RUST_VER >> env.output

# Printout Env
echo CHANNEL: $CHANNEL 
echo RUST_VER: $RUST_VER
echo SOLANA_BUILD_BRANCH: $SOLANA_BUILD_BRANCH
echo GIT_COMMIT: $GIT_COMMIT
echo SOLANA_REPO: $SOLANA_REPO

## preventing lock-file build fail, 
## also need to disable software upgrade in image
sudo fuser -vki -TERM /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend || true
sudo dpkg --configure -a
sudo apt update

## pre-install and rust version
sudo apt-get install -y libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler

rustup default stable
if [[ $RUST_VER ]];then
    rustup default nightly
fi
rustup update

# set base directory

if [[ -d "$base/solana" ]];then
    rm -rf solana
fi

git clone $SOLANA_REPO
cd $base/solana
if [[ "$GIT_COMMIT" ]];then
    git checkout $GIT_COMMIT
elif [[ "$SOLANA_BUILD_BRANCH" ]];then
    git checkout $SOLANA_BUILD_BRANCH
else 
    exit 1
fi
git branch || true
# install solana in  /solana/ci
#cd $base/solana/ci
# res=$(CI_OS_NAME=linux DO_NOT_PUBLISH_TAR=true CHANNEL=$CHANNEL ./publish-tarball.sh)
cd $base/solana/bech-tps
res=$(cargo build --release)
echo build result $res
exit 0