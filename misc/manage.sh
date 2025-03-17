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

  # 排除status命令
  if [[ "$cmd" == "status" ]]; then
    echo -e "${RED}错误：status命令请直接调用status函数${NC}"
    return 2
  fi

  for service in "${services[@]}"; do
    echo -e "\n${YELLOW}正在处理 $service...${NC}"
    systemctl "$cmd" "$service"
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}错误：$cmd ${service} 失败 (返回码 $?)${NC}"
      echo -e "尝试使用以下命令调试："
      echo -e "journalctl -u $service -n 50 --no-pager"
    else
      echo -e "${GREEN}操作成功：$service $cmd${NC}"
    fi
  done
}

# 各个功能的具体实现
function start() {
  systemctl_all start
}

function stop() {
  for service in "${services[@]}"; do
    echo -e "\n${YELLOW}正在停止 $service...${NC}"
    systemctl stop "$service"
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}错误：停止 ${service} 失败 (返回码 $?)${NC}"
    else
      echo -e "${GREEN}停止成功：$service${NC}"
    fi
  done
}

function status() {
  for service in "${services[@]}"; do
    echo -e "\n${YELLOW}------ ${BOLD}$service 状态检查 ------${NC}"
    
    # 检查服务是否存在
    if ! systemctl list-unit-files | grep -q "$service.service"; then
      echo -e "${RED}错误：服务 $service 不存在${NC}"
      continue
    fi

    # 使用 --no-pager 防止分页
    systemctl --no-pager status "$service" | head -n 20
    
    # 添加状态概要
    active_status=$(systemctl is-active "$service")
    enabled_status=$(systemctl is-enabled "$service" || echo "unknown")
    
    echo -e "\n${BLUE}状态概要：${NC}"
    echo -e "运行状态: ${active_status^}"
    echo -e "开机自启: ${enabled_status^}"
    
    # 添加间隔控制
    if [ ${#services[@]} -gt 1 ]; then
      read -r -p "查看下一个服务？[Enter继续/q退出] " input
      if [[ $input = "q" ]] || [[ $input = "Q" ]]; then
        break
      fi
    fi
  done
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
    read -r -p "按 Enter 键继续..."
  done
}

function restart() {
  stop
  start
}

function reset_password() {
  echo -e "${YELLOW}正在重置 ARL 管理员密码...${NC}"

  if ! systemctl is-active --quiet mongod; then
      echo -e "${RED}错误：MongoDB 服务未运行。请先启动 MongoDB。${NC}"
      return 1
  fi

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
  read -r -p "按 Enter 键继续..."
}

# --- 帮助/菜单 ---
function show_menu() {
    clear
    echo -e "${BLUE}${BOLD}=====================================${NC}"
    echo -e "${BLUE}${BOLD}       ARL 服务管理工具   ${NC}"
    echo -e "${BLUE}${BOLD}=====================================${NC}"
    echo -e "\n${YELLOW}请选择一个操作：${NC}"
    echo -e "  ${BOLD}1)${NC} 启动所有服务"
    echo -e "  ${BOLD}2)${NC} 停止所有服务"
    echo -e "  ${BOLD}3)${NC} 重启所有服务"
    echo -e "  ${BOLD}4)${NC} 显示服务状态"
    echo -e "  ${BOLD}5)${NC} 禁用开机自启"
    echo -e "  ${BOLD}6)${NC} 启用开机自启"
    echo -e "  ${BOLD}7)${NC} 查看服务日志"
    echo -e "  ${BOLD}8)${NC} 重置管理员密码"
    echo -e "  ${BOLD}9)${NC} 退出脚本"
    echo -e "\n请输入选项 [1-9]: "
}

# --- 主脚本逻辑 ---
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}此脚本必须以 root 用户或使用 sudo 运行${NC}"
  exit 1
fi

while true; do
  show_menu
  read -r choice

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
      echo "退出脚本。"
      exit 0
      ;;
    *)
      echo -e "${RED}无效选择。请重新输入。${NC}"
      sleep 1
      ;;
  esac
done