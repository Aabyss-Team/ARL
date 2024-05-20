set -e

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
  pip3.6 --version
fi

if ! command -v nmap &> /dev/null
then
    echo "install nmap-7.93-1 ..."
    rpm -vhU https://nmap.org/dist/nmap-7.93-1.x86_64.rpm
fi


if ! command -v nuclei &> /dev/null
then
  echo "install nuclei_3.2.4 ..."
  wget https://github.com/projectdiscovery/nuclei/releases/download/v3.2.4/nuclei_3.2.4_linux_amd64.zip
  unzip nuclei_3.2.4_linux_amd64.zip && mv nuclei /usr/bin/ && rm -f nuclei_3.2.4_linux_amd64.zip
  nuclei -ut
fi


if ! command -v wih &> /dev/null
then
  echo "install wih ..."
  ## 安装 WIH
  wget https://github.com/Aabyss-Team/arl_files/blob/master/wih/wih_linux_amd64 -O /usr/bin/wih && chmod +x /usr/bin/wih
  wih --version
fi


echo "start services ..."
systemctl enable mongod
systemctl start mongod
systemctl enable rabbitmq-server
systemctl start rabbitmq-server


if [ ! -d ARL ]; then
  echo "git clone ARL proj"
  git clone https://github.com/Aabyss-Team/ARL
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
  wget https://github.com/Aabyss-Team/arl_files/blob/master/ncrack -O /usr/local/bin/ncrack
  chmod +x /usr/local/bin/ncrack
fi

mkdir -p /usr/local/share/ncrack
if [ ! -f /usr/local/share/ncrack/ncrack-services ]; then
  echo "Download ncrack-services ..."
  wget https://github.com/Aabyss-Team/arl_files/blob/master/ncrack-services -O /usr/local/share/ncrack/ncrack-services
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

systemctl status arl-web
systemctl status arl-worker
systemctl status arl-worker-github
systemctl status arl-scheduler

echo "install done"
