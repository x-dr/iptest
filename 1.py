import requests

url = 'https://ngabbs.com/nuke.php?__lib=load_topic&__act=load_topic_reply_ladder'
headers = {
    'Host': 'ngabbs.com',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': '*/*',
    'Accept-Encoding': 'gzip, deflate, br',
    'Cookie': 'access_token=X95vflttl3cc8u6vb5r9d9jgjo5var0pe8eqjno2; access_uid=63364455; ngaPassportUid=guest06589a3624aa68; ngacn0comInfoCheckTime=1703518600; ngacn0comUserInfo=tryxd%09tryxd%0939%0939%09%0910%090%094%090%090%09; ngacn0comUserInfoCheck=8814f4326406a074a15894587455ca2d',
    'Connection': 'keep-alive',
    'Content-Length': '11',
    'User-Agent': 'NGA/7.3.1 (iPhone; iOS 17.2.1; Scale/3.00)',
    'Accept-Language': 'zh-Hans-CN;q=1',
    'Referer': 'https://ngabbs.com/',
    'X-User-Agent': 'NGA_skull/7.3.1(iPhone13,2;iOS 17.2.1)',
}

data = {'__output': '14'}

response = requests.post(url, headers=headers, data=data)

print(response.text)
