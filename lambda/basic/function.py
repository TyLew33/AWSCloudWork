def handler(event, context):
    message = event.get("message", "Hello, World!")
    return {
        "statusCode": 200,
        "body": message
    }   

