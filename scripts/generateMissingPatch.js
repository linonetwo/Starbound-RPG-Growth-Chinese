// @flow
import { readAsync, writeAsync, dirAsync } from 'fs-jetpack';
import { dirname } from 'path';
import { it, _ } from 'param.macro';
import BaiduTranslate from 'baidu-translate';
import promiseRetry from 'promise-retry';
import dotenv from 'dotenv';

import { keysNeedTranslation } from './constants';
import { keyPathInObject, delay } from './utils';

dotenv.config();
const translate = new BaiduTranslate(process.env.TRANSLATION_APP_ID, process.env.TRANSLATION_SECRET, 'zh', 'en');
function tryTranslation(value: string) {
  if (!value) return '';
  return promiseRetry((retry, number) => {
    translate(value, 'zh')
      .then(({ trans_result: result }) => {
        if (result && result.length > 0) {
          const [{ dst }] = result;
          return dst;
        }
        console.log('Translation Error: ', result, 'From: ', value.substring(0, 15));
        retry();
      })
      .catch(error => {
        console.error('Translation Error: ', error, 'Retry: ', number);
        retry();
      });
  });
}
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
  let counter = 0;
  await Promise.all(
    missingTranslationPath.map((aPath, fileIndex) =>
      readAsync(`source/${aPath}`, 'json')
        .then(fileJSON => keyPathInObject(fileJSON, keysNeedTranslation))
        .then(() => delay(50 * fileIndex))
        .then(places =>
          Promise.all(
            places.map(async ({ value, path }, index) => {
              // 自动翻译
              await delay(250 * index);
              let translationResult = '';
              try {
                translationResult = await tryTranslation(value);
              } catch (err) {
                console.error(err);
                translationResult = await tryTranslation(value);
              }
              counter += 1;
              console.log(
                `Translated ${((counter / places.length / missingTranslationPath.length) * 100).toFixed(
                  3,
                )}% file#${fileIndex} patch#${index}`,
              );

              return { path, op: 'replace', source: value, value: translationResult };
            }),
          ),
        )
        .then(patchesForAFile => writeAsync(`${outputDir}/${aPath}`, patchesForAFile)),
    ),
  );
}

parseReport();
