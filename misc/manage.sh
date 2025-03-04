#!/bin/bash

# --- 配置 ---
services=(
  "mongod"
  "rabbitmq-server"
  "arl-web"
  "arl-worker"
  "arl-worker-github"
  "arl-scheduler"
  "nginx"
)

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- 函数 ---
function systemctl_all() {
  local cmd="$1"
  if [[ -z "$cmd" ]]; then
    echo -e "${RED}错误：没有为 systemctl_all 提供命令${NC}"
    return 1
  fi

  for service in "${services[@]}"; do
    systemctl "$cmd" "$service"
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}错误：$cmd ${service} 失败${NC}"
    else
      echo -e "${GREEN}$service $cmd 成功.${NC}"
    fi
  done
}

# 各个功能的具体实现
function start() {
  systemctl_all start
}

function stop() {
  for service in "${services[@]}"; do  # 保持反向停止
    systemctl stop "$service"
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}错误：停止 ${service} 失败${NC}"
    else
      echo -e "${GREEN}$service 停止成功.${NC}"
    fi
  done
}

function status() {
  systemctl_all status
}

function disable() {
  systemctl_all disable
}

function enable() {
  systemctl_all enable
}

function showLog() {
  for service in "${services[@]}"; do
    echo -e "\n${YELLOW}------ $service 日志 ------${NC}"
    journalctl -n 15 --no-pager -u "$service"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}错误：无法检索 ${service} 的日志${NC}"
    fi
  done
}

function restart() {
  stop
  start
}

function reset_password() {
  echo -e "${YELLOW}正在重置 ARL 管理员密码...${NC}"

  # 检查 MongoDB 服务是否正在运行.  如果mongod 没有运行，则不重置密码.
  if ! systemctl is-active --quiet mongod; then
      echo -e "${RED}错误：MongoDB 服务未运行。请先启动 MongoDB。${NC}"
      return 1
  fi


  # 使用 mongo shell 执行密码重置命令.  这里使用一个Here Document
  mongo <<EOF
use arl
db.user.drop()
db.user.insert({ username: 'admin',  password: hex_md5('arlsalt!@#'+'admin123') })
exit
EOF

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}ARL 管理员密码已重置为 'admin123'。${NC}"
  else
    echo -e "${RED}密码重置失败。请检查 MongoDB 连接和脚本中的命令。${NC}"
  fi
}


# --- 帮助/菜单 ---

function show_menu() {
    clear # 清屏

    # 标题栏 (使用 -e 选项来解释转义序列)
    echo -e "${BLUE}${BOLD}=====================================${NC}"
    echo -e "${BLUE}${BOLD}       ARL 服务管理工具          ${NC}"
    echo -e "${BLUE}${BOLD}=====================================${NC}"
    echo -e ""  # 添加一个空行

    # 菜单选项 (竖排显示，使用 -e 选项)
    echo -e "${YELLOW}请选择一个操作：${NC}"
    echo -e "  ${BOLD}1)${NC} 启动所有 ARL 服务 (start)"
    echo -e "  ${BOLD}2)${NC} 停止所有 ARL 服务 (stop)"
    echo -e "  ${BOLD}3)${NC} 重启所有 ARL 服务 (restart)"
    echo -e "  ${BOLD}4)${NC} 显示所有 ARL 服务状态 (status)"
    echo -e "  ${BOLD}5)${NC} 禁用所有 ARL 服务开机自启 (disable)"
    echo -e "  ${BOLD}6)${NC} 启用所有 ARL 服务开机自启 (enable)"
    echo -e "  ${BOLD}7)${NC} 显示每个 ARL 服务的日志 (log)"
    echo -e "  ${BOLD}8)${NC} 重置 ARL 管理员密码 (reset-password)"
    echo -e "  ${BOLD}9)${NC} 显示帮助信息 (help)"
    echo -e "  ${BOLD}10)${NC} 退出 (exit)"
    echo -e "" #添加空行
    echo -n "请输入选项编号 [1-10]: "  # 更友好的提示
}

# --- 主脚本逻辑 ---

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}此脚本必须以 root 用户或使用 sudo 运行${NC}"
  exit 1
fi

while true; do
  show_menu  # 显示菜单
  read -r choice  # 读取用户输入

  case "$choice" in
    1) start ;;
    2) stop ;;
    3) restart ;;
    4) status ;;
    5) disable ;;
    6) enable ;;
    7) showLog ;;
    8) reset_password ;;
    9)
        show_menu
        continue
        ;;
    10)
      echo "退出脚本。"
      exit 0
      ;;
    *)
      echo -e "${RED}无效选择。请重新输入。${NC}"
      sleep 1
      ;;
  esac
done