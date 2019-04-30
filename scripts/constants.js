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
  'text',
  'title',
  'subtitle',
  'caption',
  'description',
  'shortDescription',
  'shortdescription',
  'label',
];
export const keyOnlyTranslateIfItIsChild = ['name'];
export const stopWordsForValue = ['-'];
/** 如果扫描 json 的过程中经过这个 key，我们不翻译它 */
export const stopWordsForPath = ['list'];
/** 源 mod 里有一些 patch 文件，它里面的 path 里带有这些停止词的 patch 文件我们不去覆盖它 */
export const pathStopWordsForPatchFromSource = ['itemTags', 'dropPools', 'baseParameters', '0', '1', 'test1', 'test2', 'scripts', 'primaryScriptSources'];
export const opDoNotScan = ['test'];
