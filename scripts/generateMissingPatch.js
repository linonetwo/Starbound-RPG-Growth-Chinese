// @flow
import { readAsync, writeAsync, dirAsync } from 'fs-jetpack';
import { dirname } from 'path';
import { it, _ } from 'param.macro';
import { assign } from 'lodash';

import { keysNeedTranslation } from './constants';
import { keyPathInObject } from './utils';

async function parseReport() {
  const report: string[] = await readAsync('./report.log', 'json');
  // 创建不存在的文件夹
  const missingTranslationPath = report.filter(it.startsWith('翻译文件缺失')).map(it.replace('翻译文件缺失 ', ''));
  await Promise.all(
    missingTranslationPath
      .map(itt => `${dirname(itt)}`)
      // .map(itt => `translation/${dirname(itt)}`)
      .map(dirAsync(_)),
  );
  // 创建 patch JSON
  missingTranslationPath
    .map(readAsync(it, 'json'))
    .map(fileJSON => keyPathInObject(fileJSON, keysNeedTranslation))
    .map(places => places.map(place => assign(place, { op: 'replace', source: place.value })))
    .map(patchesForAFile => {
      return writeAsync(`${patchesForAFile[0].path}`, patchesForAFile);
    });
}

parseReport();
