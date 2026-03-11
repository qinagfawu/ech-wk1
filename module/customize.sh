#!/system/bin/sh
# 核心修复：强制计算真实模块目录，不依赖 KSU 注入的 MODDIR

# 手动计算模块根目录（脚本所在目录就是模块根目录）
# $0 是当前脚本路径，比如 /data/adb/modules_update/ech-wk/customize.sh
MODDIR=$(dirname "$0")
RUN_DIR="/data/adb/ech-wk"
LOG_FILE="$RUN_DIR/install.log"

# 强制创建运行目录和日志
mkdir -p "$RUN_DIR" || exit 1
touch "$LOG_FILE" || exit 1

# 日志函数
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
    [ "$(type -t ui_print)" = "function" ] && ui_print "$1" || echo "$1"
}

# 调试：输出真实模块目录（关键！）
log "=== 开始安装 ECH-Workers 模块 ==="
log "脚本路径: $0"
log "真实模块目录: $MODDIR"  # 现在会显示正确路径，比如 /data/adb/modules_update/ech-wk
log "运行目录: $RUN_DIR"

# 识别架构
ARCH=$(uname -m)
log "检测到设备架构: $ARCH"
case "$ARCH" in
    aarch64|arm64) BIN_NAME="ech-wk-arm64" ;;
    x86_64|amd64) BIN_NAME="ech-wk-x86_64" ;;
    *) log "错误：不支持的架构 $ARCH"; exit 1 ;;
esac

# 拼接正确的二进制路径（核心修复）
BIN_SRC="$MODDIR/bin/$BIN_NAME"
log "检查二进制文件: $BIN_SRC"

# 验证文件存在
if [ ! -f "$BIN_SRC" ]; then
    log "错误：二进制文件不存在！实际路径: $BIN_SRC"
    log "模块目录下的文件列表: $(ls -l $MODDIR/ 2>&1)"
    exit 1
fi

# 复制二进制文件
log "复制二进制文件: $BIN_NAME"
cp -f "$BIN_SRC" "$RUN_DIR/ech-wk" || {
    log "复制失败（错误码：$?）"
    exit 1
}

# 复制配置文件（容错）
CONFIG_SRC="$MODDIR/config/default.conf"
CONFIG_DST="$RUN_DIR/config.conf"
if [ -f "$CONFIG_SRC" ]; then
    cp -f "$CONFIG_SRC" "$CONFIG_DST" || log "复制配置文件失败，使用默认配置"
else
    log "创建默认配置文件"
    echo "server_addr = ech.510524.xyz:443" > "$CONFIG_DST"
fi

# 设置权限
chmod 755 "$RUN_DIR/ech-wk"
chmod 644 "$CONFIG_DST"
touch "$RUN_DIR/ech.log" && chmod 666 "$RUN_DIR/ech.log"
touch "$MODDIR/auto_mount"

log "=== 安装完成 ==="
ui_print "✅ ECH-Workers 模块安装成功！"
ui_print "🔧 配置文件: $RUN_DIR/config.conf"
ui_print "📝 日志文件: $RUN_DIR/ech.log"
exit 0
