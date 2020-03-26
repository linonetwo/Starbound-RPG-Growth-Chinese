export const fileTypesNeedTranslation = [
  '*.patch',
  '*.config',
  '*.weaponability',
  '*.activeitem',
  '*.item',
  '*.thrownitem',
  '*.statuseffect',
  '*.currency',
  '*.object',
  '*.particle',
  '*.questtemplate',
  '*.tech',
];
export const keysNeedTranslation = [
  'value',
  'name',
  'children',
  'text',
  'title',
  'subtitle',
  'caption',
  'description',
  'shortDescription',
  'shortdescription',
  'label',
  'weaponText',
  'unlockText',
  'changelog',
  'credits',
];
export const keyMaybeDatabaseID = ['name'];
/** 如果这些 key 和 keyMaybeDatabaseID 一同出现，就实锤了 keyMaybeDatabaseID 是 databaseID */
export const keyToJudgeDatabaseID = ['title', 'title', 'text'];
export const stopWordsForValue = ['-'];
/** 如果名字中一部分是这个词，也不能翻译它 */
export const stopWordsPartsForValue = /(ivrpg)|(\.lua)/g;
/** 如果扫描 json 的过程中经过这个 key，我们不翻译它 */
export const stopWordsForPath = ['list'];
/** 源 mod 里有一些 patch 文件，它里面的 path 里带有这些停止词的 patch 文件我们不去覆盖它 */
export const pathStopWordsForPatchFromSource = [
  'itemTags',
  'dropPools',
  'baseParameters',
  '0',
  '1',
  'test1',
  'test2',
  'scripts',
  'primaryScriptSources',
];
export const opDoNotScan = ['test'];
export const textDonTNeedToTranslate = ['0', 0, '-'];
