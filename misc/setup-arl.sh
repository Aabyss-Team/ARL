#!/bin/bash
#set -e

check_selinux(){
systemctl stop firewalld &> /dev/null
systemctl disable firewalld &> /dev/null
systemctl stop iptables &> /dev/null
systemctl disable iptables &> /dev/null
ufw disable &> /dev/null
echo "防火墙已被禁用."

if sestatus | grep "SELinux status" | grep -q "enabled"; then
        WARN "SELinux 已启用。禁用 SELinux..."
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        echo "SELinux 已被禁用."
    else
        echo "SELinux 已被禁用."
fi
}

check_and_install_pyyaml() {
  required_version="5.4.1"
  installed_version=$(pip3.6 show PyYAML | grep Version | cut -d ' ' -f 2)

  if [ "$installed_version" != "$required_version" ]; then
    echo "Installing PyYAML version $required_version..."
    pip3.6 install --ignore-installed PyYAML==$required_version
  else
    echo "PyYAML version $required_version is already installed."
  fi
}
add_check_nginx_log_format(){

# 定义路径
NGINX_CONF="/etc/nginx/nginx.conf"
NEW_CONF="/opt/ARL/misc/nginx.conf"

# 检查 log_format 是否已存在
if grep -q 'log_format main' "$NGINX_CONF"; then
    echo "log_format already exists in $NGINX_CONF. No changes made."
else
    echo "log_format not found. Replacing $NGINX_CONF with new configuration..."

    # 备份当前配置文件
     cp "$NGINX_CONF" "${NGINX_CONF}.bak"
    
    # 替换配置文件
     cp "$NEW_CONF" "$NGINX_CONF"
fi

}

install_for_ubuntu() {
set -e

echo "cd /opt/"

mkdir -p /opt/
cd /opt/

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" |  tee /etc/apt/sources.list.d/mongodb-org-4.4.list

  if ! command -v curl &> /dev/null; then
    echo "install curl ..."
    apt-get install curl -y
  fi
  
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg \
   --dearmor

  echo "Updating package list..."
  apt-get update -y
   apt install software-properties-common
   add-apt-repository ppa:deadsnakes/ppa
   apt update -y && apt-get upgrade -y

  echo "Installing dependencies..."
  apt-get install -y python3.6 mongodb-org rabbitmq-server python3.6-dev g++ git nginx fontconfig \
  unzip wget gnupg lsb-release python3.6-distutils -y


  if [ ! -f /usr/local/bin/pip3.6 ]; then
    echo "install pip3.6"
    curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
    python3.6 get-pip.py
    #国内下载失败可以打开
    #python3.6 get-pip.py -i https://pypi.tuna.tsinghua.edu.cn/simple
    pip3.6 --version
    #pip3.6 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    rm -rf get-pip.py
  fi
  if ! command -v alien &> /dev/null; then
    echo "install alien..."
    apt-get install alien -y
  fi
  if ! command -v nmap &> /dev/null; then
    echo "install nmap-7.93-1 ..."
    wget https://nmap.org/dist/nmap-7.93-1.x86_64.rpm
     alien ./nmap-7.93-1.x86_64.rpm
     dpkg -i nmap_7.93-2_amd64.deb 
    rm -f nmap-7.93-1.x86_64.rpm
  fi

  if ! command -v nuclei &> /dev/null; then
    echo "install nuclei_3.3.0 ..."
    wget https://github.com/projectdiscovery/nuclei/releases/download/v3.3.0/nuclei_3.3.0_linux_amd64.zip
    unzip nuclei_3.3.0_linux_amd64.zip && mv nuclei /usr/bin/ && rm -f nuclei_3.3.0_linux_amd64.zip
    nuclei -ut
  fi

  if ! command -v wih &> /dev/null; then
    echo "install wih ..."
    wget https://raw.githubusercontent.com/msmoshang/arl_files/master/wih/wih_linux_amd64 -O /usr/bin/wih
    chmod +x /usr/bin/wih
    wih --version
  fi

  echo "start services ..."
  systemctl enable mongod
  systemctl start mongod
  systemctl enable rabbitmq-server
  systemctl start rabbitmq-server

  check_and_install_pyyaml

  if [ ! -d ARL ]; then
    echo "git clone ARL proj"
    git clone https://github.com/msmoshang/ARL
  fi

  if [ ! -d "ARL-NPoC" ]; then
    echo "git clone ARL-NPoC proj"
    git clone https://github.com/Aabyss-Team/ARL-NPoC
  fi

  cd ARL-NPoC
  echo "install poc requirements ..."
  pip3.6 install -r requirements.txt
  pip3.6 install -e .
  cd ../

  if [ ! -f /usr/local/bin/ncrack ]; then
    echo "Download ncrack ..."
    wget https://raw.githubusercontent.com/msmoshang/arl_files/master/ncrack -O /usr/local/bin/ncrack
    chmod +x /usr/local/bin/ncrack
  fi

  mkdir -p /usr/local/share/ncrack
  if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
    echo "Download ncrack-services ..."
    wget https://raw.githubusercontent.com/msmoshang/arl_files/master/ncrack-services -O /usr/local/share/ncrack/ncrack-services
  fi

  mkdir -p /data/GeoLite2
  if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
    echo "download GeoLite2-ASN.mmdb ..."
    wget https://git.io/GeoLite2-ASN.mmdb -O /data/GeoLite2/GeoLite2-ASN.mmdb
  fi

  if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
    echo "download GeoLite2-City.mmdb ..."
    wget https://git.io/GeoLite2-City.mmdb -O /data/GeoLite2/GeoLite2-City.mmdb
  fi

  cd ARL

  if [ ! -f rabbitmq_user ]; then
    echo "add rabbitmq user"
    rabbitmqctl add_user arl arlpassword
    rabbitmqctl add_vhost arlv2host
    rabbitmqctl set_user_tags arl arltag
    rabbitmqctl set_permissions -p arlv2host arl ".*" ".*" ".*"
    echo "init arl user"
    mongo 127.0.0.1:27017/arl docker/mongo-init.js
    touch rabbitmq_user
  fi

  echo "install arl requirements ..."
  pip3.6 install -r requirements.txt
  if [ ! -f app/config.yaml ]; then
    echo "create config.yaml"
    cp app/config.yaml.example app/config.yaml
  fi

  if [ ! -f /usr/bin/phantomjs ]; then
    echo "install phantomjs"
    ln -s `pwd`/app/tools/phantomjs /usr/bin/phantomjs
  fi

    add_check_nginx_log_format

  if [ ! -f /etc/nginx/sites-available/arl.conf ]; then
    echo "copy arl.conf"
    cp misc/arl.conf /etc/nginx/sites-available/arl.conf
    ln -s /etc/nginx/sites-available/arl.conf /etc/nginx/sites-enabled/
  fi

  if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    echo "download dhparam.pem"
    curl https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/ssl/certs/dhparam.pem
  fi

  echo "gen cert ..."
  chmod +x ./docker/worker/gen_crt.sh
  ./docker/worker/gen_crt.sh

  nginx -s reload

  cd /opt/ARL/

  if [ ! -f /etc/systemd/system/arl-web.service ]; then
    echo "copy arl-web.service"
    cp misc/arl-web.service /etc/systemd/system/
  fi

  if [ ! -f /etc/systemd/system/arl-worker.service ]; then
    echo "copy arl-worker.service"
    cp misc/arl-worker.service /etc/systemd/system/
  fi

  if [ ! -f /etc/systemd/system/arl-worker-github.service ]; then
    echo "copy arl-worker-github.service"
    cp misc/arl-worker-github.service /etc/systemd/system/
  fi

  if [ ! -f /etc/systemd/system/arl-scheduler.service ]; then
    echo "copy arl-scheduler.service"
    cp misc/arl-scheduler.service /etc/systemd/system/
  fi

    nginx -s reload

  # Give massdns execute permissions
  echo "massdns run"
  cd /opt/ARL/app/tools/
  chmod +x massdns

  echo "start arl services ..."
  systemctl enable arl-web
  systemctl start arl-web
  systemctl enable arl-worker
  systemctl start arl-worker
  systemctl enable arl-worker-github
  systemctl start arl-worker-github
  systemctl enable arl-scheduler
  systemctl start arl-scheduler
  systemctl enable nginx
  systemctl start nginx

    # Add fingerprint
  cd /opt/ARL/misc
  if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
    echo "ADD finger"
    python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  fi


  echo "Checking services status..."
  systemctl status mongod
  systemctl status rabbitmq-server
  systemctl status arl-web
  systemctl status arl-worker
  systemctl status arl-worker-github
  systemctl status arl-scheduler
  systemctl status nginx

  echo "install done"
}

install_for_centos() {

echo "cd /opt/"

mkdir -p /opt/
cd /opt/

tee /etc/yum.repos.d/mongodb-org-4.0.repo <<"EOF"
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF

echo "install dependencies ..."
yum install epel-release -y
yum install python36 mongodb-org-server mongodb-org-shell rabbitmq-server python36-devel gcc-c++ git \
 nginx  fontconfig wqy-microhei-fonts unzip wget -y

if [ ! -f /usr/bin/python3.6 ]; then
  echo "link python3.6"
  ln -s /usr/bin/python36 /usr/bin/python3.6
fi

if [ ! -f /usr/local/bin/pip3.6 ]; then
  echo "install  pip3.6"
  python3.6 -m ensurepip --default-pip
  python3.6 -m pip install --upgrade pip
  #python3.6 -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple
  #pip3.6 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  pip3.6 --version
fi

if ! command -v nmap &> /dev/null
then
    echo "install nmap-7.93-1 ..."
    rpm -vhU https://nmap.org/dist/nmap-7.93-1.x86_64.rpm
fi


if ! command -v nuclei &> /dev/null
then
  echo "install nuclei_3.3.0 ..."
  wget https://github.com/projectdiscovery/nuclei/releases/download/v3.3.0/nuclei_3.3.0_linux_amd64.zip
  unzip nuclei_3.3.0_linux_amd64.zip && mv nuclei /usr/bin/ && rm -f nuclei_3.3.0_linux_amd64.zip
  nuclei -ut
fi

if ! command -v wih &> /dev/null
then
  echo "install wih ..."
  ## 安装 WIH
  wget https://raw.githubusercontent.com/msmoshang/arl_files/master/wih/wih_linux_amd64 -O /usr/bin/wih && chmod +x /usr/bin/wih
  wih --version
fi


echo "start services ..."
systemctl enable mongod
systemctl start mongod
systemctl enable rabbitmq-server
systemctl start rabbitmq-server


if [ ! -d ARL ]; then
  echo "git clone ARL proj"
  git clone https://github.com/msmoshang/ARL
fi

if [ ! -d "ARL-NPoC" ]; then
  echo "git clone ARL-NPoC proj"
  git clone https://github.com/Aabyss-Team/ARL-NPoC
fi

cd ARL-NPoC
echo "install poc requirements ..."
pip3.6 install -r requirements.txt
pip3.6 install -e .
cd ../

if [ ! -f /usr/local/bin/ncrack ]; then
  echo "Download ncrack ..."
  wget https://raw.githubusercontent.com/msmoshang/arl_files/master/ncrack -O /usr/local/bin/ncrack
  chmod +x /usr/local/bin/ncrack
fi

mkdir -p /usr/local/share/ncrack
if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
  echo "Download ncrack-services ..."
  wget https://raw.githubusercontent.com/msmoshang/arl_files/master/ncrack-services -O /usr/local/share/ncrack/ncrack-services
fi

mkdir -p /data/GeoLite2
if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
  echo "download GeoLite2-ASN.mmdb ..."
  wget https://git.io/GeoLite2-ASN.mmdb -O /data/GeoLite2/GeoLite2-ASN.mmdb
fi

if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
  echo "download GeoLite2-City.mmdb ..."
  wget https://git.io/GeoLite2-City.mmdb -O /data/GeoLite2/GeoLite2-City.mmdb
fi

cd ARL

if [ ! -f rabbitmq_user ]; then
  echo "add rabbitmq user"
  rabbitmqctl add_user arl arlpassword
  rabbitmqctl add_vhost arlv2host
  rabbitmqctl set_user_tags arl arltag
  rabbitmqctl set_permissions -p arlv2host arl ".*" ".*" ".*"
  echo "init arl user"
  mongo 127.0.0.1:27017/arl docker/mongo-init.js
  touch rabbitmq_user
fi

echo "install arl requirements ..."
pip3.6 install -r requirements.txt
if [ ! -f app/config.yaml ]; then
  echo "create config.yaml"
  cp app/config.yaml.example  app/config.yaml
fi

if [ ! -f /usr/bin/phantomjs ]; then
  echo "install phantomjs"
  ln -s `pwd`/app/tools/phantomjs  /usr/bin/phantomjs
fi

if [ ! -f /etc/nginx/conf.d/arl.conf ]; then
  echo "copy arl.conf"
  cp misc/arl.conf /etc/nginx/conf.d
fi



if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
  echo "download dhparam.pem"
  curl https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/ssl/certs/dhparam.pem
fi


echo "gen cert ..."
chmod +x ./docker/worker/gen_crt.sh
./docker/worker/gen_crt.sh


cd /opt/ARL/


if [ ! -f /etc/systemd/system/arl-web.service ]; then
  echo  "copy arl-web.service"
  cp misc/arl-web.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-worker.service ]; then
  echo  "copy arl-worker.service"
  cp misc/arl-worker.service /etc/systemd/system/
fi


if [ ! -f /etc/systemd/system/arl-worker-github.service ]; then
  echo  "copy arl-worker-github.service"
  cp misc/arl-worker-github.service /etc/systemd/system/
fi

if [ ! -f /etc/systemd/system/arl-scheduler.service ]; then
  echo  "copy arl-scheduler.service"
  cp misc/arl-scheduler.service /etc/systemd/system/
fi

  nginx -s reload
 
#给massdns添加执行权限
echo "massdns run"
cd /opt/ARL/app/tools/
chmod +x massdns

echo "start arl services ..."
systemctl enable arl-web
systemctl start arl-web
systemctl enable arl-worker
systemctl start arl-worker
systemctl enable arl-worker-github
systemctl start arl-worker-github
systemctl enable arl-scheduler
systemctl start arl-scheduler
systemctl enable nginx
systemctl start nginx


    # Add fingerprint
  cd /opt/ARL/misc
  if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
    echo "ADD finger"
    python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  fi

systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

echo "install done"

}

if [ -f /etc/centos-release ]; then
  if grep  -qi 'centos:7' /etc/os-release; then
    OS="centos7"
    echo "$OS"
    check_selinux
    install_for_centos
  else
    echo "Unsupported CentOS version. Only CentOS 7 is supported."
    exit 1
  fi
elif [ -f /etc/lsb-release ] && grep -qi 'ubuntu' /etc/lsb-release; then
  if grep -qi '20.04' /etc/lsb-release; then
    OS="ubuntu 20.04"
    echo "$OS"
    install_for_ubuntu
  else
    echo "Unsupported Ubuntu version. Only Ubuntu 20.04 is supported."
    exit 1
  fi
else
  echo "Unsupported operating system."
  exit 1
fi
