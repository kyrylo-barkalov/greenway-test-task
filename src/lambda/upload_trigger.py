import json
import os
import urllib.parse

import boto3


_sfn_client = boto3.client("stepfunctions")


def handler(event, context):
    state_machine_arn = os.environ["STATE_MACHINE_ARN"]
    execution_arns = []

    for record in event.get("Records", []):
        bucket_name = record["s3"]["bucket"]["name"]
        raw_key = record["s3"]["object"]["key"]
        object_key = urllib.parse.unquote_plus(raw_key)
        execution_name = f"exec-{context.aws_request_id}-{len(execution_arns)}"
        payload = {
            "trigger": "s3",
            "bucket": bucket_name,
            "key": object_key,
        }

        response = _sfn_client.start_execution(
            stateMachineArn=state_machine_arn,
            name=execution_name,
            input=json.dumps(payload, default=str),
        )
        execution_arns.append(response["executionArn"])

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "executions started",
                "execution_arns": execution_arns,
            }
        ),
    }
