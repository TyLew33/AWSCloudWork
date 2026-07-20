import random

def lambda_handler(event, context):

    if random.randint(1,3) == 1:
        raise Exception("Mission failed")

    return {
        "missionSuccess": True
    }

