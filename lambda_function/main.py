import base64
import gzip
import io
import json
from datetime import datetime
import os
from zoneinfo import ZoneInfo
import http.client


def send_slack_message(slack_message):
    slack_webhook_url = os.getenv("SLACK_WEBHOOK_URL")
    data = {
        "text": slack_message
    }
    json_data = json.dumps(data)

    headers = {
        "Content-type": "application/json"
    }

    conn = http.client.HTTPSConnection("hooks.slack.com")
    conn.request("POST", slack_webhook_url, json_data, headers)
    response = conn.getresponse()

    # Print the response status and data
    print("Response Status:", response.status)
    print("Response Data:", response.read().decode())

    conn.close()
    

def process_event(event):
    base64_data = event['awslogs']['data']
    binary_data = base64.b64decode(base64_data)

    with gzip.GzipFile(fileobj=io.BytesIO(binary_data)) as uncompressed_data:
        data = uncompressed_data.read().decode()
        json_data = json.loads(data)
        message = json.loads(json_data['logEvents'][0]['message'])

        user = message['userIdentity']['userName']
        instance_id = message["responseElements"]["instancesSet"]["items"][0]["instanceId"]
        event_time = message["eventTime"]
        region = message["awsRegion"]
        original_datetime = datetime.fromisoformat(event_time)
        result_timestamp = original_datetime.astimezone(tz=ZoneInfo("Africa/Lagos"))

        slack_message = f"{user} has started EC2 instance: {instance_id} in {region} region at {result_timestamp}"

        send_slack_message(slack_message)
