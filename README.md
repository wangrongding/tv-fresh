# 小米电视去广告 + 换开源桌面完全攻略（推荐 Projectivy）

> 适用于国内版 MIUI TV（实测机型 MiTV-ASTP0 / Android 9，2026-10 成功）
> 免 root、全程可逆（所有操作都有对应还原命令）。
> 原理：ADB 调试 + `pm uninstall --user 0`（只对当前用户卸载，系统分区不动，
> `cmd package install-existing <包名>` 一条命令可还原）。
![改造后的电视桌面（Projectivy Launcher + 无广告 + CMFA/SmartTube/影视仓全家桶）](docs/desktop-home.jpg)

# 作为 Agent Skill 使用（推荐）

本仓库同时是一个可安装的 agent 技能（含 `SKILL.md` + 分任务 reference + 一键脚本），
你的 AI 助手装上后即可按流程安全地改造小米电视：

```bash
# omp 等 agent 的技能目录（其它 agent 放各自的 skills 目录即可）
git clone https://github.com/wangrongding/tv-fresh ~/.agents/skills/tv-fresh
```


## 安装后的使用示范（复制即用）

**一键全家桶**（复刻本仓库作者的完整改造效果）：

```text
我的小米电视(MIUI TV)要全面改造，按 tv-fresh 技能流程来：
1. 去广告：清掉广告/推送/统计组件，OTA 复活了要能重跑
2. 换桌面：装 Projectivy Launcher，开机直达无广告，PatchWall 禁用但保留可恢复
3. 装代理：Clash Meta(CMFA)，配置文件在 <你的配置路径/URL>，规则要国内直连、节点挂了不影响电视
4. 装 YouTube 客户端 SmartTube
5. 装影视仓 + OK影视(FongMi)，配置源用 http://肥猫.net/tv
6. 清理预装：先给我编号清单我挑，别自作主张删
电视 IP 是 192.168.1.4（不对就扫 5555 端口找）。
删除/禁用系统包前列清单等我确认，全程用可逆操作并附恢复命令。
```

> 需要遥控器配合的只有三处：电视开 ADB、授权弹窗点允许、CMFA 的 VPN 授权——其余 agent 全自动。

**单任务短句**（技能自动路由）：

```text
帮我把小米电视的开机广告去掉                    → debloat
电视换个第三方桌面，要可回滚                    → launcher-swap
电视上装个能看 YouTube 的                       → proxy-youtube
给 TVBox 配一个能自动更新的接口                 → streaming-apps
电视输入法打网址全是全角符号，帮我填个配置地址   → remote-toolbox
```


## 成果

| 项 | 结果 |
|---|---|
| 广告/推送/统计组件 | 全部移除，重启存活 |
| 开机桌面 | PatchWall（瀑布流+广告）→ **Projectivy**（开源、可自定义，实测在用） |
| HOME 键 | 始终回到 Projectivy |
| 系统设置 | 不受影响（`com.xiaomi.mitv.settings`） |

---

# Part 1 · 去广告（基础篇）

## 一、解锁开发者模式并开启 ADB

1. **设置 → 关于 → 「产品型号」**（或「版本号」）**连按遥控器"确定"5-7 次** → 提示"已开启开发者模式"
2. **设置 → 账号与安全 → ADB 调试 → 允许**（部分固件在 设置 → 通用设置 → 开发者选项）
3. 首次连接时电视会弹 RSA 授权框，遥控器选"允许"（勾选"一律允许"）

> 注意：部分固件（如 MiTV-ASTP0）**每次重启 ADB 开关会被复位**，需重新开启。
> 没有桌面时可用语音键说"打开设置"进入。

## 二、电脑端连接

```bash
adb connect <电视IP>:5555
adb devices   # 确认 device 状态（unauthorized=电视上有弹窗没点）
```

电视与电脑同一路由器即可（2.4G/5G 任意，同网段互通；不要用访客网络）。

## 三、去广告组件清单（按固件实测调整）

社区通用清单（部分固件只有其中几项）：

| 包名 | 作用 |
|---|---|
| `com.miui.systemAdSolution` | 系统广告引擎（横幅/开屏，核心） |
| `com.duokan.videodaily` | 今日头屏 |
| `com.xiaomi.mitv.tvpush`(.tvpushservice) | 消息推送弹窗 |
| `com.xiaomi.mitv.advertise` | 广告服务 |
| `com.mitv.tvad` | 电视广告 |
| `com.mitv.analysis` / `com.miui.analytics` / `com.miui.tv.analytics` | 行为统计 |
| `com.xiaomi.mistat.analyticstracker` | 埋点上报 |
| `com.xiaomi.tv.musicadapter` | 音乐卡片 |
| `com.xiaomi.mitv.tvmanager` | 电视管家 |
| `com.mitv.shoplugin` | 商城插件 |

```bash
adb shell pm uninstall --user 0 com.miui.analytics
# ...逐个执行；先 pm list packages 确认存在再删
```

**不要碰**：`com.android.packageinstaller`、`com.mitv.tvplayer` 等核心组件。
**OTA 升级可能复活组件**：重跑一遍即可。

## 四、路由器层辅助（可选）

屏蔽 `ad.xiaomi.com`、`ad1.xiaomi.com`、`ad.mi.com`。

---

# Part 2 · 换桌面（进阶篇 · 逆向实录）

## 目标

开机不进 PatchWall，直接进 **[Projectivy](https://projectivylauncher.com/)**（开源、可自定义壁纸/分组/屏保，作者在用）。方法对任意带 HOME 过滤器的桌面通用。

## 踩坑记录（排除法）

| 尝试 | 结果 |
|---|---|
| `cmd package set-home-activity` | 返回 Success 但**无效**（首选记录写入了，解析不认） |
| `pm uninstall --user 0 com.mitv.tvhome` | 黑屏 → 落在系统兜底页 FallbackHome |
| `settings put system tvservice_forground_app` | 该键与桌面解析无关 |
| 重打包目标桌面加 `android:priority="1000"` | PMS 解析后 priority 仍为 **0**（被钳制） |
| `setprop sys.fallbackhome_exit` | 无 root 不可写 |

## 逆向过程

工具链（全部本地可复现）：

1. **`vdexExtractor`**（源码编译）——这固件 `framework.jar`/`services.jar` 是 183 字节壳，真代码在：
   - `/system/framework/boot-framework.vdex`（21MB，framework）
   - `/system/framework/oat/arm/services.vdex`（10MB，system_server）
2. 提取得到 cdex（compact dex）→ baksmali 2.5.2 **不支持 cdex001** → 改用 `vdexExtractor --dis` 内置反汇编（输出 386MB 日志）
3. `jadx` 反编译普通 APK（TvSettings.apk 里的 FallbackHome 是标准 dex）

## 根因（三重夹击）

1. **AOSP 规则**：`set-home-activity` 写入的首选记录 `mAlways=false`；当其它候选的查询 match（0x108000）高于首选记录的 mMatch（0x100000）时，**首选被跳过**
2. **MIUI PMS 补丁**：第三方桌面 HOME intent-filter 的 priority 被钳制为 0（manifest 写 1000 也无效）
3. **兜底页**：`com.android.tv.settings/.system.FallbackHome`（系统特权应用）在 PatchWall 缺席时永远赢得解析；它自己的逻辑是"解析结果不是我就每 20 秒重试"——死循环黑屏

关键证据：

```
$ adb shell cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME
priority=-1000 match=0x108000 isDefault=true
com.android.tv.settings.system.FallbackHome      # PatchWall 被禁时

$ adb shell dumpsys package | grep -A6 'Preferred Activities'
  com.spocky.projengmenu/.ui.home.MainActivity
   mMatch=0x100000 mAlways=false                  # 首选在但被规则跳过
```

## 最终解法 ✅

```bash
adb connect <TV_IP>:5555
# 1. 装 Projectivy（armeabi-v7a 版）
adb install ProjectivyLauncher-*-xda-release.apk
# 2. 注册首选桌面
adb shell cmd package set-home-activity com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity
# 3. 禁用 PatchWall（保留在系统分区，可随时还原）
adb shell pm uninstall --user 0 com.mitv.tvhome
# 4. 关键一步：禁用兜底页宿主（AOSP 设置包）
adb shell pm disable-user --user 0 com.android.tv.settings
# 5. 验证：HOME 键应落在 Projectivy
adb shell input keyevent 3 && adb shell dumpsys window windows | grep mCurrentFocus
```

> 第 4 步安全性说明：国内 MIUI TV 用户看到的中文「设置」是 `com.xiaomi.mitv.settings`，
> AOSP 的 `com.android.tv.settings` 只承载兜底页（和英文设置入口），禁用不影响日常使用。

## 一键回滚

```bash
adb shell cmd package install-existing com.mitv.tvhome   # 恢复 PatchWall
adb shell pm enable com.android.tv.settings               # 恢复兜底页
adb shell pm uninstall com.spocky.projengmenu            # （可选）卸载 Projectivy
```

## 其它注意事项

- **ADB 每次重启被复位**：语音"打开设置" → 账号与安全 → ADB 调试
- 想换其它桌面（当贝等）：同样三步即可，但**当贝闭源且带内容推荐位**，介意请保持 Projectivy
- 开机广告由固件启动流程加载，删 `com.mitv.tvad`（在装的前提下）多数固件可跳过

---

# Part 3 · 电视完全体（代理 / YouTube / 影视仓 / 清理）

> 换桌面之后的进阶玩法，全部实测于 MiTV-ASTP0 / Android 9 / armeabi-v7a。

## 一、电视独立代理（Clash Meta for Android）

1. 侧载 [CMFA](https://github.com/MetaCubeX/ClashMetaForAndroid/releases)（armeabi-v7a 包）
2. 生成 mihomo 配置（节点 + `GEOIP,CN,DIRECT` 分流规则，**国内应用零影响，节点挂了关 VPN 即可**）
3. 导入技巧：配置文件放电脑上 `python3 -m http.server 18972`，
   然后 `adb reverse tcp:18972 tcp:18972`，电视端 CMFA 用深链导入：

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "clash://install-config?url=http%3A%2F%2F127.0.0.1%3A18972%2Fconfig.yaml"
```

> adb reverse 完美绕开"电脑防火墙拦局域网"的问题；若要真局域网分发记得
> `ufw allow from 192.168.1.0/24 to any port 18972 proto tcp`。

## 二、YouTube = SmartTube

[SmartTube](https://github.com/yuliskov/SmartTube)（开源、无广告、免谷歌服务、遥控器友好）。
官方 YouTube 装不了：强依赖 GMS + 设备认证 + Widevine，国产电视三座大山全撞。

## 三、影视仓 / OK影视(FongMi)：TVBox 配置的其它玩家

- 常用接口源（社区维护，时活时死，装前先 `curl -A 'okhttp/3.15' <url>` 验证返回 JSON 且含 sites）：

  | 接口 | 实测(2026-10) |
  |---|---|
  | `http://肥猫.net/tv` | ✅ 可用(40站) |
  | `http://www.饭太硬.net/tv` | ⚠️ 返回图片页,非直连配置 |
  | `http://fty.xxooo.cf/tv` / `http://我不是.摸鱼儿.top` | ❌ 失效中 |
- 影视仓：瀑布流内容墙（翻着看）；FongMi：搜索型（搜着看）；各有所长
- 饭太硬接口死因诊断样本：域名被 DNS 污染解析到 Facebook IP 段（157.240.x.x）

## 四、批量清理预装 & 权限修复

```bash
# 第三方预装直接卸载
adb shell uninstall com.cibn.tv com.newtv.cboxtv com.ktcp.video ...
# 系统包用 --user 0（可逆）
adb shell pm uninstall --user 0 com.mitv.shoplugin
# 存储权限曾被"拒绝且不再询问"(USER_FIXED)的，系统层直接改判：
adb shell pm grant com.github.tvbox.osc.tk android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.github.tvbox.osc.tk android.permission.WRITE_EXTERNAL_STORAGE
```

> 陷阱：`com.xiaoji.tvbox` 名字像 TVBox 分支，实际是街机模拟器（com.xiaoji.emu.mame），
> 别按名字想当然归类。

---

# Part 4 · 远程操控电视的正确姿势（血泪工具箱）

## 1. uiautomator dump = 坐标与文本的唯一可信来源

视觉判读会错（本人实测把"未保存"看成"已保存"），XML 不会：

```bash
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml .
# 解析出所有 text + bounds + focused，点击/校验全靠它
```

## 2. 电视输入法会把 ASCII 打成全角

`input text 'http://a.b/c'` → 字段里变成 `http：／／a。b／c`（搜狗TV输入法的"功劳"，
`fm` 甚至能变`父母`）。解法 = [ADBKeyboard](https://github.com/senzhk/ADBKeyboard)：

```bash
adb install ADBKeyboard.apk
adb shell ime set com.android.adbkeyboard/.AdbIME
adb shell am broadcast -a ADB_CLEAR_TEXT                      # 清空当前输入框
adb shell am broadcast -a ADB_INPUT_TEXT --es msg 'https://...'  # 原样注入(支持中文)
adb shell ime set com.sohu.inputmethod.sogou.tv/.SogouIME     # 用完恢复搜狗
```

## 3. 很多 TV 按钮不认 tap，只认 D-pad

影视仓的"确定"点击 7 次无效，键盘导航一次过。通用套路：

```bash
adb shell input keyevent 61   # TAB 在输入框/按钮间移动焦点
adb shell input keyevent 21/22/20/21 # 左右上下微调焦点
adb shell input keyevent 23   # 确定键激活
```

## 4. 其它碎片经验

- `pm clear` 后应用丢权限，先补授权再走配置流程
- 弹窗布局会因输入法收起而**重排**，坐标要用完就取，别缓存
- 截图 + 视觉模型判读：内容含敏感词会被审查接口 400（聚合源的成人站分类中招过）
- Herdr 用户可把视觉判读派给副 pane 的轻量模型，主流程只信 XML
