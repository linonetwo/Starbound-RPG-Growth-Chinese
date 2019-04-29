// @flow
import { findAsync, readAsync, writeAsync, existsAsync } from 'fs-jetpack';
import { compact } from 'lodash';

import { fileTypesNeedTranslation, keysNeedTranslation } from './constants';
import { keyPathInObject, sanitizeJSON } from './utils';

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

type Patch = {
  op: string,
  value: string,
  path: string,
  source?: string,
};
async function checkMissingTranslation(places: Place[]) {
  const report: string[] = [];

  // 先检查有没有什么翻译补丁文件没有对应的源文件，如果有就说明源 MOD 结构发生改变了
  const allPatchPath = await findAsync('./translation', { matching: ['*.patch'] });
  const task1 = allPatchPath.map(async pathName => {
    /** 去掉了 .patch 和  translation/ 的中间的部分，可以用来搜索源文件 */
    const sourcePathName = pathName.replace('translation/', '').replace('.patch', '');
    let sourceExists = false;
    for (const place of places) {
      if (place.path === sourcePathName) {
        sourceExists = true;
      }
    }
    if (!sourceExists) {
      report.push(`源文件缺失 ${sourcePathName}`);
    }
  });
  // 还有检查是不是有新的翻译，或者改动的文件结构
  const task2 = places.map(async place => {
    /** 源文件中去掉了 source/ 的中间的部分，再接上了 translation/ 和 .patch，可以用来搜索翻译文件 */
    const translationFilePath = `translation/${place.path}.patch`;
    const patchExists = await existsAsync(translationFilePath);
    if (patchExists) {
      const patchJSON: Patch[] = await readAsync(translationFilePath, 'json');
      // 这里可以用散列表但我就不用因为已经够快了
      // 对于每一个待翻译的词条
      for (const sourcePatchObj of place.patches) {
        // 看看有没有对应的翻译
        let hasTranslation = false;
        for (const patch of patchJSON) {
          if (patch.path === sourcePatchObj.path) {
            hasTranslation = true;
          }
        }
        if (!hasTranslation) {
          report.push(`翻译条目缺失 ${sourcePatchObj.path} in ${place.path}`);
        }
      }

      // 对于每一个已翻译的词条
      for (const patch of patchJSON) {
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

        // 检查原文和译文是不是相同的
        if ('source' in patch && patch.source === patch.value) {
          report.push(`译文内容无效 ${patch.path} in ${place.path}`);
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
