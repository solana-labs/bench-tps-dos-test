# bench-tps-dos Test 
This is a implementation for
[bench-tps-dos gist](https://gist.github.com/joeaba/aba74e87dcd45c132a1ba2ddcaa2af7c)

## Usage
    Check  bench-tps-dos-QUIC & bench-tps-dos-UDP in buildkite.

## Environment in buildkite example
```
  BUILD_SOLANA: "false" 
  SOLANA_BUILD_BRANCH: same-as-cluster
  AVAILABLE_ZONE: "us-west2-b asia-east1-b asia-northeast1-a" 
  ENDPOINT: "http://123.123.123.123"
  NUM_CLIENT: 2
  SLACK_WEBHOOK: ""
  USE_TPU_CLIENT: "true"
  TPU_USE_QUIC: "true"
  DURATION: 1800
  TX_COUNT: 1000
  SUSTAINED: "true"
  KEYPAIR_FILE: "xxxxx.yaml"
```
+ Mandatory: ENDPOINT / NUM_CLIENT / SLACK_WEBHOOK
+ BUILD_SOLANA: "true" to build bench-tps from solana source
+ SOLANA_BUILD_BRANCH: git checkout branch/version to build solana (same-as-cluster/master/v1.10.32/10.1 ...etc.) default: same-as-cluster
+ AVAILABLE_ZONE: zones to create google cloud instance. (Be aware of quota issue)
+ NUM_CLIENT: 10 (default 10 for QUIC & 1 for UDP)
+ USE_TPU_CLIENT/TPU_USE_QUIC/DURATION/TX_COUNT/SUSTAINED arguments for bench-tps
+ KEYPAIR_FILE: keypair_files to use

## Flow
+ creates NUM_CLIENT google clound instances 
+ builds solana to use the latest bench-tps (option)
    + use BUILD_SOLANA=true to enable
    + downloads and builds https://github.com/solana-labs/solana
    + waits for NUM_CLIENT finishing build (blocking)
+ starts UDP/QUIC bench-tps DOS test by runing scripts in the instances
+ analyzes data by querying influxcloud
+ sends report to slack channel(SLACK_WEBHOOK)

## Files
+ dos-run.sh 
    Main process. To prepare environment variables, create google cloud instances, run benchmark and generate a report then send to slack
+ start-build-solana.sh
    The script downloads and builds solana 
+ start-dos-test.sh
    The script runs bench-tps DOS test in dynamically created gc instances
+ exec-start-template.sh 
    This file is used to generate exec-start-build-solana.sh to execute start-build-solana.sh 
    This file is used to generate exec-start-dos-test.sh to execute start-dos-test.sh 
+ dos-report-env.sh 
    The script is stored in bench-tps-dos bucket. It is downloaded by start-dos-test.sh. It has confidential environment for executing start-dos-test.sh
+ dos-report.sh
    The script generates a report from influxCloud and send it to a slack channel
+ influx_data.sh
    The script stores flux commands.

## Files in cloud storage
    Private files are stored in bench-tps-dos bucket in cloud storage.
    + environment variables for report
    + a key to ssh to dynamically created google cloud instances
    + keypair files for bench-tps
    + key for bench-tps


