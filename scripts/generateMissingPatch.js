// @flow
import { readAsync, writeAsync, dirAsync } from 'fs-jetpack';
import { dirname } from 'path';
import { it, _ } from 'param.macro';
import translate from 'baidu-translate-api';

import { keysNeedTranslation } from './constants';
import { keyPathInObject, delay } from './utils';

async function parseReport() {
  const { argv } = require('yargs');
  const outputDir = argv.generate === 'overwrite-missing' ? 'translation' : 'translation-test';

  const report: string[] = await readAsync('./report.log', 'json');
  // 创建不存在的文件夹
  const missingTranslationPath: string[] = report
    .filter(it.startsWith('翻译文件缺失'))
    .map(it.replace('翻译文件缺失 ', ''));
  await Promise.all(missingTranslationPath.map(itt => `${outputDir}/${dirname(itt)}`).map(dirAsync(_)));
  // 创建 patch JSON
  await Promise.all(
    missingTranslationPath.map(aPath =>
      readAsync(`source/${aPath}`, 'json')
        .then(fileJSON => keyPathInObject(fileJSON, keysNeedTranslation))
        .then(places =>
          Promise.all(
            places.map(async ({ value, path }) => {
              let translationResult;
              try {
                // 自动翻译
                await delay(Math.ceil(Math.random() * 100));
                translationResult = await translate(value, { from: 'en', to: 'zh' }).then(
                  ({ trans_result: { dst } }) => dst,
                );
              } catch (error) {
                // 再试一遍，我就不信不成功
                console.error('Translation Error: ', error);
                await delay(Math.ceil(Math.random() * 1000));
                translationResult = await translate(value, { from: 'en', to: 'zh' }).then(
                  ({ trans_result: { dst } }) => dst,
                );
              }

              return { path, op: 'replace', source: value, value: translationResult };
            }),
          ),
        )
        .then(patchesForAFile => writeAsync(`${outputDir}/${aPath}`, patchesForAFile)),
    ),
  );
}

parseReport();
