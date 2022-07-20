#!/usr/bin/env bash
source ~/.bashrc
source ~/.profile
cd ~
if [[ -d "bench-tps-dos-run" ]];then
    rm  "bench-tps-dos-run"
fi
if [[ -f "start-build-solana.sh" ]];then
    rm  "start-build-solana.sh"
fi
if [[ -f "start-dost-test.sh" ]];then
    rm  "start-dos-test.sh"
fi
if [[ -d "cluster-ops" ]];then
    rm -rf "cluster-ops"
fi
