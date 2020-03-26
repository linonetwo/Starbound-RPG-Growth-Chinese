// @flow
import { readAsync, writeAsync } from 'fs-jetpack';
import { isPlainObject, replace, isArray } from 'lodash';
import stripJsonComments from 'strip-json-comments';

import {
  keyMaybeDatabaseID,
  stopWordsForPath,
  stopWordsForValue,
  pathStopWordsForPatchFromSource,
  opDoNotScan,
  stopWordsPartsForValue,
  keyToJudgeDatabaseID,
} from './constants';
import type { Patch } from './types';

export const delay = (ms: number) => new Promise<any>(resolve => setTimeout(resolve, ms));

export function keyPathInObject(obj: Object, keys: string[], parentPath: string = ''): Patch[] {
  let keyPaths: Patch[] = [];
  // 看看是不是源文件中的 patch 文件
  if (isArray(obj)) {
    obj.forEach((item, index) => {
      if (opDoNotScan.includes(item.op)) return;
      // 处理多维数组
      if (isArray(item)) {
        const keyPathsInChild = keyPathInObject(item, keys, `${parentPath}/${index}`);
        keyPaths = keyPaths.concat(keyPathsInChild);
        return;
      }
      if (item.path) {
        for (let stopWordID = 0; stopWordID < pathStopWordsForPatchFromSource.length; stopWordID += 1) {
          if (item.path.includes(pathStopWordsForPatchFromSource[stopWordID])) {
            return;
          }
        }
      }
      // 处理普通数组
      if (isPlainObject(item)) {
        const keyPathsInChild = keyPathInObject(item, keys, `${parentPath}/${index}`);
        keyPaths = keyPaths.concat(keyPathsInChild);
        return;
      }
      // 如果不是 array 又没有 value，那就没啥用了
      if (!item.value) {
        return;
      }
      if (isArray(item.value) || isArray(item.value.item)) return;
      keyPaths.push(item);
    });
  } else {
    for (const key in obj) {
      // 如果是要翻译的字段
      if (
        keys.includes(key) &&
        typeof obj[key] === 'string' &&
        obj[key].length > 0 &&
        !obj[key].match(stopWordsPartsForValue) &&
        !stopWordsForValue.includes(obj[key]) &&
        !stopWordsForPath.includes(key)
      ) {
        // 有的字段在 JSON 的最顶层的时候是作为数据库 id 使用的，所以仅当不是顶级字段的时候才翻译它
        const isDatabaseID =
          keyMaybeDatabaseID.includes(key) && ((keyToJudgeDatabaseID: string[]).some(id => id in obj) || parentPath.length === 0);
        if (!isDatabaseID) {
          keyPaths.push({ op: 'replace', value: obj[key], path: `${parentPath}/${key}` });
        }
      }
      // 检查这个字段是不是有子字段
      if (!stopWordsForPath.includes(key) && (isPlainObject(obj[key]) || Array.isArray(obj[key]))) {
        const keyPathsInChild = keyPathInObject(obj[key], keys, `${parentPath}/${key}`);
        keyPaths = keyPaths.concat(keyPathsInChild);
      }
    }
  }
  return keyPaths;
}

export async function sanitizeJSON(filePath: string) {
  const rawJSONString = await readAsync(filePath, 'utf8');
  // 修复多行字符串
  let result = replace(
    rawJSONString,
    /"[a-zA-Z_]+"[\n ]*:[\n ]*"[^"]+?"/g,
    (badMultilineLineString: string) => {
      return badMultilineLineString
        .split('\n')
        .join('\\n ')
        .replace(/:\\n"/g, ': "');
    },
  );
  // 修复小数点
  result = replace(result, /[0-9]\.[,\]]/g, dicimal => dicimal.replace('.', '.0'));
  // Invalid characters in string. Control characters must be escaped.
  result = replace(result, /\t/g, '  ')
  return writeAsync(filePath, stripJsonComments(result));
}
