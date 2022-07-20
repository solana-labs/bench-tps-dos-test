#!/usr/bin/env bash
msg=$(jq -n --arg v "$header" '[$v]')

if [[ -z "$SLACK_WEBHOOK"  ]];then
	echo "ERROR : SLACK_WEBHOOK=$SLACK_WEBHOOK"
	exit 1
fi

slack_alert(){
    sdata=$(jq --null-input --arg val "$slack_text" '{"blocks":$val}')
    curl -X POST -H 'Content-type: application/json' --data "$sdata" $SLACK_WEBHOOK    
}

b1="{
		\"type\": \"actions\",
		\"elements\": [
			{
				\"type\": \"button\",
				\"text\": {
					\"type\": \"plain_text\",
					\"text\": \"Grafana\"
				},
				\"url\": \"${gf_url}\"
			}
		]
	}"
b2='{
			"type": "header",
			"text": {
				"type": "plain_text",
				"text": "Test_Configuration",
				"emoji": true
			}
	}'
b3="{\"type\": \"section\",\"text\": {\"type\":\"mrkdwn\",\"text\": ${conf}}}"
b4='{
	    "type": "header",
		"text": {
			"type": "plain_text",
			"text": "Result_Details",
			"emoji": true
		}
	}'
b5="{\"type\": \"section\",\"text\": {\"type\":\"mrkdwn\",\"text\": ${detail}}}"

