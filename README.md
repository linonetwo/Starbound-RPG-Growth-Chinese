# Starbound-RPG-Growth-Chinese

[Starbound Mod RPG Growth](https://github.com/IcyVines/Starbound-RPG-Growth) 汉化

## Contribute

如果你在游戏过程中发现不当的翻译，或者有未翻译的内容，可以在 issue 里提出，或顺手作出修改：

直接点击 Create New File，然后在文件名那边黏贴 `translation/translationaffinities/affinityDescriptions.config.patch` 这样的文件名，就会自动创建文件夹和文件了。

![create new file](doc/images/createnewfile.png)

这样修改的结果是放在你自己的仓库里的（防止用户恶意修改别人的仓库），然后你可以在我这边发起 Pull Request，让我去拉取你修改的结果，如果不懂操作上网搜搜视频吧！

[Contributors](https://github.com/linonetwo/Starbound-RPG-Growth-Chinese#contributor)

### 文件名（文件路径）格式

以 `translation` 开头，我们的翻译都放在这个文件夹里。中间的部分就看[待翻译列表](https://pastebin.com/2yQcm0Qv)，一般是 `tech/roguetech/roguetoxicsphere/roguetoxicsphere.tech` 这样。然后我们在最后面补上一个 `.patch`，这样 Starbound 就会用你创建的这个文件来修改源文件了。

### 文件格式

可以找个现有的例子看看，大概是这样：

```json
// ./translation/scripts/explorerglow/explorerglow.statuseffect.patch
[
  {
    "op": "replace",
    "source": "balkklsdlvasbsbfabab",
    "value": "探索与发现",
    "path": "/label"
  }
]
```

- op 是 Starbound 的 API，我们全都用 replace
- source **是我加的**，用于追踪对应的原文，**不存在于 Starbound 标准 API 中！**
- value 是翻译
- path 是原文在 JSON 中的字段的路径，MOD 里的原文都放在一个个 JSON 里，可能位于比较深的位置，用这个路径就能找到它，可以到 [Starbound Mod RPG Growth](https://github.com/IcyVines/Starbound-RPG-Growth) 找个例子看看

## Scripts

### `npm run download:source` 下载原文并解压到 `./source` 文件夹里

下载了原文才能扫描和比对。

### `npm run scan` 扫描原文与翻译的对应情况

会在这个文件夹里生成一个 `report.log` 文件，报告以下情况：

#### 扫描报告结果类型

- 翻译文件缺失：有新的待翻译的文件，或者是 MOD 结构发生改变了
- 源文件缺失：有没有什么翻译补丁文件没有对应的源文件，如果有就说明源 MOD 结构发生改变了
- 翻译条目缺失：补丁文件是有的，不过某个待翻译的词条没有对应的翻译
- 原文条目缺失：补丁文件是有的，之前也翻译过某个词条，不过这次这个词条在原文中不见了
- 译文内容无效：原文和译文相同（说明是放在那边占位等着翻译的，或者原文是「-」这样的占位符）

### `npm run unpack:mac` 解压压缩好的 Mod 文件

其实没什么用，主要是我总是忘记怎么手动解压，就保存在 script 里备忘吧。

### `npm run pack:mac` 打包可发布的 Mod 文件

调用了 `~/Library/'Application Support'/Steam/SteamApps/common/Starbound/osx/asset_packer`。

是 Mac 上才能运行的。

### `npm run generate:overwrite-missing` 自动生成缺失的翻译

使用百度翻译 API 自动生成大量低质翻译，注意这会把一大堆文件写入到 `translation` 文件夹里，和已有的翻译混在一起。

注意当前 git 工作区状态，随时准备回滚。

### `npm run generate:test` 测试自动生成功能

把文件写入到 `translation-test` 文件夹里，比较方便删除生成的文件。

### `npm run try`

运行 `./scripts/try.js` 方便试用一些库。

## Contributor

感谢 [Runningsky](http://www.runningsky.top/localization/sdb/1115920474.html) 在 https://tieba.baidu.com/p/5581918647 分享了初始版本的汉化

目录结构参考了 https://github.com/ProjectSky/FrackinUniverse-sChinese-Project

## 常见问题

### 动态列表无法 Patch

https://github.com/IcyVines/Starbound-RPG-Growth/issues/6

```log
[Error] Could not apply patch from file /interface/RPGskillbook/RPGskillbook.config.patch in source: ../mods/translation.  Caused by: (JsonPatchException) Could not apply patch to base. (JsonPatchException) Could not apply operation to base. (TraversalException) No such key 'list' in pathApply("/gui/lorelayout/children/scrollArea/children/list/schema/listTemplate/title/value")
```

有一个 list 的 key 在静态文件里存在，在要 patch 的时候就不存在了（刚载入的时候没问题，一打开书就报两个错）。

虽然不知道具体原因，不过我猜测是因为 List 在运行时被 Lua 改变了，毕竟它是一个要滚动的 List 嘛，怎么能不变呢（。

请尽量不要去招惹带 `/list/` 的字段。

### 字符颜色不对

可能是翻译程序把一些标记给破坏了，修复方法如下，全局搜索 `；` 即可：

```diff
-   "value": "职业是一项宝贵的资产，可以选择^黄色；1000像素。"
+   "value": "职业是一项宝贵的资产，可以选择^yellow;1000像素。"
```

### 如何上传 Mod 到 Steam？

修改 `RPG_Growth_Chinese.vdf` 里的 `<PATH_TO_THIS_REPO>` 为实际绝对路径，然后进入 steamcmd （没有就下一个），`login 账号 密码`，然后输入 `workshop_build_item <PATH_TO_THIS_REPO>/Starbound-RPG-Growth-Chinese/RPG_Growth_Chinese.vdf` 即可。

详见：
- https://community.playstarbound.com/threads/manually-uploading-to-steam-workshop-with-linux-and-mac-and-windows.118872/
- https://community.playstarbound.com/threads/uploading-a-mod-onto-the-steam-workshop-step-by-step-how-to.118399/
