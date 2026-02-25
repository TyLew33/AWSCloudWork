## Create a bucket

aws s3 mb s3://encrypt-fun-tl33

## Create file
echo "Real Ones" > real.txt
aws s3 cp real.txt s3://encrypt-fun-tl33


## Put file with encryption of SS3-KMS

aws s3api put-object \
--bucket encrypt-fun-tl33 \
--key real.txt \
--body real.txt \
--server-side-encryption "aws:kms" \
--ssekms-key-id"  "


## Put object with SSE-C generate with open ssl

aws s3api put-object \
--bucket encrypt-fun-tl33 \
--key real.txt \
--body real.txt \
--sse-customer-algorithm AES256 \
--sse-customer-key $ENCODED_KEY \ 
--sse-customer-md5