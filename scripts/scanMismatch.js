// @flow
import { findAsync, readAsync, writeAsync, existsAsync } from 'fs-jetpack';

import { fileTypesNeedTranslation, keysNeedTranslation } from './constants';
import { keyPathInObject, sanitizeJSON } from './utils'

type Place = {
  path: string,
  patches: {
    value: any,
    path: string,
  }[],
};
async function getAllConfig(): Promise<Place[]> {
  const allConfigPath = await findAsync('./source', { matching: fileTypesNeedTranslation });
  const places = await Promise.all(
    allConfigPath.map(async filePath => {
      await sanitizeJSON(filePath);
      const configJSON = await readAsync(filePath, 'json');
      const keyPathAndValues = keyPathInObject(configJSON, keysNeedTranslation);
      return { path: filePath.replace('source/', ''), patches: keyPathAndValues };
    }),
  );
  return places;

  // await writeAsync('./aaa.log', places);
}

type Patch = {
  op: string,
  value: string,
  path: string,
};
async function checkMissingTranslation(places: Place[]) {
  const report: string[] = [];

  // 先检查有没有什么翻译补丁文件没有对应的源文件，如果有就说明源 MOD 结构发生改变了
  const allPatchPath = await findAsync('./translation', { matching: ['*.patch'] });
  const task1 = allPatchPath.map(async pathName => {
    const sourcePathName = pathName.replace('translation/', '').replace('.patch', '');
    let sourceExists = false;
    for (const place of places) {
      if (place.path === sourceExists) {
        sourceExists = true;
      }
    }
    if (!sourceExists) {
      report.push(`源文件缺失 ${sourcePathName}`);
    }
  });
  // 还有检查是不是有新的翻译，或者改动的文件结构
  const task2 = places.map(async place => {
    const translationFilePath = `translation${place.path}`;
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
          report.push(`翻译条目缺失 ${sourcePatchObj.path} in ${translationFilePath}`);
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
          report.push(`原文条目缺失 ${patch.path} in ${translationFilePath}`);
        }
      }
    } else {
      report.push(`翻译文件缺失 ${translationFilePath}`);
    }
  });

  return Promise.all([...task1, ...task2]).then(() => report);
}

(async () => {
  const places = await getAllConfig();
  const report = await checkMissingTranslation(places);
  writeAsync('./report.log', report);
})();
