// 适配 KernelSU WebUI API（兼容 v3.1.0+）
async function ksExec(cmd) {
    return new Promise((resolve, reject) => {
        // 优先使用 KSU 官方 API
        const exec = window.kernelsu?.exec || window.ksud?.exec;
        
        if (typeof exec !== 'function') {
            reject(new Error('KernelSU WebUI API 未找到，请升级 KSU 管理器'));
            return;
        }

        // 使用 su -c 提权（解决 KSU v3.1.0 权限问题）
        const fullCmd = `su -c "${cmd.replace(/"/g, '\\"').replace(/\$/g, '\\$')}"`;
        
        exec(fullCmd, (result) => {
            if (result.code === 0) {
                resolve(result.stdout || '操作成功');
            } else {
                reject(new Error(`执行失败 [代码: ${result.code}]: ${result.stderr || '无错误信息'}`));
            }
        });
    });
}

// 日志输出函数
function log(msg) {
    const logEl = document.getElementById('logContent');
    const time = new Date().toLocaleString('zh-CN');
    logEl.value = `[${time}] ${msg}\n` + logEl.value;
}

// 加载配置文件
async function loadConfig() {
    try {
        log('正在加载配置文件...');
        // 确保配置文件存在
        await ksExec('mkdir -p /data/adb/ech-wk && touch /data/adb/ech-wk/config.conf');
        
        // 读取配置
        const confContent = await ksExec('cat /data/adb/ech-wk/config.conf');
        
        // 解析配置项
        const parseConfig = (key) => {
            const regex = new RegExp(`^${key}\\s*=\\s*(.+)$`, 'm');
            const match = confContent.match(regex);
            return match ? match[1].trim() : '';
        };

        // 填充表单
        document.getElementById('server_addr').value = parseConfig('server_addr') || '';
        document.getElementById('local_port').value = parseConfig('local_listen') || '127.0.0.1:1080';
        document.getElementById('token').value = parseConfig('token') || '';
        document.getElementById('preferred_ip').value = parseConfig('preferred_ip') || '';
        document.getElementById('doh_server').value = parseConfig('doh_server') || 'dns.alidns.com/dns-query';
        document.getElementById('ech_domain').value = parseConfig('ech_domain') || 'cloudflare-ech.com';
        document.getElementById('routing').value = parseConfig('routing') || 'global';

        log('配置文件加载完成');
    } catch (e) {
        log(`加载配置失败: ${e.message}`);
        alert(`加载配置失败: ${e.message}`);
    }
}

// 保存配置文件
document.getElementById('save').addEventListener('click', async () => {
    try {
        // 获取表单值
        const server = document.getElementById('server_addr').value.trim();
        const local = document.getElementById('local_port').value.trim();
        const token = document.getElementById('token').value.trim();
        const ip = document.getElementById('preferred_ip').value.trim();
        const doh = document.getElementById('doh_server').value.trim();
        const ech = document.getElementById('ech_domain').value.trim();
        const routing = document.getElementById('routing').value.trim();

        // 校验必填项
        if (!server) {
            alert('服务端地址不能为空！');
            return;
        }

        // 构建配置内容
        const config = `server_addr = ${server}
local_listen = ${local || '127.0.0.1:1080'}
token = ${token}
preferred_ip = ${ip}
doh_server = ${doh || 'dns.alidns.com/dns-query'}
ech_domain = ${ech || 'cloudflare-ech.com'}
routing = ${routing || 'global'}`;

        // 写入配置文件
        await ksExec(`echo '${config.replace(/'/g, "\\'")}' > /data/adb/ech-wk/config.conf`);
        
        log('配置已保存');
        alert('配置保存成功！');
    } catch (e) {
        log(`保存配置失败: ${e.message}`);
        alert(`保存配置失败: ${e.message}`);
    }
});

// 启动服务
document.getElementById('start').addEventListener('click', async () => {
    try {
        log('正在启动服务...');
        await ksExec('/data/adb/modules/ech-wk/service.sh');
        log('服务启动成功');
        alert('服务启动成功！');
        await checkStatus();
    } catch (e) {
        log(`启动服务失败: ${e.message}`);
        alert(`启动服务失败: ${e.message}`);
    }
});

// 停止服务
document.getElementById('stop').addEventListener('click', async () => {
    try {
        log('正在停止服务...');
        await ksExec('pkill -9 -f /data/adb/ech-wk/ech-wk');
        log('服务已停止');
        alert('服务已停止！');
        await checkStatus();
    } catch (e) {
        log(`停止服务失败: ${e.message}`);
        alert(`停止服务失败: ${e.message}`);
    }
});

// 重启服务
document.getElementById('restart').addEventListener('click', async () => {
    try {
        log('正在重启服务...');
        await ksExec('pkill -9 -f /data/ad服务...');
        await ksExec('pkill -9 -f /data/adb/ech-wk/ech-wk');
        await new Promise(resolve => setTimeout(resolve, 1500));
        await ksExec('/data/adb/modules/ech-wk/service.sh');
        
        log('服务重启成功');
        alert('服务重启成功！');
        await checkStatus();
    } catch (e) {
        log(`重启服务失败: ${e.message}`);
        alert(`重启服务失败: ${e.message}`);
    }
});

// 查看服务状态
async function checkStatus() {
    try {
        log('正在检查服务状态...');
        const result = await ksExec('ps -A | grep /data/adb/ech-wk/ech-wk | grep -v grep');
        
        if (result) {
            log(`服务运行中:\n${result}`);
            alert('服务正在运行！');
        } else {
            log('服务已停止');
            alert('服务已停止！');
        }
    } catch (e) {
        log(`检查状态失败: ${e.message}`);
        alert(`检查状态失败: ${e.message}`);
    }
}
document.getElementById('status').addEventListener('click', checkStatus);

// 设置全局代理
document.getElementById('setGlobalProxy').addEventListener('click', async () => {
    try {
        const local = document.getElementById('local_port').value.trim() || '127.0.0.1:1080';
        const [host, port] = local.split(':');
        
        if (!host || !port) {
            alert('本地监听地址格式错误！示例：127.0.0.1:1080');
            return;
        }

        log(`设置全局代理: ${host}:${port}`);
        // 设置 Android 系统全局代理
        await ksExec(`settings put global http_proxy ${host}:${port}`);
        await ksExec(`settings put global global_http_proxy_host ${host}`);
        await ksExec(`settings put global global_http_proxy_port ${port}`);
        
        log('全局代理设置成功');
        alert(`全局代理已设置为: ${host}:${port}`);
    } catch (e) {
        log(`设置全局代理失败: ${e.message}`);
        alert(`设置全局代理失败: ${e.message}`);
    }
});

// 清除全局代理
document.getElementById('clearGlobalProxy').addEventListener('click', async () => {
    try {
        log('正在清除全局代理...');
        await ksExec('settings put global http_proxy :0');
        await ksExec('settings put global global_http_proxy_host ""');
        await ksExec('settings put global global_http_proxy_port ""');
        
        log('全局代理已清除');
        alert('全局代理已清除！');
    } catch (e) {
        log(`清除全局代理失败: ${e.message}`);
        alert(`清除全局代理失败: ${e.message}`);
    }
});

// 刷新日志
document.getElementById('refreshLog').addEventListener('click', async () => {
    try {
        log('正在刷新日志...');
        await ksExec('touch /data/adb/ech-wk/ech.log');
        const logContent = await ksExec('tail -n 50 /data/adb/ech-wk/ech.log');
        
        document.getElementById('logContent').value = logContent || '日志文件为空';
        log('日志刷新完成');
    } catch (e) {
        log(`刷新日志失败: ${e.message}`);
        document.getElementById('logContent').value = `读取日志失败: ${e.message}`;
    }
});

// 页面初始化
window.addEventListener('load', async () => {
    await loadConfig();
    await checkStatus();
    await document.getElementById('refreshLog').click();
});
