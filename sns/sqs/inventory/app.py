import json

def lambda_handler(event, context):

    print("===== Inventory Processor =====")

    print(json.dumps(event, indent=4))

    for record in event["Records"]:

        body = json.loads(record["body"])

        print("Inventory processing order:")

        print(body)

    return {
        "statusCode": 200
    }
    