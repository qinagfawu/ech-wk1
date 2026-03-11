#!/bin/sh
# KernelSU 模块卸载脚本

RUN_DIR="/data/adb/ech-wk"
LOG_FILE="$RUN_DIR/uninstall.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    ui_print "$1"
}

# 初始化
mkdir -p "$RUN_DIR"
touch "$LOG_FILE"
log "=== 开始卸载 ECH-Workers 模块 ==="

# 停止服务
log "停止服务进程"
pkill -9 -f "$RUN_DIR/ech-wk" 2>/dev/null
sleep 2

# 清除系统代理
log "清除全局代理设置"
settings put global http_proxy :0 2>/dev/null
settings put global global_http_proxy_host "" 2>/dev/null
settings put global global_http_proxy_port "" 2>/dev/null

# 删除运行目录
log "删除运行目录: $RUN_DIR"
rm -rf "$RUN_DIR"

# 删除模块标记
log "清理模块标记文件"
rm -f "$MODDIR/disable"
rm -f "$MODDIR/remove"

log "=== 卸载完成 ==="
ui_print "✅ ECH-Workers 模块已完全卸载！"
