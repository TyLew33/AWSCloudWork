import json

def lambda_handler(event, context):

    print("===== Email Processor =====")

    print(json.dumps(event, indent=4))

    for record in event["Records"]:

        body = json.loads(record["body"])

        print("Sending confirmation email for:")

        print(body)

    return {
        "statusCode": 200
    }