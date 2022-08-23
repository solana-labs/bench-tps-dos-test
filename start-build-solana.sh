#!/usr/bin/env bash
## env
set -ex
base=$(pwd)
## Check ENV
if [[ ! "$SOLANA_BUILD_BRANCH" ]];then 
    echo No SOLANA_BUILD_BRANCH Env and exit > env.output
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
echo SOLANA_BUILD_BRANCH: $SOLANA_BUILD_BRANCH

## preventing lock-file build fail, 
## also need to disable software upgrade in image
sudo fuser -vki -TERM /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend || true
sudo dpkg --configure -a
sudo apt update

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
git checkout $SOLANA_BUILD_BRANCH
# install solana in  /solana/ci
cd $base/solana/ci
res=$(CI_OS_NAME=linux DO_NOT_PUBLISH_TAR=true CHANNEL=$CHANNEL ./publish-tarball.sh)
echo build result $res
exit 0