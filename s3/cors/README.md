## WEBSITE 1

## Create a bucket 

'''sh
aws s3 mb s3://cors-fun-tl-33
'''
## Change block public access

'''sh
aws s3api put-public-access-block \
    --bucket cors-fun-tl-33 \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false"
'''
## Create a bucket policy 

'''sh
aws s3api put-bucket-policy --bucket cors-fun-tl-33 --policy file://bucket-policy.json
'''

## Turn on static website hosting

'''sh
aws s3api put-bucket-website --bucket cors-fun-tl-33 --website-configuration file://website.json
'''
## Upload our index.html file and include cross-origin resource

'''sh
aws s3 cp index.html s3://cors-fun-tl-33
'''

## Get the website endpoint for s3

http://cors-fun-tl-33.s3-website.us-east-2.amazonaws.com

## cleanup file and bucket

aws s3 rm s3://cors-fun-tl-33/index.html
aws s3 rb s3://cors-fun-tl-33




## WEBSITE 2