def lambda_handler(event, context):

    print("Mission completed")

    event["reviewedBy"] = "Kakashi"

    return event