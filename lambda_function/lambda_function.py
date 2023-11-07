from main import process_event
import json

def lambda_handler(event, context):
    process_event(event)

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
