#!/system/bin/sh
# 强制使用系统sh，避免兼容问题
# 严格遵循 KernelSU 官方规范

# 基础变量（KSU 自动注入）
MODDIR=${0%/*}
RUN_DIR="/data/adb/ech-wk"
LOG_FILE="$RUN_DIR/install.log"

# 强制创建日志目录（避免目录不存在导致日志写入失败）
mkdir -p "$RUN_DIR" || {
    echo "创建运行目录失败" > /sdcard/ech-wk-debug.log
    exit 1
}
touch "$LOG_FILE" || {
    echo "创建日志文件失败" > /sdcard/ech-wk-debug.log
    exit 1
}

# 调试日志：输出所有变量
echo "=== 调试信息 ===" >> "$LOG_FILE"
echo "MODDIR: $MODDIR" >> "$LOG_FILE"
echo "RUN_DIR: $RUN_DIR" >> "$LOG_FILE"
echo "当前目录: $(pwd)" >> "$LOG_FILE"
echo "bin目录文件: $(ls -l $MODDIR/bin/ 2>&1)" >> "$LOG_FILE"
echo "=================" >> "$LOG_FILE"

# 日志函数（确保ui_print可用）
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
    # 兼容KSU的ui_print
    if [ "$(type -t ui_print)" = "function" ]; then
        ui_print "$1"
    else
        echo "$1"
    fi
}

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
        echo "不支持的架构" > /sdcard/ech-wk-debug.log
        exit 1
        ;;
esac

# 核心修复：先检查文件是否存在，再复制
BIN_SRC="$MODDIR/bin/$BIN_NAME"
log "检查二进制文件: $BIN_SRC"
if [ ! -f "$BIN_SRC" ]; then
    log "错误：二进制文件不存在！"
    echo "二进制缺失: $BIN_SRC" > /sdcard/ech-wk-debug.log
    exit 1
fi

log "复制二进制文件: $BIN_NAME"
cp -f "$BIN_SRC" "$RUN_DIR/ech-wk" || {
    log "复制二进制失败（错误码：$?）"
    echo "复制失败: $BIN_SRC → $RUN_DIR/ech-wk" > /sdcard/ech-wk-debug.log
    exit 1
}

# 复制配置文件（容错）
CONFIG_SRC="$MODDIR/config/default.conf"
CONFIG_DST="$RUN_DIR/config.conf"
if [ -f "$CONFIG_SRC" ]; then
    cp -f "$CONFIG_SRC" "$CONFIG_DST" || log "复制配置文件失败，使用默认配置"
else
    log "配置文件不存在，创建默认配置"
    echo "server_addr = ech.510524.xyz:443" > "$CONFIG_DST"
fi

# 设置权限（KSU 官方推荐，增加容错）
set_perm() {
    chown $2:$3 $1 || chmod $4 $1
}
set_perm_recursive() {
    chown -R $2:$3 $1 || chmod -R $4 $5 $1
}

set_perm "$RUN_DIR/ech-wk" 0 0 755
set_perm "$CONFIG_DST" 0 0 644
if [ -d "$MODDIR/webroot" ]; then
    set_perm_recursive "$MODDIR/webroot" 0 0 755 644
fi

# 创建日志文件
touch "$RUN_DIR/ech.log"
set_perm "$RUN_DIR/ech.log" 0 0 666

# 标记自动挂载
touch "$MODDIR/auto_mount"

log "=== 安装完成 ==="
ui_print "✅ ECH-Workers 模块安装成功！"
ui_print "🔧 配置文件: $RUN_DIR/config.conf"
ui_print "📝 日志文件: $RUN_DIR/ech.log"

# 调试：输出最终状态
echo "安装完成，二进制路径: $RUN_DIR/ech-wk" > /sdcard/ech-wk-debug.log
ls -l $RUN_DIR >> /sdcard/ech-wk-debug.log
exit 0
