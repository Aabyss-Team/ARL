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

fixed_check_osver() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  else
    echo "无法确定发行版"
    exit 1
  fi

  case "$NAME $VERSION_ID" in
    "CentOS Linux 7")
      os_ver="CentOS Linux 7"
      ;;
    "Ubuntu 20.04")
      os_ver="Ubuntu 20.04"
      ;;
    *)
      echo "此脚本目前不支持您的系统: $NAME $VERSION"
      exit 1
      ;;
  esac
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

check_install_docker(){
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "无法确定发行版"
    exit 1
fi
if [ "$ID" = "centos" ] ; then
    if ! command -v docker &> /dev/null;then
        echo "Docker 未安装，正在进行安装..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        docker --version
        check_run_docker
      else
        echo "Docker 已经安装"
        echo "Docker版本为： $(docker --version)"  
        check_run_docker
    fi
elif [ "$ID" == "ubuntu" ]; then
    if ! command -v docker &> /dev/null;then
        echo "Docker 未安装，正在进行安装..."
        sudo apt-get update
        sudo apt-get install ca-certificates curl -y
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list
        sudo apt-get update -y
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        docker --version
        check_run_docker
      else
        echo "Docker 已经安装"
        echo "Docker版本为： $(docker --version)"  
        check_run_docker
    fi
elif [ "$ID" = "debian"]; then
    if ! command -v docker &> /dev/null;then
        echo "Docker 未安装，正在进行安装..."
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list
        sudo apt-get update -y
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        docker --version
        check_run_docker
      else
        echo "Docker 已经安装"
        echo "Docker版本为： $(docker --version)"  
        check_run_docker
    fi
else
    echo "不支持的操作系统."
    exit 1
fi
}

check_run_docker() {
status=$(systemctl is-active docker)
if [ "$status" = "active" ] ; then
      echo "Docker运行正常"   
elif [ "$status" = "inactive" ] || [ "$status" = "unknown" ] ; then
    echo "Docker 服务未运行，正在尝试启动"
    run=$(systemctl start docker)
  if [ "$?" = "0" ] ; then
        echo "Docker 启动成功"
    else
        echo "Docker 启动失败"
        exit 1
fi
else
    echo "无法确定Docker状态"
    exit 1
fi
}

uninstall_docker(){

# 检查容器是否在运行中，如果是，强制停止容器
if [ "$(docker ps -aq -f name=arl)" ]; then
    docker stop arl
    docker rm -f arl
    echo "容器 arl 停止"
fi
docker rmi moshangms/arl-test:latest
}

install_for_ubuntu() {
set -e

echo "cd /opt/"

mkdir -p /opt/
cd /opt/

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")/mongodb-org/4.4 multiverse" |  tee /etc/apt/sources.list.d/mongodb-org-4.4.list

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
yum clean all
yum makecache
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

code_install(){
fixed_check_osver
case "$os_ver" in
    "CentOS Linux 7")
        if [ "$VERSION_ID" == "7" ]; then
            echo "$os_ver"
            check_selinux
            install_for_centos
        else
            echo "暂时仅支持CentOS 7"
            exit 1
        fi
        ;;
    "Ubuntu 20.04")
        if [ "$VERSION_ID" == "20.04" ]; then
            echo ""$os_ver""
            install_for_ubuntu
        else
            echo "暂时仅支持Ubuntu 20.04"
            exit 1
        fi
        ;;
    *)
        echo "不支持的操作系统"
        exit 1
        ;;
esac
}

docker_install_menu(){
echo "请选择要安装的版本："
echo "1) arl-docker/moshangms：ARL初始版本，仅去除域名限制,5000+指纹"
echo "2) arl-docker-initial：ARL初始版本，仅去除域名限制。"
echo "3) arl-docker-all：ARL完全指纹版本，去除域名限制，全量 7165 条指纹。"
read -p "请输入选项（1-2）：" version_choice
case $version_choice in
    1)
        echo "正在拉取 Docker 镜像：arl-docker-initial..."
        docker pull moshangms/arl-test:latest
        echo "正在运行 Docker 容器..."
        docker run -d -p 5003:5003 --name arl --privileged=true moshangms/arl-test  /usr/sbin/init
        docker exec -it arl /bin/bash -c "
        rabbitmqctl add_user arl arlpassword
        rabbitmqctl set_user_tags arl administrator
        rabbitmqctl add_vhost arlv2host
        rabbitmqctl set_permissions -p arlv2host arl '.*' '.*' '.*'
        "
        ;;
    2)
        echo "正在拉取 Docker 镜像：arl-docker-initial..."
        docker pull honmashironeko/arl-docker-initial
        echo "正在运行 Docker 容器..."
        docker run -d -p 5003:5003 --name arl --privileged=true honmashironeko/arl-docker-initial /usr/sbin/init
        ;;
    3)
        echo "正在拉取 Docker 镜像：arl-docker-all..."
        docker pull honmashironeko/arl-docker-all
        echo "正在运行 Docker 容器..."
        docker run -d -p 5003:5003 --name arl --privileged=true honmashironeko/arl-docker-all /usr/sbin/init
        ;;
    *)
        echo "无效的输入，脚本将退出。"
        exit 1
        ;;
esac
}


main_menu(){
echo -e "1) 源码安装，检测系统版本中...(暂时只支持centos7 and Ubuntu20.04)"
echo -e "2) docker安装"
echo -e "3) 卸载Docker镜像"
echo -e "4) 退出脚本"
echo "---------------------------------------------------------------"
read -e -p "输入对应数字:" code_id

case $code_id in
    1)
        code_install
        ;;
    2)
        check_install_docker
        docker_install_menu
        ;;
    3)
        echo "暂时未完成"
        uninstall_docker
        ;;
    4)
        exit 1
        ;;
    *)
        echo "输入了无效的选择。请重新选择1-4的选项."
        sleep 2; main_menu
        ;;
esac
}

main_menu
