# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2026-04-20

### Fixed
- 修复服务端 update_level 操作中使用未定义变量的问题
- 修复卡牌合成逻辑未实际移除和添加卡牌的bug
- 修复客户端UI中字符串拼接错误问题

### Changed
- 优化卡牌合成逻辑，合成后实际从候补区移除3张卡并添加1张高星卡
- 增强服务端参数验证

## [1.0.5] - 2026-04-20

### Added
- 服务端实现商店系统，包括商店卡牌生成、刷新和购买逻辑
- 客户端添加商店交互功能，支持卡牌购买、刷新和卡牌位管理
- 实现等待卡牌位（10个）和战场卡牌位（等于玩家等级）
- 添加卡牌放置到战场和返回候补的功能
- 1星升级2星必须是相同的卡牌，不同卡牌不可合成
- 商店刷新时可获得相同卡牌，3张相同卡牌不自动合成，必须购买后才可合成

### Changed
- 客户端 UI 重新设计，添加商店、候补区和战场区的显示
- 服务端 API 扩展，新增 get_shop、refresh_shop、place_card、return_card 等操作
- 卡牌池系统与商店系统集成

## [1.0.4] - 2026-04-20

### Added
- 服务端实现卡牌池管理系统，包括卡牌购买、卖出和合成逻辑
- 客户端添加卡牌池交互功能，支持卡牌购买、卖出和合成操作
- 实现卡牌池数量管理，根据卡牌等级和星级计算恢复数量
- 新增卡牌池状态查询 API，用于获取当前卡牌池状态

### Changed
- 客户端 UI 布局优化，添加卡牌池状态显示和操作按钮
- 服务端 API 扩展，新增 /api/cards 路由
- 实现非商店购买卡牌的跟踪，确保准确恢复卡池数量

## [1.0.3] - 2026-04-20

### Added
- 服务端实现金币系统，包括胜利金币、连胜/连败奖励和剩余金币奖励
- 客户端添加金币系统交互功能，支持金币奖励处理
- 新增回合开始 API，同时处理经验和金币的获取
- 实现连胜/连败系统，根据 streak 长度计算奖励

### Changed
- 客户端 UI 布局优化，添加金币系统状态显示和回合管理功能
- 服务端 API 扩展，新增 /api/gold 和 /api/turn/start 路由
- 战斗系统集成连胜/连败跟踪

## [1.0.2] - 2026-04-20

### Added
- 服务端实现经验系统，包括经验获取、等级提升和金币消耗逻辑
- 客户端添加经验系统交互功能，支持回合开始、购买经验和战斗奖励操作
- 实现经验系统的等级上限（10级）和经验需求计算（每级经验翻倍）

### Changed
- 客户端 UI 布局优化，添加经验系统状态显示
- 服务端 API 扩展，新增 /api/experience 路由

## [1.0.1] - 2026-04-20

### Added
- 服务端实现数据处理功能，包括数据接收、校验、计算和回传
- 客户端添加战斗处理功能，与服务端进行交互
- 添加战斗结果计算逻辑，基于单位总功率判断战斗结果

### Changed
- 更新客户端 UI，添加战斗处理区域和结果显示
- 优化服务端错误处理机制

## [1.0.0] - 2026-04-20

### Added
- 初始化项目结构
- 创建服务端程序（Node.js + Express）
- 创建客户端程序（Flutter）
- 配置 Docker 部署环境
- 编写项目文档

### Changed
- 更新 README.md，添加项目详细信息

[1.0.1]: https://gitea.raynorzhao.com:3000/Raynor/Autobattler/compare/1.0.0...1.0.1
[1.0.0]: https://gitea.raynorzhao.com:3000/Raynor/Autobattler/commits/1.0.0