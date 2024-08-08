#!/bin/bash
#set -e
add_finger() {
  cd /opt/ARL/misc

  # 提示用户输入 admin 和 arlpass，并提供默认值
  read -p "请输入管理员用户名 (默认: admin): " admin_user
  read -p "请输入管理员密码 (默认: arlpass): " admin_pass

  # 如果用户没有输入，则使用默认值
  admin_user=${admin_user:-admin}
  admin_pass=${admin_pass:-arlpass}

  # 提示用户输入文件路径，提供默认值，并让用户可以不输入路径
  read -p "请输入指纹文件路径例：/opt/ARL/misc/finger.json（可以留空以使用默认的 finger.json）: " finger_file

  if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ]; then
    if [ -z "$finger_file" ]; then
      if [ -s /opt/ARL/misc/finger.json ]; then
        echo "添加指纹（使用默认的 finger.json）"
        python3.6 ADD-ARL-Finger.py https://127.0.0.1:5003/ "$admin_user" "$admin_pass"
      else
        echo "错误: 默认的 finger.json 文件不存在或为空。"
      fi
    else
      if [ -s "$finger_file" ]; then
        echo "添加指纹（使用指定的文件路径）"
        python3.6 ADD-ARL-Finger.py https://127.0.0.1:5003/ "$admin_user" "$admin_pass" "$finger_file"
      else
        echo "错误: 指定的指纹文件不存在或为空。"
      fi
    fi
  else
    echo "错误: ARL-Finger-ADD.py 文件不存在或为空。"
  fi
}

sources_shell(){
    echo "换源"
    echo "该脚本来自 （https://github.com/SuperManito/LinuxMirrors）"
    cd /opt
    
    if [ ! -f /opt/ChangeMirrors.sh ]; then
        echo "下载 ChangeMirrors.sh ..."
        
        # 判断 curl 和 wget 是否存在
        if command -v curl >/dev/null 2>&1; then
            curl -o /opt/ChangeMirrors.sh https://raw.gitcode.com/msmoshang/arl_files/blobs/2e431d9617f7b752747969887207a370492dc1f8/ChangeMirrors.sh
        elif command -v wget >/dev/null 2>&1; then
            wget https://raw.gitcode.com/msmoshang/arl_files/blobs/2e431d9617f7b752747969887207a370492dc1f8/ChangeMirrors.sh -O /opt/ChangeMirrors.sh
        else
            echo "错误: curl 和 wget 都不存在，请安装其中一个再运行此脚本。"
            return 1
        fi
    fi

    bash /opt/ChangeMirrors.sh
}

# 检查并安装 git 的函数
check_and_install_git() {
    echo "正在检测 git 是否安装..."

    if ! command -v git &> /dev/null; then
        echo "git 未安装，正在安装 git..."
        if [[ -f /etc/debian_version ]]; then
            # Debian/Ubuntu 系
            sudo apt-get update
            sudo apt-get install -y git
        elif [[ -f /etc/redhat-release ]]; then
            # CentOS/RHEL 系
            sudo yum install -y git
        elif [[ -f /etc/fedora-release ]]; then
            # Fedora 系
            sudo dnf install -y git
        elif [[ -f /etc/arch-release ]]; then
            # Arch Linux 系
            sudo pacman -S --noconfirm git
        else
            echo "不支持的 Linux 发行版，请手动安装 git。"
            exit 1
        fi
    else
        echo "git 已安装。"
    fi
}

#国内安装时检测一些必要命令
check_and_install_docker_tools() {
    tools=("wget" "tar")

    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            echo "$tool 未安装，正在安装 $tool..."
            if [[ -f /etc/debian_version ]]; then
                sudo apt-get update
                sudo apt-get install -y $tool
            elif [[ -f /etc/redhat-release ]]; then
                sudo yum install -y $tool
            elif [[ -f /etc/fedora-release ]]; then
                sudo dnf install -y $tool
            elif [[ -f /etc/arch-release ]]; then
                sudo pacman -S --noconfirm $tool
            else
                echo "不支持的 Linux 发行版，请手动安装 $tool。"
                exit 1
            fi
        else
            echo "$tool 已安装。"
        fi
    done
}

#检测selinux并关闭
check_selinux(){
systemctl stop firewalld &> /dev/null
systemctl disable firewalld &> /dev/null
systemctl stop iptables &> /dev/null
systemctl disable iptables &> /dev/null
ufw disable &> /dev/null
echo "防火墙已被禁用."

if sestatus | grep "SELinux status" | grep -q "enabled"; then
        echo "SELinux 已启用。禁用 SELinux..."
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
    "CentOS Stream 8" | "CentOS Linux 8")
      os_ver="CentOS Stream 8"
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

check_install_docker_CN(){
MAX_ATTEMPTS=3
attempt=0
success=false
cpu_arch=$(uname -m)
save_path="/opt/docker_tgz"
mkdir -p $save_path
docker_ver="docker-27.1.1.tgz"

case $cpu_arch in
  "arm64" | "aarch64")
    url="https://raw.gitcode.com/msmoshang/arl_files/blobs/362611e3d3d50ddea6c1c179e76364dcb8d317d5/$docker_ver"
    ;;
  "x86_64")
    url="https://raw.gitcode.com/msmoshang/arl_files/blobs/2062dee5a2b85f820fc7e56a8e238525a3b06ea3/$docker_ver"
    ;;
  *)
    echo "不支持的CPU架构: $cpu_arch"
    exit 1
    ;;
esac

check_and_install_docker_tools

if ! command -v docker &> /dev/null; then
  while [ $attempt -lt $MAX_ATTEMPTS ]; do
    attempt=$((attempt + 1))
    echo "Docker 未安装，正在进行安装..."
    wget -P "$save_path" "$url"
    if [ $? -eq 0 ]; then
        success=true
        break
    fi
    echo "Docker 安装失败，正在尝试重新下载 (尝试次数: $attempt)"
  done

  if $success; then
     tar -xzf $save_path/$docker_ver -C $save_path
     \cp $save_path/docker/* /usr/bin/
     rm -rf $save_path
     echo "Docker 安装成功，版本为：$(docker --version)"
     
     cat > /usr/lib/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target
[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP 
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl restart docker
    check_run_docker
    systemctl enable docker
  else
    echo "Docker 安装失败，请尝试手动安装"
    exit 1
  fi
else 
    echo "Docker 已安装，安装版本为：$(docker --version)"
    systemctl restart docker
    check_run_docker
fi
}

check_install_docker-compose_CN(){
echo "安装Docker Compose"
MAX_ATTEMPTS=3
attempt=0
cpu_arch=$(uname -m)
success=false
save_path="/usr/local/bin"

case $cpu_arch in
  "arm64" | "aarch64")
    url="https://raw.gitcode.com/msmoshang/arl_files/blobs/91c90fdb2223045dcac604736d5428d1ae40d018/docker-compose-linux-aarch64"
    ;;
  "x86_64")
    url="https://raw.gitcode.com/msmoshang/arl_files/blobs/72eb38523db2f2c0b9645b2597d3ed9c9e778c7e/docker-compose-linux-x86_64"
    ;;
  *)
    echo "不支持的CPU架构: $cpu_arch"
    exit 1
    ;;
esac


chmod +x $save_path/docker-compose &>/dev/null
if ! command -v docker-compose &> /dev/null || [ -z "$(docker-compose --version)" ]; then
    echo "Docker Compose 未安装或安装不完整，正在进行安装..."    
    while [ $attempt -lt $MAX_ATTEMPTS ]; do
        attempt=$((attempt + 1))
        wget --continue -q $url -O $save_path/docker-compose
        if [ $? -eq 0 ]; then
            chmod +x $save_path/docker-compose
            version_check=$(docker-compose --version)
            if [ -n "$version_check" ]; then
                success=true
                chmod +x $save_path/docker-compose
                break
            else
                echo "Docker Compose 下载的文件不完整，正在尝试重新下载 (尝试次数: $attempt)"
                rm -f $save_path/docker-compose
            fi
        fi

        echo "Docker Compose 下载失败，正在尝试重新下载 (尝试次数: $attempt)"
    done

    if $success; then
        echo "Docker Compose 安装成功，版本为：$(docker-compose --version)"
    else
        echo "Docker Compose 下载失败，请尝试手动安装docker-compose"
        exit 1
    fi
else
    chmod +x $save_path/docker-compose
    echo "Docker Compose 安装成功，版本为：$(docker-compose --version)"
fi
}

check_install_docker-compose() {
echo "安装docker compose"

TAG=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
url="https://github.com/docker/compose/releases/download/$TAG/docker-compose-$(uname -s)-$(uname -m)"
MAX_ATTEMPTS=3
attempt=0
success=false
save_path="/usr/local/bin"

chmod +x $save_path/docker-compose &>/dev/null
if ! command -v docker-compose &> /dev/null || [ -z "$(docker-compose --version)" ]; then
    echo "Docker Compose 未安装或安装不完整，正在进行安装..."    
    while [ $attempt -lt $MAX_ATTEMPTS ]; do
        attempt=$((attempt + 1))
        wget --continue -q $url -O $save_path/docker-compose
        if [ $? -eq 0 ]; then
            chmod +x $save_path/docker-compose
            version_check=$(docker-compose --version)
            if [ -n "$version_check" ]; then
                success=true
                chmod +x $save_path/docker-compose
                break
            else
                echo "Docker Compose 下载的文件不完整，正在尝试重新下载 (尝试次数: $attempt)"
                rm -f $save_path/docker-compose
            fi
        fi

        echo "Docker Compose 下载失败，正在尝试重新下载 (尝试次数: $attempt)"
    done

    if $success; then
        echo "Docker Compose 安装成功，版本为：$(docker-compose --version)"
    else
        echo "Docker Compose 下载失败，请尝试手动安装docker-compose"
        exit 1
    fi
else
    chmod +x $save_path/docker-compose
    echo "Docker Compose 已经安装，版本为：$(docker-compose --version)"
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

#国内Centos7安装
install_for_centos_CN() {

echo "cd /opt/"

mkdir -p /opt/
cd /opt/

tee /etc/yum.repos.d/mongodb-org-4.0.repo <<"EOF" 1>/dev/null
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF

echo "install dependencies ..."
yum install epel-release -y 1>/dev/null
yum clean all 1>/dev/null
yum makecache 1>/dev/null
yum install python36 mongodb-org-server mongodb-org-shell rabbitmq-server python36-devel gcc-c++ git \
 nginx  fontconfig wqy-microhei-fonts unzip wget -y 1>/dev/null

if [ ! -f /usr/bin/python3.6 ]; then
  echo "link python3.6"
  ln -s /usr/bin/python36 /usr/bin/python3.6
fi

if [ ! -f /usr/local/bin/pip3.6 ]; then
  echo "install  pip3.6"
  python3.6 -m ensurepip --default-pip
  python3.6 -m pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple
  pip3.6 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
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
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/fb1f668e8733eea99153aed322db879cfa240d84/nuclei_3.3.0_linux_amd64.zip
  unzip nuclei_3.3.0_linux_amd64.zip && mv nuclei /usr/bin/ && rm -f nuclei_3.3.0_linux_amd64.zip
  nuclei -ut
fi

if ! command -v wih &> /dev/null
then
  echo "install wih ..."
  ## 安装 WIH
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/ca1f54e9ea46855fea153cb76fb854e870d3bd8a/wih_linux_amd64 -O /usr/bin/wih && chmod +x /usr/bin/wih
  wih --version
fi


echo "start services ..."
systemctl enable mongod
systemctl start mongod
systemctl enable rabbitmq-server
systemctl start rabbitmq-server


if [ ! -d ARL ]; then
  echo "git clone ARL proj"
  git clone https://gitee.com/Aabyss-Team/ARL
fi

if [ ! -d "ARL-NPoC" ]; then
  echo "git clone ARL-NPoC proj"
  git clone https://gitee.com/ms1125/ARL-NPoC
fi

cd ARL-NPoC
echo "install poc requirements ..."
pip3.6 install -r requirements.txt
pip3.6 install -e .
cd /opt/

if [ ! -f /usr/local/bin/ncrack ]; then
  echo "Download ncrack ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/9a6b0fbf8b9e377e1ed234347a3097c5c28ebd8d/ncrack -O /usr/local/bin/ncrack
  chmod +x /usr/local/bin/ncrack
fi

mkdir -p /usr/local/share/ncrack
if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
  echo "Download ncrack-services ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/cfd6e29efb2ab97e84f346206fe5d9719f242a8f/ncrack-services -O /usr/local/share/ncrack/ncrack-services
fi

mkdir -p /data/GeoLite2
if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
  echo "download GeoLite2-ASN.mmdb ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/0737adc55cb78b6b06973d55d6012d66bcc1d219/GeoLite2-ASN.mmdb -O /data/GeoLite2/GeoLite2-ASN.mmdb
fi

if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
  echo "download GeoLite2-City.mmdb ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/cb513cf65f6b6611bd3aa6b6ca61ccbed2858ec2/GeoLite2-City.mmdb -O /data/GeoLite2/GeoLite2-City.mmdb
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


  #   # Add fingerprint
  # cd /opt/ARL/misc
  # if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
  #   echo "ADD finger"
  #   python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  # fi

#重新启动特定服务防止添加指纹断开连接造成启动失败
echo "restart services"
systemctl start mongod
systemctl start rabbitmq-server
systemctl start arl-web
systemctl start arl-worker
systemctl start arl-worker-github
systemctl start arl-scheduler


echo "status services"
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

echo "install done"

}

#国内centos8安装
install_for_centos8_CN(){
echo "cd /opt/"

mkdir -p /opt/
cd /opt/

tee /etc/yum.repos.d/mongodb-org-4.0.repo <<"EOF" 1>/dev/null
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF

#写入rabbitmq安装源
tee /etc/yum.repos.d/rabbitmq.repo <<"EOF" 1>/dev/null
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/8/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_erlang-source]
name=rabbitmq_erlang-source
baseurl=https://packagecloud.io/rabbitmq/erlang/el/8/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/8/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server-source]
name=rabbitmq_rabbitmq-server-source
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/8/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF

echo "install dependencies ..."
yum install epel-release -y 1>/dev/null
yum clean all 1>/dev/null
yum makecache 1>/dev/null
yum install python36 mongodb-org-server mongodb-org-shell rabbitmq-server python36-devel gcc-c++ git \
 nginx  fontconfig wqy-microhei-fonts unzip wget -y 1>/dev/null


if [ ! -f /usr/bin/python3.6 ]; then
  echo "link python3.6"
  ln -s /usr/bin/python36 /usr/bin/python3.6
fi

if [ ! -f /usr/local/bin/pip3.6 ]; then
  echo "install  pip3.6"
  python3.6 -m ensurepip --default-pip
  python3.6 -m pip install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple
  pip3.6 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
  pip3.6 --version
fi

if ! command -v nmap &> /dev/null
then
    echo "install nmap-7.92-1 ..."
    yum install nmap -y
fi

if ! command -v nuclei &> /dev/null
then
  echo "install nuclei_3.3.0 ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/fb1f668e8733eea99153aed322db879cfa240d84/nuclei_3.3.0_linux_amd64.zip
  unzip nuclei_3.3.0_linux_amd64.zip && mv nuclei /usr/bin/ && rm -f nuclei_3.3.0_linux_amd64.zip
  nuclei -ut
fi

if ! command -v wih &> /dev/null
then
  echo "install wih ..."
  ## 安装 WIH
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/ca1f54e9ea46855fea153cb76fb854e870d3bd8a/wih_linux_amd64 -O /usr/bin/wih && chmod +x /usr/bin/wih
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
  git clone https://gitee.com/Aabyss-Team/ARL
fi

if [ ! -d "ARL-NPoC" ]; then
  echo "git clone ARL-NPoC proj"
  git clone https://gitee.com/ms1125/ARL-NPoC
fi

cd ARL-NPoC
echo "install poc requirements ..."
pip3.6 install -r requirements.txt
pip3.6 install -e .
cd /opt/

if [ ! -f /usr/local/bin/ncrack ]; then
  echo "Download ncrack ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/9a6b0fbf8b9e377e1ed234347a3097c5c28ebd8d/ncrack -O /usr/local/bin/ncrack
  chmod +x /usr/local/bin/ncrack
fi

mkdir -p /usr/local/share/ncrack
if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
  echo "Download ncrack-services ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/cfd6e29efb2ab97e84f346206fe5d9719f242a8f/ncrack-services -O /usr/local/share/ncrack/ncrack-services
fi

mkdir -p /data/GeoLite2
if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
  echo "download GeoLite2-ASN.mmdb ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/0737adc55cb78b6b06973d55d6012d66bcc1d219/GeoLite2-ASN.mmdb -O /data/GeoLite2/GeoLite2-ASN.mmdb
fi

if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
  echo "download GeoLite2-City.mmdb ..."
  wget https://raw.gitcode.com/msmoshang/arl_files/blobs/cb513cf65f6b6611bd3aa6b6ca61ccbed2858ec2/GeoLite2-City.mmdb -O /data/GeoLite2/GeoLite2-City.mmdb
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


  #   # Add fingerprint
  # cd /opt/ARL/misc
  # if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
  #   echo "ADD finger"
  #   python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  # fi

#重新启动特定服务防止添加指纹断开连接造成启动失败
echo "restart services"
systemctl start mongod
systemctl start rabbitmq-server
systemctl start arl-web
systemctl start arl-worker
systemctl start arl-worker-github
systemctl start arl-scheduler


echo "status services"
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

echo "install done"

}

#国内Ubuntu20.04安装
install_for_ubuntu_CN() {
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
    curl https://raw.gitcode.com/msmoshang/arl_files/blobs/fd48c7fdef802d8bb86ace74134c553f0317258c/get-pip.py -o get-pip.py
    #国内下载失败可以打开
    python3.6 get-pip.py -i https://mirrors.aliyun.com/pypi/simple/
    pip3.6 --version
    pip3.6 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
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
    wget https://raw.gitcode.com/msmoshang/arl_files/blobs/fb1f668e8733eea99153aed322db879cfa240d84/nuclei_3.3.0_linux_amd64.zip
    unzip nuclei_3.3.0_linux_amd64.zip && mv nuclei /usr/bin/ && rm -f nuclei_3.3.0_linux_amd64.zip
    nuclei -ut
  fi

  if ! command -v wih &> /dev/null; then
    echo "install wih ..."
    wget https://raw.gitcode.com/msmoshang/arl_files/blobs/ca1f54e9ea46855fea153cb76fb854e870d3bd8a/wih_linux_amd64 -O /usr/bin/wih
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
    git clone https://gitee.com/Aabyss-Team/ARL
  fi

  if [ ! -d "ARL-NPoC" ]; then
    echo "git clone ARL-NPoC proj"
    git clone https://gitee.com/ms1125/ARL-NPoC
  fi

  cd ARL-NPoC
  echo "install poc requirements ..."
  pip3.6 install -r requirements.txt
  pip3.6 install -e .
  cd ../

  if [ ! -f /usr/local/bin/ncrack ]; then
    echo "Download ncrack ..."
    wget https://raw.gitcode.com/msmoshang/arl_files/blobs/9a6b0fbf8b9e377e1ed234347a3097c5c28ebd8d/ncrack -O /usr/local/bin/ncrack
    chmod +x /usr/local/bin/ncrack
  fi

  mkdir -p /usr/local/share/ncrack
  if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
    echo "Download ncrack-services ..."
    wget https://raw.gitcode.com/msmoshang/arl_files/blobs/cfd6e29efb2ab97e84f346206fe5d9719f242a8f/ncrack-services -O /usr/local/share/ncrack/ncrack-services
  fi

  mkdir -p /data/GeoLite2
  if [ ! -f /data/GeoLite2/GeoLite2-ASN.mmdb ]; then
    echo "download GeoLite2-ASN.mmdb ..."
    wget https://raw.gitcode.com/msmoshang/arl_files/blobs/0737adc55cb78b6b06973d55d6012d66bcc1d219/GeoLite2-ASN.mmdb -O /data/GeoLite2/GeoLite2-ASN.mmdb
  fi

  if [ ! -f /data/GeoLite2/GeoLite2-City.mmdb ]; then
    echo "download GeoLite2-City.mmdb ..."
    wget https://raw.gitcode.com/msmoshang/arl_files/blobs/cb513cf65f6b6611bd3aa6b6ca61ccbed2858ec2/GeoLite2-City.mmdb -O /data/GeoLite2/GeoLite2-City.mmdb
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

  #   # Add fingerprint
  # cd /opt/ARL/misc
  # if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
  #   echo "ADD finger"
  #   python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  # fi


#重新启动特定服务防止添加指纹断开连接造成启动失败
echo "restart services"
systemctl start mongod
systemctl start rabbitmq-server
systemctl start arl-web
systemctl start arl-worker
systemctl start arl-worker-github
systemctl start arl-scheduler


echo "status services"
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

  echo "install done"
}


#国外Ubuntu20.04安装
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

  #   # Add fingerprint
  # cd /opt/ARL/misc
  # if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
  #   echo "ADD finger"
  #   python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  # fi


#重新启动特定服务防止添加指纹断开连接造成启动失败
echo "restart services"
systemctl start mongod
systemctl start rabbitmq-server
systemctl start arl-web
systemctl start arl-worker
systemctl start arl-worker-github
systemctl start arl-scheduler


echo "status services"
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

  echo "install done"
}


#国外centos7安装
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


  #   # Add fingerprint
  # cd /opt/ARL/misc
  # if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
  #   echo "ADD finger"
  #   python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  # fi

#重新启动特定服务防止添加指纹断开连接造成启动失败
echo "restart services"
systemctl start mongod
systemctl start rabbitmq-server
systemctl start arl-web
systemctl start arl-worker
systemctl start arl-worker-github
systemctl start arl-scheduler


echo "status services"
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

echo "install done"

}


#国外centos8安装
install_for_centos8(){
echo "cd /opt/"

mkdir -p /opt/
cd /opt/

#写入mongodb安装源
tee /etc/yum.repos.d/mongodb-org-4.0.repo <<"EOF" 1>/dev/null
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF

#写入rabbitmq安装源
tee /etc/yum.repos.d/rabbitmq.repo <<"EOF" 1>/dev/null
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/8/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_erlang-source]
name=rabbitmq_erlang-source
baseurl=https://packagecloud.io/rabbitmq/erlang/el/8/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/8/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[rabbitmq_rabbitmq-server-source]
name=rabbitmq_rabbitmq-server-source
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/8/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF

echo "install dependencies ..."
yum install epel-release -y 1>/dev/null
yum clean all 1>/dev/null
yum makecache 1>/dev/null
yum install python36 mongodb-org-server mongodb-org-shell rabbitmq-server python36-devel gcc-c++ git \
 nginx  fontconfig wqy-microhei-fonts unzip wget -y 1>/dev/null
 
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
    echo "install nmap-7.92-1 ..."
    yum install nmap -y
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
cd /opt/

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


  #   # Add fingerprint
  # cd /opt/ARL/misc
  # if [ -s /opt/ARL/misc/ARL-Finger-ADD.py ] && [ -s /opt/ARL/misc/finger.json ]; then
  #   echo "ADD finger"
  #   python3.6 ARL-Finger-ADD.py https://127.0.0.1:5003/ admin arlpass
  # fi

#重新启动特定服务防止添加指纹断开连接造成启动失败
echo "restart services"
systemctl start mongod
systemctl start rabbitmq-server
systemctl start arl-web
systemctl start arl-worker
systemctl start arl-worker-github
systemctl start arl-scheduler


echo "status services"
systemctl status mongod
systemctl status rabbitmq-server
systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

echo "install done"

}

code_install(){
fixed_check_osver
case "$os_ver" in
    "CentOS Linux 7"|"CentOS Stream 8")
        if [ "$VERSION_ID" == "7" ]; then
            echo "$os_ver"
            check_selinux
            install_for_centos
        elif [ "$VERSION_ID" == "8" ]; then
            echo "$os_ver"
            check_selinux
            install_for_centos8
        else
            echo "暂时仅支持CentOS 7 and CentOS Stream 8"
            xit 1
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

code_install_CN(){
fixed_check_osver
case "$os_ver" in
    "CentOS Linux 7"|"CentOS Stream 8")
        if [ "$VERSION_ID" == "7" ]; then
            echo "$os_ver"
            check_selinux
            install_for_centos
        elif [ "$VERSION_ID" == "8" ]; then
            echo "$os_ver"
            check_selinux
            install_for_centos8_CN
        else
            echo "暂时仅支持CentOS 7 and CentOS Stream 8"
            xit 1
        fi
        ;;
    "Ubuntu 20.04")
        if [ "$VERSION_ID" == "20.04" ]; then
            echo ""$os_ver""
            install_for_ubuntu_CN
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

docker_mirrors_CN(){
mkdir -p /etc/docker
echo "{
  \"registry-mirrors\": [\"https://hub.msqh.net\"]
}" > /etc/docker/daemon.json
systemctl restart docker
check_run_docker
}

docker_install_menu(){
echo "请选择要安装的版本："
echo "1) arl-docker-all：honmashironeko docker(暂时支持国外安装)"
read -p "请输入选项（1）：" version_choice
case $version_choice in
    1)
        check_and_install_git
        echo "正在 Git ARL-docker"
        cd /opt/
        if [ ! -d ARL-docker ]; then
        echo "git clone ARL proj"
        git clone https://github.com/honmashironeko/ARL-docker
        fi
        cd /opt/ARL-docker
        chmod +x setup_docker.sh
        bash setup_docker.sh
        ;;
    # 2)
    #     echo "正在拉取 Docker 镜像：arl-docker-initial..."
    #     docker pull honmashironeko/arl-docker-initial
    #     echo "正在运行 Docker 容器..."
    #     docker run -d -p 5003:5003 --name arl --privileged=true honmashironeko/arl-docker-initial /usr/sbin/init
    #     ;;
    # 3)
    #     echo "正在拉取 Docker 镜像：arl-docker-all..."
    #     docker pull honmashironeko/arl-docker-all
    #     echo "正在运行 Docker 容器..."
    #     docker run -d -p 5003:5003 --name arl --privileged=true honmashironeko/arl-docker-all /usr/sbin/init
    #     ;;
    *)
        echo "无效的输入，脚本将退出。"
        exit 1
        ;;
esac
}


main_menu(){
echo -e "第一次安装建议进行换源参数在继续安装"  
echo -e "1) 换源 (脚本来自于 https://github.com/SuperManito/LinuxMirrors)"  
echo -e "2) 源码安装(暂时只支持centos 7 8 and Ubuntu20.04 支持国内外安装)"
echo -e "3) docker安装 （支持国内外安装，但可能存在抽风问题）"
echo -e "4) 卸载Docker镜像"
echo -e "5) 添加指纹（默认为7k+）只限于源码安装添加指纹"
echo -e "6) 退出脚本"
echo "---------------------------------------------------------------"
read -e -p "输入对应数字:" code_id

case $code_id in
    1)
      while true; do
          echo "换源"
          read -e -p "$(echo "换源选择1 不换源选择2 > ")" code_deploy
          case "$code_deploy" in
              1)
                  sources_shell
                  break;;
              2)
                  echo "不换源的话一定要确保自己的源可用"
                  break;;
              * )
                  echo "换源选择1 不换源选择2";;
          esac
      done
      main_menu
      ;;
    2)
      while true; do
          echo "源码安装"
          read -e -p "$(echo "安装环境确认 [国外环境输1  国内环境输2] > ")" code_deploy
          case "$code_deploy" in
              1)
                  code_install
                  break;;
              2)
                  code_install_CN
                  break;;
              * )
                  echo "请输入 1 表示国外 或者 2 表示国内";;
          esac
      done
      ;;
    3)
      while true; do
          echo "Docker安装"
          read -e -p "$(echo "安装环境确认 [国外环境输1  国内环境输2] > ")" code_deploy
          case "$code_deploy" in
              1)
                  check_install_docker
                  check_install_docker-compose
                  docker_install_menu
                  break;;
              2)
                  check_install_docker_CN
                  check_install_docker-compose_CN
                  docker_mirrors_CN
                  docker_install_menu
                  break;;
              * )
                  echo "请输入 1 表示国外 或者 2 表示国内";;
          esac
      done
      ;;      
    4)
        echo "暂时未完成"
        uninstall_docker
        ;;
    5)
        add_finger
        ;;
    6)
        exit 1
        ;;
    *)
        echo "输入了无效的选择。请重新选择1-4的选项."
        sleep 2; main_menu
        ;;
esac
}
main_menu
