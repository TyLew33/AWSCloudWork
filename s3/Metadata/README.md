## Create a Bucket
 
aws s3 mb s3://metadata-fun-tl3333

## Create a file
echo "hello jupiter" > hello.txt

## Upload file with metadata
aws s3api put-object --bucket metadata-fun-tl3333 --key hello.txt --metadata Planet=jupiter

## view metadata of object
aws s3api head-object --bucket metadata-fun-tl3333

## Cleanup bucket
aws s3 rm s3://metadata-fun-tl3333/hello.txt
aws s3 rb s3://metadata-fun-tl3333

