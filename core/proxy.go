package core

import (
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"
)

// Config 代理配置结构体（与官方参数一致）
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

	// 循环接受连接（核心逻辑占位，替换为官方ECH代码）
	fmt.Printf("代理已启动，监听: %s\n", cfg.LocalListen)
	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Printf("接受连接失败: %v\n", err)
			continue
		}
		// 处理连接（此处替换为实际ECH转发逻辑）
		go handleConnection(conn, cfg)
	}
}

// handleConnection 处理单个连接（占位）
func handleConnection(conn net.Conn, cfg Config) {
	defer conn.Close()
	fmt.Printf("新连接: %s -> %s\n", conn.RemoteAddr(), cfg.ServerAddr)
	// 此处添加ECH加密、分流、转发逻辑
	// 参考官方代码：https://github.com/byJoey/ech-wk
}
