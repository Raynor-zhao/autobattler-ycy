# Autobattler

当前日期：2026-04-20 初始化仓库

## 项目概述

Autobattler 是一个自动战斗游戏项目，包含服务端和客户端程序。

## 技术栈

### 服务端
- Node.js + Express
- 支持 Linux 环境部署
- Docker 容器化支持

### 客户端
- Flutter
- 支持 Windows、iOS、Android 多平台

## 目录结构

```
Autobattler/
├── server/           # 服务端程序
│   ├── src/          # 源代码
│   ├── config/       # 配置文件
│   ├── routes/       # 路由
│   ├── models/       # 数据模型
│   ├── controllers/  # 控制器
│   ├── package.json  # 依赖配置
│   ├── app.js        # 主应用
│   └── Dockerfile    # Docker 配置
├── client/           # 客户端程序
│   ├── lib/          # 源代码
│   ├── src/          # 资源文件
│   ├── assets/       # 静态资源
│   ├── test/         # 测试文件
│   └── pubspec.yaml  # 依赖配置
├── docker-compose.yml # Docker 编排配置
├── LICENSE
└── README.md
```

## 快速开始

### 服务端

1. 进入服务端目录
2. 安装依赖：`npm install`
3. 启动开发服务器：`npm run dev`
4. 生产环境部署：使用 `docker-compose up -d`

### 客户端

1. 进入客户端目录
2. 安装依赖：`flutter pub get`
3. 运行应用：`flutter run`
4. 构建应用：
   - Windows：`flutter build windows`
   - iOS：`flutter build ios`
   - Android：`flutter build apk`

## 功能特性

- 服务端提供 RESTful API
- 客户端跨平台支持
- 容器化部署方案
- 模块化代码结构

## 开发指南

### 服务端开发
- 使用 Express 框架构建 API
- 遵循 RESTful 设计原则
- 使用 Docker 进行容器化部署

### 客户端开发
- 使用 Flutter 框架构建 UI
- 遵循 Flutter 最佳实践
- 支持多平台适配

## 部署说明

### 服务端部署
1. 确保安装了 Docker 和 Docker Compose
2. 执行 `docker-compose up -d` 启动服务
3. 服务将在 3000 端口运行

### 客户端部署
1. 构建对应平台的应用
2. 分发应用安装包

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送分支
5. 开启 Pull Request

## 许可证

MIT License
