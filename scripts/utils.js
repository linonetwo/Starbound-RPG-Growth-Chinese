// @flow
import { readAsync, writeAsync } from 'fs-jetpack';
import { isPlainObject, replace } from 'lodash';
import stripJsonComments from 'strip-json-comments';

import { keyOnlyTranslateIfItIsChild } from './constants'

export const delay = (ms: number) => new Promise<any>(resolve => setTimeout(resolve, ms));

export function keyPathInObject(obj: Object, keys: string[], parentPath: string = '') {
  let keyPaths: { value: string, path: string }[] = [];
  for (const key in obj) {
    // 如果是要翻译的字段
    if (keys.includes(key) && typeof obj[key] === 'string' && obj[key].length > 0) {
      // 有的字段在 JSON 的最顶层的时候是作为数据库 id 使用的，所以仅当不是顶级字段的时候才翻译它
      if (!keyOnlyTranslateIfItIsChild.includes(key) || parentPath.length !== 0) {
        keyPaths.push({ value: obj[key], path: `${parentPath}/${key}` });
      }
    }
    // 检查这个字段是不是有子字段
    if (isPlainObject(obj[key])) {
      const keyPathsInChild = keyPathInObject(obj[key], keys, `${parentPath}/${key}`);
      keyPaths = keyPaths.concat(keyPathsInChild);
    }
  }
  return keyPaths;
}

export async function sanitizeJSON(filePath: string) {
  const rawJSONString = await readAsync(filePath, 'utf8');
  // 修复多行字符串
  let result = replace(
    rawJSONString,
    /"[\n ]*:[\n ]*"([0-9a-zA-Z!^;/()+\-:?,.\\ ]*\n)+([0-9a-zA-Z!^;/()+\-:?,.\\ ]*\n?)"/g,
    (badMultilineLineString: string) => {
      return badMultilineLineString
        .split('\n')
        .join('\\n')
        .replace(/:\\n"/g, ': "');
    },
  );
  // 修复小数点
  result = replace(result, /[0-9]\.[,\]]/g, dicimal => dicimal.replace('.', '.0'));
  return writeAsync(filePath, stripJsonComments(result));
}
