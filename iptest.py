import subprocess
from concurrent.futures import ThreadPoolExecutor


def process_ip(ip_address):
    curl_command = f'curl --resolve www.cloudflare.com:443:{ip_address} https://www.cloudflare.com:443/cdn-cgi/trace -s --connect-timeout 3 --max-time 5'
    result = subprocess.run(curl_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    result_dict = {}
    if(result.stdout):
        with open('proxyip.txt', 'a') as outfile:
                outfile.write(f'{ip_address}\n')
        pairs = result.stdout.split("\n")
        for pair in pairs:
           if '=' in pair:
               key, value = pair.split('=', 1)
               result_dict[key.strip()] = value.strip()
               
           else:
               pass
    else:
        # pass
        print(f"no proxy {ip_address}")

# 从文件中读取多个IP地址
with open('ip.txt', 'r') as file:
    ip_addresses = file.read().splitlines()

# 使用多线程处理每个IP地址
with ThreadPoolExecutor(max_workers=128) as executor:
    executor.map(process_ip, ip_addresses)
