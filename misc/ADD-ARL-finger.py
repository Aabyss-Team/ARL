'''
Author: moshang
Blog: blog.tyslz.cn
'''

import sys
import json
import requests

requests.packages.urllib3.disable_warnings()


def login(url, username, password):
    login_url = f"{url}/api/user/login"
    login_data = json.dumps({"username": username, "password": password})
    headers = {
        "Accept": "application/json, text/plain, */*",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
        "Content-Type": "application/json; charset=UTF-8"
    }
    response = requests.post(login_url, data=login_data, headers=headers, verify=False)
    if response.status_code == 200:
        token = response.json().get('data', {}).get('token')
        if token:
            print("[+] Login Success!!")
            return token
    print("[-] Login Failure!")
    return None


def add_finger(name, rule, url, token):
    add_url = f"{url}/api/fingerprint/"
    headers = {
        "Accept": "application/json, text/plain, */*",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
        "token": token,
        "Content-Type": "application/json; charset=UTF-8"
    }
    data = {"name": name, "human_rule": rule}
    response = requests.post(add_url, data=json.dumps(data), headers=headers, verify=False)
    if response.status_code == 200:
        print(f"Add: [\033[32;1m+\033[0m] {json.dumps(data)}\nRsp: [\033[32;1m+\033[0m] {response.text}")
    else:
        print(f"[-] Failed to add fingerprint for {name}")


def upload_finger_file(file_path, url, token):
    upload_url = f"{url}/api/fingerprint/upload/"
    headers = {
        "Accept": "application/json, text/plain, */*",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
        "token": token,
        "Content-Type": "multipart/form-data"
    }
    files = {'file': ('finger.json', open(file_path, 'rb'), 'application/json')}
    response = requests.post(upload_url, files=files, headers=headers, verify=False)
    if response.status_code == 200:
        print(f"[+] File upload success: {file_path}\nRsp: [\033[32;1m+\033[0m] {response.text}")
    else:
        print(f"[-] Failed to upload file: {file_path}")


def main(url, token, file_path=None):
    if file_path:
        upload_finger_file(file_path, url, token)
    else:
        with open("./finger.json", 'r', encoding="utf-8") as f:
            load_dict = json.loads(f.read())

        body_template = "body=\"{}\""
        title_template = "title=\"{}\""
        hash_template = "icon_hash=\"{}\""

        for i in load_dict['fingerprint']:
            finger_json = i

            name = finger_json['cms']
            method = finger_json['method']
            location = finger_json['location']

            if method == "keyword":
                if "body" in location:
                    template = body_template
                elif "title" in location:
                    template = title_template
                else:
                    template = hash_template

                if len(finger_json['keyword']) > 0:
                    for rule in finger_json['keyword']:
                        formatted_rule = template.format(rule)
                        add_finger(name, formatted_rule, url, token)
                else:
                    formatted_rule = template.format(finger_json['keyword'][0])
                    add_finger(name, formatted_rule, url, token)


if __name__ == '__main__':
    if len(sys.argv) == 4 or len(sys.argv) == 5:
        login_url = sys.argv[1]
        login_name = sys.argv[2]
        login_password = sys.argv[3]
        file_path = sys.argv[4] if len(sys.argv) == 5 else None

        token = login(login_url, login_name, login_password)
        if token:
            main(login_url, token, file_path)
    else:
        print('''
    usage:
        python3 ARL-finger-ADD.py https://192.168.1.1:5003/ admin password    支持老形式如
       {
            "cms": "致远OA",
            "method": "keyword",
            "location": "rule: body",
            "keyword": [
                "/seeyon/USER-DATA/IMAGES/LOGIN/login.gif"
            ]
       }

        python3 script.py https://192.168.1.1:5003/ admin password [file_path]   支持ARL导出的指纹

        ''')
