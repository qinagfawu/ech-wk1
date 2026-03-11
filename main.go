package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"
)

// ========== 原 core/proxy.go 代码内联到这里 ==========
// Config 代理配置结构体
type Config struct {
	ServerAddr  string // 服务端地址 -f
	LocalListen string // 本地监听地址 -l
	Token       string // 身份令牌 -token
	PreferredIP string // 优选IP -ip
	DoHServer   string // DoH服务器 -dns
	ECHDomain   string // ECH域名 -ech
	Routing     string // 分流模式 -routing
}

// StartProxy 启动代理服务
func StartProxy(cfg Config) error {
	// 打印配置信息
	fmt.Println("=== ECH-Workers 配置 ===")
	fmt.Printf("服务端地址: %s\n", cfg.ServerAddr)
	fmt.Printf("本地监听: %s\n", cfg.LocalListen)
	fmt.Printf("分流模式: %s\n", cfg.Routing)
	fmt.Println("========================")

	// 监听本地端口
	listener, err := net.Listen("tcp", cfg.LocalListen)
	if err != nil {
		return fmt.Errorf("监听失败: %v", err)
	}

	// 处理退出信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		fmt.Println("\n正在停止代理...")
		listener.Close()
		os.Exit(0)
	}()

	// 循环接受连接
	fmt.Printf("代理已启动，监听: %s\n", cfg.LocalListen)
	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Printf("接受连接失败: %v\n", err)
			continue
		}
		// 处理连接（占位）
		go handleConnection(conn, cfg)
	}
}

// handleConnection 处理单个连接
func handleConnection(conn net.Conn, cfg Config) {
	defer conn.Close()
	fmt.Printf("新连接: %s -> %s\n", conn.RemoteAddr(), cfg.ServerAddr)
}
// ========== core 代码内联结束 ==========

func main() {
	// 定义命令行参数
	serverAddr := flag.String("f", "", "服务端地址 (必需，格式：域名:端口)")
	localListen := flag.String("l", "127.0.0.1:1080", "本地监听地址")
	token := flag.String("token", "", "身份验证令牌")
	preferredIP := flag.String("ip", "", "服务端优选IP")
	dohServer := flag.String("dns", "dns.alidns.com/dns-query", "DoH服务器")
	echDomain := flag.String("ech", "cloudflare-ech.com", "ECH域名")
	routing := flag.String("routing", "global", "分流模式")

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
	cfg := Config{
		ServerAddr:  *serverAddr,
		LocalListen: *localListen,
		Token:       *token,
		PreferredIP: *preferredIP,
		DoHServer:   *dohServer,
		ECHDomain:   *echDomain,
		Routing:     *routing,
	}

	// 启动代理
	if err := StartProxy(cfg); err != nil {
		fmt.Printf("启动失败: %v\n", err)
		os.Exit(1)
	}
}
