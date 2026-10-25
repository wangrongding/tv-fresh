# 应用下载源清单（全部为 2026-10-24/25 实测安装成功的原始 URL）

> 原则：就用下面这些 URL（含版本号，实测可用）。APK 站/网盘转载有重打包风险。
> 下载后先 `unzip -t <apk>` 校验（大文件断点续传常损坏）；装完 `pm path <包名>` 核对。

## 实测源清单（armeabi-v7a / Android 9 电视）

| 应用 | 实测下载 URL | 装后包名（核对用） |
|---|---|---|
| Projectivy Launcher 4.72 | `https://github.com/spocky/miproja1/releases/download/4.72/ProjectivyLauncher-4.72-c97-xda-release.apk` | `com.spocky.projengmenu` |
| Clash Meta (CMFA) 2.11.36 | `https://github.com/MetaCubeX/ClashMetaForAndroid/releases/download/v2.11.36/cmfa-2.11.36-meta-armeabi-v7a-release.apk` | `com.github.metacubex.clash.meta` |
| SmartTube 32.68 | `https://github.com/yuliskov/SmartTube/releases/download/32.68s/SmartTube_stable_32.68_armeabi-v7a.apk` | `org.smarttube.stable` |
| 影视仓 6.2.8 (TV 32位) | `https://github.com/youhunwl/TVAPP/raw/refs/heads/main/影视/影视仓/影视仓-TV-32位-6.2.8.apk`（路径含中文，curl 里需 URL 编码） | `com.huawei.himovceie` ⚠️正版伪装名 |
| OK影视 (FongMi) 5.8.2 | `https://github.com/FongMi/Release/releases/download/5.8.2/leanback-armeabi_v7a.apk` | `com.fongmi.android.tv` |
| ADBKeyboard | `https://github.com/senzhk/ADBKeyboard/raw/master/ADBKeyboard.apk` | `com.android.adbkeyboard` |
| FLauncher 2025.07.001（备用极简桌面） | `https://github.com/osrosal/flauncher/releases/download/v2025.07.001/flauncher-armeabi-v7a-release.apk` | `me.efesser.flauncher` |

## 版本更新

以上是"锁定版本"（保证能装）。要追新：把 URL 里的版本号换成对应仓库 Releases 最新 tag 即可，
其余路径不变。**装完必须核对包名**（尤其影视仓，包名是伪装的 `com.huawei.himovceie`，
下错包=装了别的东西）。

## 下载技巧（GitHub 大文件防掐断）

```bash
for i in $(seq 1 40); do curl -sL -C - -m 40 '<URL>' -o app.apk; \
  unzip -t app.apk >/dev/null 2>&1 && break; done
```
