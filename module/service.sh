#!/bin/sh
# KernelSU late_start 模式启动脚本

# 等待系统完全启动
sleep 20

# 基础变量
MODDIR=${0%/*}
RUN_DIR="/data/adb/ech-wk"
BIN="$RUN_DIR/ech-wk"
CONF="$RUN_DIR/config.conf"
LOG="$RUN_DIR/ech.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

# 检查前置条件
if [ ! -f "$BIN" ]; then
    log "错误：二进制文件不存在 $BIN"
    exit 1
fi
if [ ! -f "$CONF" ]; then
    log "错误：配置文件不存在 $CONF"
    exit 1
fi

# 赋予执行权限
chmod 755 "$BIN"

# 读取配置（兼容空格）
read_config() {
    grep "^$1\s*=" "$CONF" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}'
}

SERVER_ADDR=$(read_config "server_addr")
LOCAL_LISTEN=$(read_config "local_listen")
TOKEN=$(read_config "token")
PREFERRED_IP=$(read_config "preferred_ip")
DOH_SERVER=$(read_config "doh_server")
ECH_DOMAIN=$(read_config "ech_domain")
ROUTING=$(read_config "routing")

# 校验必需配置
if [ -z "$SERVER_ADDR" ]; then
    log "错误：未配置服务端地址"
    exit 1
fi

# 停止旧进程
log "停止旧进程（如果存在）"
pkill -9 -f "$BIN" 2>/dev/null
sleep 2

# 构建启动命令
CMD="$BIN -f \"$SERVER_ADDR\" -l \"$LOCAL_LISTEN\""
[ -n "$TOKEN" ] && CMD="$CMD -token \"$TOKEN\""
[ -n "$PREFERRED_IP" ] && CMD="$CMD -ip \"$PREFERRED_IP\""
[ -n "$DOH_SERVER" ] && CMD="$CMD -dns \"$DOH_SERVER\""
[ -n "$ECH_DOMAIN" ] && CMD="$CMD -ech \"$ECH_DOMAIN\""
[ -n "$ROUTING" ] && CMD="$CMD -routing \"$ROUTING\""

# 启动服务
log "启动命令: $CMD"
eval "$CMD" >> "$LOG" 2>&1 &
PID=$!

# 验证启动
sleep 3
if ps -p "$PID" >/dev/null; then
    log "服务启动成功，PID: $PID"
else
    log "服务启动失败"
    exit 1
fi

log "服务运行中，监听: $LOCAL_LISTEN"
