#!/usr/bin/env bash
set -ex
# shellcheck source=/dev/null
source $HOME/.profile
# shellcheck source=/dev/null
source $HOME/env-artifact.sh

upload_log_folder() {
	gsutil cp -r $1 gs://mango_bencher-dos-log/$BUILDKITE_BUILD_NUMBER/
}

echo ----- stage: upload logs: make folder and move logs ------
cd $HOME
[[ -d "$HOME/$HOSTNAME" ]] && ls -al "$HOME/$HOSTNAME" || exit 1
upload_log_folder "$HOME/$HOSTNAME"

if [[ -f  "$HOME/start-dos-test.nohup" ]];then
	# must upload to build level, otherwise when the printlog in different job, it cannot find the file
	ret_upload_nohup=$(gsutil cp "$HOME/start-dos-test.nohup" "gs://$ARTIFACT_BUCKET/$BUILDKITE_PIPELINE_ID/$BUILDKITE_BUILD_ID/start-dos-test-$1.nohup") || true
else 
	echo no start-dos-test.nohup found in $home
fi
# [[ -f  "$HOME/start-dos-test.nohup" ]]&& cat start-dos-test.nohup || true

echo "all logs are uploaded"
exit 0

