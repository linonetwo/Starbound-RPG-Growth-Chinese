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
  const missingTranslationPath: string[] = report
    .filter(it.startsWith('翻译文件缺失'))
    .map(it.replace('翻译文件缺失 ', ''));
  await Promise.all(missingTranslationPath.map(itt => `translation/${dirname(itt)}`).map(dirAsync(_)));
  // 创建 patch JSON
  await Promise.all(
    missingTranslationPath.map(aPath =>
      readAsync(`source/${aPath}`, 'json')
        .then(fileJSON => keyPathInObject(fileJSON, keysNeedTranslation))
        .then(places => places.map(place => assign(place, { op: 'replace', source: place.value })))
        .then(patchesForAFile => {
          console.log(patchesForAFile);

          return writeAsync(`translation/${aPath}`, patchesForAFile);
        }),
    ),
  );
}

parseReport();
