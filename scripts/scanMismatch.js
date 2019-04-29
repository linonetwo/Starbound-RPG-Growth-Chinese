// @flow
import { findAsync, readAsync, writeAsync, existsAsync } from 'fs-jetpack';
import { isPlainObject, replace, flatten, assign } from 'lodash';
import stripJsonComments from 'strip-json-comments';

function keyPathInObject(obj: Object, keys: string[], parentPath: string = '') {
  let keyPaths: { value: any, path: string }[] = [];
  for (const key in obj) {
    // 如果是要翻译的字段
    if (keys.includes(key)) {
      keyPaths.push({ value: obj[key], path: `${parentPath}/${key}` });
    }
    // 检查这个字段是不是有子字段
    if (isPlainObject(obj[key])) {
      const keyPathsInChild = keyPathInObject(obj[key], keys, `${parentPath}/${key}`);
      keyPaths = keyPaths.concat(keyPathsInChild);
    }
  }
  return keyPaths;
}

async function sanitizeJSON(filePath: string) {
  const rawJSONString = await readAsync(filePath, 'utf8');
  const result = replace(
    rawJSONString,
    /"[\n ]*:[\n ]*"([0-9a-zA-Z!^;/()+\-:?,.\\ ]*\n)+([0-9a-zA-Z!^;/()+\-:?,.\\ ]*\n?)"/g,
    (badMultilineLineString: string) => {
      return badMultilineLineString
        .split('\n')
        .join('\\n')
        .replace(/:\\n"/g, ': "');
    },
  );
  return writeAsync(filePath, stripJsonComments(result));
}

const keysNeedsTranslation = [
  'value',
  'name',
  'text',
  'title',
  'subtitle',
  'caption',
  'description',
  'shortDescription',
  'label',
];
type Place = {
  path: string,
  patches: {
    value: any,
    path: string,
  }[],
};
async function getAllConfig(): Promise<Place[]> {
  const allConfigPath = await findAsync('./source', { matching: ['*.config'] });
  const places = await Promise.all(
    allConfigPath.map(async filePath => {
      await sanitizeJSON(filePath);
      const configJSON = await readAsync(filePath, 'json');
      const keyPathAndValues = keyPathInObject(configJSON, keysNeedsTranslation);
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
    const result = await existsAsync(`source/${sourcePathName}`);
    if (!result) {
      report.push(`源文件缺失 ${sourcePathName}`);
    }
  });
  // 还有检查是不是有新的翻译，或者改动的文件结构
  const task2 = places.map(async place => {
    const translationFilePath = `./translation${place.path}`;
    const patchExists = await existsAsync(translationFilePath);
    if (patchExists) {
      const patchJSON: Patch[] = await readAsync(translationFilePath, 'json');
      // 这里可以用散列表但我就不用因为已经够快了
      // 对于每一个待翻译的词条
      for (const sourcePath of place.patches) {
        // 看看有没有对应的翻译
        let hasTranslation = false;
        for (const patch of patchJSON) {
          if (patch.path === sourcePath.path) {
            hasTranslation = true;
          }
        }
        if (!hasTranslation) {
          report.push(`翻译条目缺失 ${sourcePath.path} in ${translationFilePath}`);
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
