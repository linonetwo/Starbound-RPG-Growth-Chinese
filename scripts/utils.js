// @flow
import { readAsync, writeAsync } from 'fs-jetpack';
import { isPlainObject, replace } from 'lodash';
import stripJsonComments from 'strip-json-comments';

export function keyPathInObject(obj: Object, keys: string[], parentPath: string = '') {
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