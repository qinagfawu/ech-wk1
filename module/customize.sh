#!/system/bin/sh
# 核心：强制使用绝对路径，兼容所有解压层级

# 手动指定模块解压后的真实绝对路径（KSU默认解压到这里）
MODDIR="/data/adb/modules_update/ech-wk"
RUN_DIR="/data/adb/ech-wk"
LOG_FILE="$RUN_DIR/install.log"

# 初始化
mkdir -p "$RUN_DIR"
touch "$LOG_FILE"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    ui_print "$1"
}

log "=== 开始安装 ECH-Workers 模块 ==="
log "强制模块目录: $MODDIR"
log "运行目录: $RUN_DIR"

# 识别架构
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

# 强制绝对路径（核心！）
BIN_SRC="$MODDIR/bin/$BIN_NAME"
log "检查二进制文件: $BIN_SRC"

# 先验证文件是否存在
if [ ! -f "$BIN_SRC" ]; then
    log "错误：二进制文件不存在！"
    log "模块目录下的文件: $(ls -l $MODDIR/ 2>&1)"
    abort "二进制文件缺失"
fi

# 复制二进制
log "复制二进制文件: $BIN_NAME"
cp -f "$BIN_SRC" "$RUN_DIR/ech-wk" || {
    log "复制二进制失败"
    abort "复制失败"
}

# 复制配置文件（容错）
CONFIG_SRC="$MODDIR/config/default.conf"
CONFIG_DST="$RUN_DIR/config.conf"
if [ -f "$CONFIG_SRC" ]; then
    cp -f "$CONFIG_SRC" "$CONFIG_DST" || log "复制配置文件失败，使用默认配置"
else
    log "复制配置文件失败，使用默认配置"
    echo "server_addr = ech.510524.xyz:443" > "$RUN_DIR/config.conf"
fi

# 设置权限
set_perm "$RUN_DIR/ech-wk" 0 0 755
set_perm "$RUN_DIR/config.conf" 0 0 644
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
