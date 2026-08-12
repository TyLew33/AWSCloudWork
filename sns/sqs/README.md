#Create an SNS Topic

aws sns create-topic \
    --name OrderPlaced

TOPIC_ARN=<arn:aws:sns:us-east-2:111122223333:OrderPlaced>

#Create Inventory Queue
aws sqs create-queue \
    --queue-name InventoryQueue

#Create Email Queue
aws sqs create-queue \
    --queue-name EmailQueue

#Retrieve  Queue Urls
aws sqs get-queue-url \
    --queue-name InventoryQueue

"QueueUrl": "https://sqs.us-east-2.amazonaws.com/111122223333/InventoryQueue"

aws sqs get-queue-url \
    --queue-name EmailQueue

"QueueUrl": "https://sqs.us-east-2.amazonaws.com/111122223333/EmailQueue"

GET QUEUE ARNs:
aws sqs get-queue-attributes \
    --queue-url $INV_QUEUE_URL \
    --attribute-names QueueArn
    
    "arn:aws:sqs:us-east-2:111122223333:InventoryQueue"

aws sqs get-queue-attributes \
    --queue-url $EMAIL_QUEUE_URL \
    --attribute-names QueueArn

 "arn:aws:sqs:us-east-2:111122223333:EmailQueue"

INV_QUEUE_ARN="arn:aws:sqs:us-east-2:111122223333:InventoryQueue"
EMAIL_QUEUE_ARN="arn:aws:sqs:us-east-2:111122223333:EmailQueue"
TOPIC_ARN="arn:aws:sns:us-east-2:111122223333:OrderPlaced"
INV_QUEUE_URL="https://sqs.us-east-2.amazonaws.com/111122223333/InventoryQueue"
EMAIL_QUEUE_URL="https://sqs.us-east-2.amazonaws.com/111122223333/EmailQueue"

#POLICY TO ALLOW SNS MESSAGES TO THE QUEUES(SQS)
aws sqs set-queue-attributes \
  --queue-url $INV_QUEUE_URL \
  --cli-input-json "{\"Attributes\": {\"Policy\": $(jq -c . inventory-policy.json | jq -R .)}}"

aws sqs set-queue-attributes \
  --queue-url $EMAIL_QUEUE_URL \
  --cli-input-json "{\"Attributes\": {\"Policy\": $(jq -c . email-policy.json | jq -R .)}}"

aws sqs set-queue-attributes   --queue-url $EMAIL_QUEUE_URL   --attributes "Policy=$(cat email-policy.json)"
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#SUBSCRIBE QUEUES TO TOPIC:

aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint $INV_QUEUE_ARN

aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint $EMAIL_QUEUE_ARN

aws sns list-subscriptions
-=-=-=-=-=-=-=-
-=-=-=-=-=-=-=-=
#PUBLISH A MESSAGE:

aws sns publish \
    --topic-arn $TOPIC_ARN \
    --message '{
        "OrderID":1001,
        "Customer":"Tyree",
        "Product":"Gaming Monitor"
    }'
-=-=-=-=-=-=
=-=-=-=-=-=--=-=
#READ MESSAGES FROM SQS:
aws sqs receive-message \
    --queue-url $INV_QUEUE_URL

aws sqs receive-message \
    --queue-url $EMAIL_QUEUE_URL
=-=-=-=-=-=-=-
-=-=-=-=-=-=-=-=-
aws sqs set-queue-attributes \
  --queue-url $INV_QUEUE_URL \
  --attributes "Policy=$(jq -c . inventory-policy.json)"

aws sqs set-queue-attributes \
  --queue-url $EMAIL_QUEUE_URL \
  --attributes "Policy=$(jq -c . email-policy.json)"
-=-=-=-=-=-=-=-=-
=-=-=-=-=-=-=-=-=-
#DELETE MESSAGES
aws sqs delete-message \
    --queue-url $EMAIL_QUEUE_URL \
    --receipt-handle "AQEBNA2lz2pzibyI0gYXcguAdagXg8z6n1bT3N4ibs+FAlFSCX3Sp8lGjIhysC71l+TzQPka7Zm3XxEtRRn1h4SMRWLMmeN8b34YaBKvJH6jP4TvpJQoDEsNkbnWeSsaJM7N6i9NZjvaVfwLDsk48Fv5CPR32FpiImUwJuQ54h6ImTNgPzOvUIDb0V8LZzvDZrxnEkhYRL9jfcRaowbvsOtHDnzD/PuFAYqEEWeir28BC+d+X1Yc289P8SJ3VpiNJsYuDzQm+YJ0fMvz+hD1zbhzIx3FfFCc4xG6iyizOqRTwiMNLYp4yt/CjwoAeXB03Tvg+pFh0M4oLIYT4L/I9YWKJfIadHST1HZ3vYRHOqpZHUsS3rjCrwjSWXl1OfM2dPzsFXSgKJlbH3JJoy1Uu+d3Kw=="

aws sqs delete-message \
    --queue-url $INV_QUEUE_URL \
    --receipt-handle "AQEBQQimgsD4+i5+u9+CqVdQVIa3ShNJ28q0kLlSqMWXL8aohUXharctn9aL4SQJceWmE8c+kivXg2hBMmXOIHeqHNyErJUWy1pHUaLwlP8StB5MOVbnX1yVcl9z2KFs9yx7XL7WlgBeF790VgajA8AVKmpRLepBrMirEkOMQiTY1//oXmvTo1xPFD2qDUDP07HB9jRKmkFh14WVtr4GRxIDhGKq+bgJjY6qZVUJGoqNl4Pt4stNTOZOREj25NUpctQR+7S4S01cv7a0pLSWEuMZvr7dkGKz90hlxTyant9wnCL7YEnHLJbvYzl0DnzAJPCjn+E5ok3wCX9/j/m+YB8xtRgQc+0YAVup10Ub4Ot983jNADW1MGwFuhPCfbsQQYeWi92l2O4E6SPTO5COVHFVRw=="
=-=-=-=-=-=-=-
-=-=-=-=-=-=-
#CREATE TWO LAMBDAS FUNCTIONS

InventoryProcessor
EmailProcessor
-=-=-=-=-=-
-=-=-=-=-=-=-
#CONNECT SQS TO LAMBDA:

aws lambda get-function \
    --function-name InventoryProcessor

aws lambda create-event-source-mapping \
    --function-name InventoryProcessor \
    --event-source-arn $INV_QUEUE_ARN

aws lambda list-event-source-mappings

aws lambda get-function \
    --function-name EmailProcessor

aws lambda create-event-source-mapping \
    --function-name EmailProcessor \
    --event-source-arn $EMAIL_QUEUE_ARN

aws lambda list-event-source-
=-=-=-=-=--=
-=-=-=-=-=-=-=
#PUBLISH AGAIN

aws sns publish \
    --topic-arn $TOPIC_ARN \
    --message '{
        "OrderID":1002,
        "Customer":"Tyree",
        "Product":"Laptop"
    }'

#CHECK CLOUDWATCH LOGS

#CLEANUP
aws lambda delete-event-source-mapping \
    --uuid "56b06469-7a03-4a9f-8326-ee9b7697cd53"

aws lambda delete-event-source-mapping \
    --uuid "2b51d36d-be27-41bf-98b1-dd39101420fe"

aws lambda delete-function \
    --function-name InventoryProcessor

aws lambda delete-function \
    --function-name EmailProcessor

aws sns unsubscribe \
    --subscription-arn "arn:aws:sns:us-east-2:111122223333:OrderPlaced:a39f901a-7e11-4fce-bd1f-2383cea3ad85"

aws sns unsubscribe \
    --subscription-arn "arn:aws:sns:us-east-2:111122223333:OrderPlaced:f47b2c5e-34b2-414c-9bbd-bb7d4b41eef3"

aws sqs delete-queue \
    --queue-url $INV_QUEUE_URL

aws sqs delete-queue \
    --queue-url $EMAIL_QUEUE_URL

aws sns delete-topic \
    --topic-arn $TOPIC_ARN

aws cloudformation delete-stack \
    --stack-name inventory-lambda-stack

aws cloudformation delete-stack \
    --stack-name inventory-lambda-stack

aws cloudformation delete-stack \
    --stack-name email-lambda-stack

aws sns delete-topic \
    --topic-arn $TOPIC_ARN

aws sqs delete-queue \
    --queue-url $INV_QUEUE_URL

aws sqs delete-queue \
    --queue-url $EMAIL_QUEUE_URL

