# Gnothi · 认识自己

> γνῶθι σεαυτόν —— 德尔斐神庙箴言「认识你自己」

一款记录心理历程的 iOS + macOS 应用：把每一次心理测试、每一次心情打卡连成一条属于你的心灵轨迹。
一个人购买，可以在应用里为家人分别建立角色，每个人的记录互相独立。

## 运行

要求：**macOS 14 + Xcode 16 或更高**。支持 iOS 17+ 和 macOS 14+（同一个工程、同一个 Bundle ID，一次购买两端通用）。

👉 **想直接装来试用，看 [安装说明.md](安装说明.md)**。Mac 版只需一条命令：`./build-mac.sh`

1. 双击打开 `Gnothi.xcodeproj`
2. 选中 Gnothi target → Signing & Capabilities → 选择你的 Team（个人 Apple ID 即可）
3. 选择模拟器或真机，按 ⌘R 运行
4. 想快速看到「历程」页效果：进入「我的」→「载入示例数据」（仅 Debug 构建可见，会额外生成 2 位示例成员）
5. 测试内购：工程已附带 `Products.storekit`，并在共享 Scheme 里启用。模拟器中可以直接测试购买，不需要连接 App Store。
   如果没有生效：Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration，选 `Products.storekit`

如果 Xcode 提示工程无法打开，可以改用 XcodeGen 重新生成：

```bash
brew install xcodegen && xcodegen generate
```

## 功能

| 模块 | 内容 |
|---|---|
| 🧭 探索 | 每日心情打卡 + 4 个测试：大五人格（50 题）、PHQ-9 情绪自评、GAD-7 焦虑自评、数字推理（随机生成） |
| 📝 结果 | 雷达图 / 分级刻度、解读、建议，「此刻的我」随笔；高风险自动显示心理援助热线 |
| 📈 历程 | 按月分组的时间线；变化趋势曲线；「那时的我 vs 现在的我」雷达对比；近 30 天心情曲线 |
| 👨‍👩‍👧 成员 | 应用内创建家庭成员角色（插画头像），随时切换「为谁记录」，数据按成员隔离 |
| 🖼 报告图片 | 测试结果一键生成长图，顶部是应用品牌栏，底部有下载二维码，可保存到相册或分享；可选择隐藏名字、附带随笔 |
| 💎 Pro | StoreKit 2：年订阅（含 1 周试用）+ 终身买断。免费版 1 位成员，Pro 不限 |
| 🌱 我的 | Pro 状态、成员管理、Face ID 隐私锁、每周提醒、JSON 导出、恢复购买、一键清空、心理援助热线 |

## 技术

- 一个多平台 target：iPhone 底部 Tab 布局，Mac 侧边栏布局；平台差异集中在 `Design/Platform.swift`
- SwiftUI + **SwiftData**（本地存储，不联网）+ **Swift Charts**
- 插画全部用 SwiftUI `Shape` 矢量绘制（`Illustrations/`），没有使用图片素材，自动适配深色模式和任意尺寸
- 测试是**配置驱动**的：新增一个量表，只需在 `Tests/` 下加一个 `PsychTest` 定义
- 记录中保存原始答案和量表版本，以后改了计分规则也能重新计算历史结果

```
Gnothi/
├── App/             入口、Tab、隐私锁、通知
├── Design/          色板、字体、通用组件
├── Illustrations/   插画形状与场景
├── Models/          SwiftData 模型、测试协议、示例数据
├── Tests/           大五 / PHQ-9 / GAD-7 / 数字推理
└── Features/        探索 · 答题 · 结果 · 历程 · 我的
```

## 版权与合规

- 大五人格题目来自 IPIP（公有领域）；PHQ-9 和 GAD-7 可免费使用；数字推理题由程序原创生成
- 没有使用 MBTI 以及瑞文推理测验等有版权的测验
- 所有结果页都附有免责声明。PHQ-9 第 9 题答「有」或总分偏高时，会显示心理援助热线

## 上架前必须修改

| 位置 | 内容 |
|---|---|
| 工程 Bundle ID | `com.example.gnothi` 改成你自己的 |
| `Features/Store/Store.swift` | 两个商品 ID 改成你在 App Store Connect 里创建的 ID（`Products.storekit` 同步修改） |
| `Features/Report/ReportImage.swift` → `AppInfo` | `appStoreURL`（二维码内容）改成上架后的真实链接；`privacyURL` 改成你的隐私政策页面 |
| App Store Connect | 创建「年度订阅」（订阅组 Gnothi Pro）和「终身版」（非消耗型）两个商品，并填写价格和本地化文案 |
| 国内上架 | 需要完成 APP 备案 |

## 下一步可做

- [ ] 更多量表：依恋类型（ECR-RS）、压力知觉（PSS-10，需确认授权）、生活满意度（SWLS）
- [ ] 生活事件标注（换工作、搬家等），显示在趋势图上
- [ ] 年度心灵报告、可分享的结果卡片
- [ ] iCloud 同步（SwiftData + CloudKit）
- [ ] 桌面小组件：一键记录心情
- [ ] 英文本地化
