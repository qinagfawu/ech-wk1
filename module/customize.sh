#!/bin/sh
# 严格遵循 KernelSU 官方规范

# 基础变量（KSU 自动注入）
MODDIR=${0%/*}
RUN_DIR="/data/adb/ech-wk"
LOG_FILE="$RUN_DIR/install.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    ui_print "$1"
}

# 初始化
mkdir -p "$RUN_DIR"
touch "$LOG_FILE"
log "=== 开始安装 ECH-Workers 模块 ==="
log "模块目录: $MODDIR"
log "运行目录: $RUN_DIR"

# 自动识别设备架构
ARCH=$(uname -m)
log "检测到设备架构: $ARCH"
case "$ARCH" in
    aarch64|arm64)
        BIN_NAME="ech-wk-arm64"
        ;;
    x86_64|amd64)
        BIN_NAME="ech-wk-x86_64"
        ;;
    *)
        log "错误：不支持的架构 $ARCH"
        abort "仅支持 arm64/x86_64 架构"
        ;;
esac

# 复制核心文件
log "复制二进制文件: $BIN_NAME"
cp -f "$MODDIR/bin/ech-wk" "$RUN_DIR/ech-wk" || {
    log "复制二进制失败"
    abort "二进制文件缺失"
}

# 复制配置文件
cp -f "$MODDIR/config/default.conf" "$RUN_DIR/config.conf" || {
    log "复制配置文件失败，使用默认配置"
    echo "server_addr = ech.510524.xyz:443" > "$RUN_DIR/config.conf"
}

# 设置权限（KSU 官方推荐）
set_perm "$RUN_DIR/ech-wk" 0 0 755
set_perm "$RUN_DIR/config.conf" 0 0 644
set_perm_recursive "$MODDIR/webroot" 0 0 755 644

# 创建日志目录
touch "$RUN_DIR/ech.log"
set_perm "$RUN_DIR/ech.log" 0 0 666

# 标记自动挂载
touch "$MODDIR/auto_mount"

log "=== 安装完成 ==="
ui_print "✅ ECH-Workers 模块安装成功！"
ui_print "🔧 配置文件: $RUN_DIR/config.conf"
ui_print "📝 日志文件: $RUN_DIR/ech.log"
