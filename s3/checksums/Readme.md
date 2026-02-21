## Create a new s3 bucket

'''md
aws s3 mb s3://checksums-examples-tl-2233
'''



## Create a file that will we do a checksum on

'''
echo "Hello yung bull" > myfile.txt
'''

## GEt a md5 checksum for a file

'''md
md5sum myfile.txt
d8bb4c4a4ba5bd6fc96cec546185f6c3  myfile.txt
'''

## upload our file and look at its etag

'''
aws s3 cp myfile.txt s3://checksums-examples-tl-2233
aws s3api head-object --bucket checksums-examples-tl-2233 --key myfile.txt
'''

## Lets upload a file with a different checksum

'''sh
bundle exec ruby crc
'''


'''sh
aws s3api put-object \
--bucket="checksums-examples-tl-2233" \
--key="myfilecrc32.txt" \
--body="myfile.txt" \
--checksum-algorithm="CRC32"
--checksum-crc32
'''
