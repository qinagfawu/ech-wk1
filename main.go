package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/你的用户名/ech-wk-ksu/core" // 替换为你的实际模块路径
)

func main() {
	// 定义命令行参数（与官方一致）
	serverAddr := flag.String("f", "", "服务端地址 (必需，格式：域名:端口)")
	localListen := flag.String("l", "127.0.0.1:1080", "本地监听地址 (默认：127.0.0.1:1080)")
	token := flag.String("token", "", "身份验证令牌 (可选)")
	preferredIP := flag.String("ip", "", "服务端优选IP (绕过DNS，可选)")
	dohServer := flag.String("dns", "dns.alidns.com/dns-query", "DoH服务器 (默认：alidns)")
	echDomain := flag.String("ech", "cloudflare-ech.com", "ECH查询域名 (默认：cloudflare-ech.com)")
	routing := flag.String("routing", "global", "分流模式 (global/bypass_cn/none，默认：global)")

	// 自定义帮助信息
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "使用方法: %s [选项]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "ECH-Workers 代理客户端 for KernelSU\n\n")
		fmt.Fprintf(os.Stderr, "必需参数:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\n示例:\n")
		fmt.Fprintf(os.Stderr, "  %s -f ech.510524.xyz:443 -l 0.0.0.0:1080 -routing bypass_cn\n", os.Args[0])
	}

	flag.Parse()

	// 校验必需参数
	if *serverAddr == "" {
		fmt.Println("错误：必须指定服务端地址 (-f)")
		flag.Usage()
		os.Exit(1)
	}

	// 构建配置
	cfg := core.Config{
		ServerAddr:  *serverAddr,
		LocalListen: *localListen,
		Token:       *token,
		PreferredIP: *preferredIP,
		DoHServer:   *dohServer,
		ECHDomain:   *echDomain,
		Routing:     *routing,
	}

	// 启动代理
	if err := core.StartProxy(cfg); err != nil {
		fmt.Printf("启动失败: %v\n", err)
		os.Exit(1)
	}
}
