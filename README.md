# Starbound-RPG-Growth-Chinese

[Starbound Mod RPG Growth](https://github.com/IcyVines/Starbound-RPG-Growth) 汉化

## Contribute

可以先看看[目前扫描出来的待翻译列表](https://pastebin.com/2yQcm0Qv)，报错类型可以在[下面](https://github.com/linonetwo/Starbound-RPG-Growth-Chinese#npm-run-scan-%E6%89%AB%E6%8F%8F%E5%8E%9F%E6%96%87%E4%B8%8E%E7%BF%BB%E8%AF%91%E7%9A%84%E5%AF%B9%E5%BA%94%E6%83%85%E5%86%B5)查看。

直接点击 Create New File，然后在文件名那边黏贴 `translation/translationaffinities/affinityDescriptions.config.patch` 这样的文件名，就会自动创建文件夹和文件了。

![create new file](doc/images/createnewfile.png)

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
- source 是我加的，用于追踪对应的原文
- value 是翻译
- path 是原文在 JSON 中的字段的路径，MOD 里的原文都放在一个个 JSON 里，可能位于比较深的位置，用这个路径就能找到它，可以到 [Starbound Mod RPG Growth](https://github.com/IcyVines/Starbound-RPG-Growth) 找个例子看看

## Scripts

### `npm run download:source` 下载原文并解压到 `./source` 文件夹里

下载了原文才能扫描和比对。

### `npm run scan` 扫描原文与翻译的对应情况

会在这个文件夹里生成一个 `report.log` 文件，报告以下情况：

#### 报错类型

- 翻译文件缺失：有新的待翻译的文件，或者是 MOD 结构发生改变了
- 源文件缺失：有没有什么翻译补丁文件没有对应的源文件，如果有就说明源 MOD 结构发生改变了
- 翻译条目缺失：补丁文件是有的，不过某个待翻译的词条没有对应的翻译
- 原文条目缺失：补丁文件是有的，之前也翻译过某个词条，不过这次这个词条在原文中不见了

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
