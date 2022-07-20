#!/usr/bin/env bash
if [[ -f "dos-report-env.sh" ]];then
    rm -f dos-report-env.sh
	echo "dos-report-env.sh removed"
fi
if [[ -f "exec-start-dos-test.sh" ]];then
    rm -f exec-start-dos-test.sh
	echo "exec-start-dos-test.sh removed"
fi
if [[ -f "exec-start-build-solana.sh" ]];then
    rm -f exec-start-build-solana.sh
	echo "exec-start-build-solana.sh removed"
fi
if [[ -f "id_ed25519_dos_test" ]];then
    rm -f id_ed25519_dos_test
	echo "id_ed25519_dos_test removed"
fi

if [[ -f "query.result" ]];then
    rm -f query.result
	echo "query.result removed"
fi
if [[ -f "ret_create.out" ]];then
    rm -f ret_create.out
	echo "ret_create.out removed"
fi