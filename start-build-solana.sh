#!/usr/bin/env bash
## env
set -ex
base=$(pwd)
## Check ENV
if [[ ! "$TESTNET_VER" ]];then 
    echo No TESTNET_VER Env, use $TESTNET_VER and exit >> env.output
    exit 1
fi
if [[ ! "$CHANNEL" ]];then
    CHANNEL=edge
    echo No CHANNEL Env , use $CHANNEL >> env.output
fi

if [[ ! "$RUST_VER" ]];then 
    RUST_VER=default
    echo No RUST_VER Env, use $RUST_VER >> env.output
fi
# Printout Env
echo CHANNEL: $CHANNEL 
echo RUST_VER: $RUST_VER
echo TESTNET_VER: $TESTNET_VER

## pre-install and rust version
sudo apt-get install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler

rustup default stable
if [[ $RUST_VER ]];then
    rustup default nightly
fi
rustup update

# set base directory
# download solana
repo=https://github.com/solana-labs/solana.git
if [[ -d "$base/solana" ]];then
    rm -rf solana
fi

git clone $repo
cd $base/solana
git checkout $TESTNET_VER
# install solana in  /solana/ci
cd $base/solana/ci
res=$(CI_OS_NAME=linux DO_NOT_PUBLISH_TAR=true CHANNEL=$CHANNEL ./publish-tarball.sh)
echo build result $res
exit 0