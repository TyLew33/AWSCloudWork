#create bucket
'''sh

aws s3 mb s3://prefixes-fun-tl-3333
'''
#create folder "hello"
'''sh

aws s3api put-object --bucket="prefixes-fun-tl-3333" --key="hello/"
'''

#create many folders
'''sh

aws s3api put-object --bucket="prefixes-fun-tl-3333" --key="hello/"
'''

