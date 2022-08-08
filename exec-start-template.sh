#!/usr/bin/env bash
source ~/.bashrc
source ~/.profile
cd ~
if [[ -d "bench-tps-dos-test" ]];then
    rm  -rf "bench-tps-dos-test"
fi
if [[ -f "start-build-solana.sh" ]];then
    rm  "start-build-solana.sh"
fi
if [[ -f "start-dost-test.sh" ]];then
    rm  "start-dos-test.sh"
fi
