# Starbound-RPG-Growth-Chinese

Starbound Mod RPG Growth 汉化

## Scripts

### `npm run download:source` 下载原文并解压到 `./source` 文件夹里

下载了原文才能扫描和比对。

### `npm run scan` 扫描原文与翻译的对应情况

会在这个文件夹里生成一个 `report.log` 文件，报告以下情况：

- 翻译文件缺失：有新的待翻译的文件，或者是 MOD 结构发生改变了
- 源文件缺失：有没有什么翻译补丁文件没有对应的源文件，如果有就说明源 MOD 结构发生改变了
- 翻译条目缺失：补丁文件是有的，不过某个待翻译的词条没有对应的翻译
- 原文条目缺失：补丁文件是有的，之前也翻译过某个词条，不过这次这个词条在原文中不见了

### `npm run unpack:mac` 解压压缩好的 Mod 文件

其实没什么用，主要是我总是忘记怎么手动解压，就保存在 script 里备忘吧。

## Contributor

感谢 @993499094 在 https://tieba.baidu.com/p/5581918647 分享了初始版本的汉化

目录结构参考了 https://github.com/ProjectSky/FrackinUniverse-sChinese-Project
