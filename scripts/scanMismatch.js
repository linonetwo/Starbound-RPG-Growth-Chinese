// @flow
import { findAsync, readAsync, writeAsync, existsAsync } from 'fs-jetpack';
import { compact } from 'lodash';

import { fileTypesNeedTranslation, keysNeedTranslation, stopWordsPartsForValue } from './constants';
import { keyPathInObject, sanitizeJSON } from './utils';
import type { Patch } from './types';

type Place = {
  path: string,
  patches: {
    value: any,
    /** 源文件中去掉了 source/ 的中间的部分，可以用来搜索翻译文件 */
    path: string,
  }[],
};
async function getAllConfig(): Promise<Place[]> {
  const allSourceFilePaths = await findAsync('./source', { matching: fileTypesNeedTranslation });
  const places = await Promise.all(
    allSourceFilePaths.map(async filePath => {
      await sanitizeJSON(filePath);
      const configJSON = await readAsync(filePath, 'json');
      const keyPathAndValues = keyPathInObject(configJSON, keysNeedTranslation);
      if (keyPathAndValues.length > 0) {
        return { path: filePath.replace('source/', ''), patches: keyPathAndValues };
      }
    }),
  );
  return compact(places);

  // await writeAsync('./aaa.log', places);
}

/**
 *
 * @param {Place[]} places 源文件及其内部待 patch 内容的列表
 */
async function checkMissingTranslation(places: Place[]) {
  const report: string[] = [];

  // 先检查有没有什么翻译补丁文件没有对应的源文件，如果有就说明源 MOD 结构发生改变了
  const allTranslationFilePath = await findAsync('./translation', { matching: ['*.patch'] });
  const task1 = allTranslationFilePath.map(async translationPathName => {
    /** 去掉了 .patch 和  translation/ 的中间的部分，可以用来搜索源文件 */
    const sourcePathNameMiddlePart = translationPathName.replace('translation/', '').replace('.patch', '');
    let sourceExists = false;
    for (const place of places) {
      // 如果翻译文件去掉 .patch 和源文件相同，或者源文件本身也是个 .patch 文件
      if (place.path === sourcePathNameMiddlePart || place.path === `${sourcePathNameMiddlePart}.patch`) {
        sourceExists = true;
      }
    }
    if (!sourceExists) {
      report.push(`源文件缺失 ${sourcePathNameMiddlePart}`);
    }
  });
  // 还有检查是不是有新的翻译，或者改动的文件结构
  const task2 = places.map(async place => {
    /** 源文件中去掉了 source/ 的中间的部分，再接上了 translation/ 和 .patch，可以用来搜索翻译文件 */
    const translationFilePath = `translation/${place.path.replace('.patch', '')}.patch`;
    const patchExists = await existsAsync(translationFilePath);
    if (patchExists) {
      const patchJSON: Patch[] | Patch[][] = await readAsync(translationFilePath, 'json');
      // 这里可以用散列表但我就不用因为已经够快了
      // 对于每一个待翻译的词条
      for (const sourcePatchObj of place.patches) {
        // 看看有没有对应的翻译
        let hasTranslation = false;
        for (const patch of patchJSON) {
          if (Array.isArray(patch)) {
            // patch.forEach(subPatch => {
            //   if (subPatch.path === sourcePatchObj.path) {
            hasTranslation = true; // keybindingsmenu.config.patch 不好检查，不查了
            //   }
            // });
          } else if (patch.path === sourcePatchObj.path) {
            hasTranslation = true;
          }
        }
        if (!hasTranslation && !sourcePatchObj.value.match(stopWordsPartsForValue)) {
          report.push(`翻译条目缺失 ${sourcePatchObj.path} in ${place.path}`);
        }
      }

      // 对于每一个已翻译的词条
      for (const patch of patchJSON) {
        if (!Array.isArray(patch)) {
          // 看看有没有对应的原文，没有就说明原文被移走了
          let hasTranslation = false;
          for (const sourcePath of place.patches) {
            if (patch.path === sourcePath.path) {
              hasTranslation = true;
            }
          }
          if (!hasTranslation) {
            report.push(`原文条目缺失 ${patch.path} in ${place.path}`);
          }
          if (patch.source && patch.source.match(stopWordsPartsForValue)) {
            report.push(`原文条目不该翻译 ${patch.path} in ${place.path}`);
          }

          // 检查原文和译文是不是相同的
          if ('source' in patch && patch.source === patch.value) {
            report.push(`译文内容无效 ${patch.path} in ${place.path}`);
          }
        }
      }
    } else {
      report.push(`翻译文件缺失 ${place.path}`);
    }
  });

  return Promise.all([...task1, ...task2]).then(() => report);
}

(async () => {
  const places = await getAllConfig();
  const report = await checkMissingTranslation(places);
  writeAsync('./report.log', report);
})();
