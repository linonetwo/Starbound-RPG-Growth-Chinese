// @flow
import { read, readAsync, writeAsync, dirAsync } from 'fs-jetpack';
import { dirname } from 'path';
import { it, _ } from 'param.macro';
import { get, memoize, remove } from 'lodash';

import { keysNeedTranslation } from './constants';
import { keyPathInObject, delay } from './utils';
import tryTranslation from './tryTranslation';

const DELAY_BEFORE_START = 200;
const DELAY_BETWEEN_EACH = 500;

/** 补齐翻译文件缺失 */
async function generateMissingTranslationFiles(report: string[], outputDir: string) {
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
        .then(async itt => {
          await delay(DELAY_BEFORE_START * fileIndex);
          return itt;
        })
        .then(places =>
          Promise.all(
            places.map(async ({ value, path }, index) => {
              // 自动翻译
              await delay(DELAY_BETWEEN_EACH * index);
              let translationResult = '';
              try {
                translationResult = await tryTranslation(value);
              } catch (err) {
                console.error(err);
                translationResult = await tryTranslation(value);
              }
              console.log(
                // eslint-disable-next-line no-plusplus
                `Translated ${((counter++ / places.length / missingTranslationPath.length) * 100).toFixed(
                  3,
                )}% file#${fileIndex} patch#${index}`,
              );

              return { path, op: 'replace', source: value, value: translationResult };
            }),
          ),
        )
        .then(patchesForAFile => writeAsync(`${outputDir}/${aPath}.patch`, patchesForAFile)),
    ),
  );
}

/** 补齐翻译条目缺失 */
async function appendMissingTranslationItem(report: string[], outputDir: string) {
  // 创建不存在的文件夹
  const missingTranslationPaths: { keyPath: string, sourceFilePath: string, translationFilePath: string }[] = report
    .filter(it.startsWith('翻译条目缺失'))
    .map(it.replace('翻译条目缺失 ', ''))
    .map(it.split(' in '))
    .map(([keyPath, filePath]) => ({
      keyPath,
      sourceFilePath: `source/${filePath}`,
      translationFilePath: `${outputDir}/${filePath}.patch`,
    }));

  const memorizedReadAsync = memoize(readAsync);
  const translationFileContents = {};
  await Promise.all(
    missingTranslationPaths.map(async ({ keyPath, sourceFilePath, translationFilePath }, index) => {
      const sourceJSON = await memorizedReadAsync(sourceFilePath, 'json');
      const dotBasedKeyPath = keyPath.substring(1).split('/');
      const source = get(sourceJSON, dotBasedKeyPath);

      await delay(DELAY_BEFORE_START * index);
      if (!source) {
        console.warn('!source in appendMissingTranslationItem', source, keyPath, sourceFilePath, translationFilePath);
        return;
      }
      // 不需要翻译的数字
      if (source === '0' || source === 0) {
        return;
      }
      let value = '';
      try {
        value = await tryTranslation(source);
      } catch (err) {
        console.error(err);
        value = await tryTranslation(source);
      }
      const patch = {
        path: keyPath,
        op: 'replace',
        source,
        value,
      };

      // 可能得搞个锁……
      if (translationFileContents[translationFilePath]) {
        translationFileContents[translationFilePath].push(patch);
      } else {
        const previousFile = read(translationFilePath);
        let parsedArray: Object[] = [];
        try {
          parsedArray = JSON.parse(previousFile);
        } catch (error) {
          console.warn(
            `奇怪， ${translationFilePath} 没有被创建过，为什么扫描器把它误报为「翻译条目缺失」而不是文件缺失?`,
          );
        }
        parsedArray.push(patch);
        translationFileContents[translationFilePath] = parsedArray;
      }
    }),
  );
  await Promise.all(
    Object.keys(translationFileContents).map((translationFilePath: string) => {
      return writeAsync(translationFilePath, translationFileContents[translationFilePath]).catch(aaa =>
        console.log('writeAsync Error: ', aaa),
      );
    }),
  );
}

/** 解决原文条目缺失 */
async function removeMissingSourceItem(report: string[], outputDir: string) {
  // 创建不存在的文件夹
  const missingTranslationPaths: { keyPath: string, translationFilePath: string }[] = report
    .filter(it.startsWith('原文条目缺失') || it.startsWith('原文条目不该翻译'))
    .map(it.replace('原文条目缺失 ', '').replace('原文条目不该翻译 ', ''))
    .map(it.split(' in '))
    .map(([keyPath, filePath]) => ({
      keyPath,
      translationFilePath: `${outputDir}/${filePath}.patch`,
    }));

  const translationFiles = new Set<string>();
  const translationFileContents: { [path: string]: { path: string, op: String, value: string }[] } = {};
  missingTranslationPaths.forEach(({ translationFilePath }) => {
    translationFiles.add(translationFilePath);
  });
  const readFileTask = [];
  translationFiles.forEach(translationFilePath => {
    readFileTask.push(
      readAsync(translationFilePath, 'json').then(fileJSON => {
        translationFileContents[translationFilePath] = fileJSON;
      }),
    );
  });
  await Promise.all(readFileTask);

  // 移出没用的 Patch Item
  missingTranslationPaths.forEach(({ translationFilePath, keyPath }) => {
    remove(translationFileContents[translationFilePath], ({ path }) => path === keyPath);
  });

  await Promise.all(
    Object.keys(translationFileContents).map((translationFilePath: string) => {
      return writeAsync(translationFilePath, translationFileContents[translationFilePath]).catch(aaa =>
        console.log('writeAsync Error: ', aaa),
      );
    }),
  );
}

/** 解决译文内容无效，可能是没翻译，也可能内容是 - 之类的占位符 */
async function removeUnusableSourceItem(report: string[], outputDir: string) {
  // 创建不存在的文件夹
  const missingTranslationPaths: { keyPath: string, translationFilePath: string }[] = report
    .filter(it.startsWith('译文内容无效'))
    .map(it.replace('译文内容无效 ', ''))
    .map(it.split(' in '))
    .map(([keyPath, filePath]) => ({
      keyPath,
      translationFilePath: `${outputDir}/${filePath}.patch`,
    }));

  const translationFiles = new Set<string>();
  const translationFileContents: { [path: string]: { path: string, op: String, value: string }[] } = {};
  missingTranslationPaths.forEach(({ translationFilePath }) => {
    translationFiles.add(translationFilePath);
  });
  const readFileTask = [];
  translationFiles.forEach(translationFilePath => {
    readFileTask.push(
      readAsync(translationFilePath, 'json').then(fileJSON => {
        translationFileContents[translationFilePath] = fileJSON;
      }),
    );
  });
  await Promise.all(readFileTask);

  // 移出没用的 Patch Item
  missingTranslationPaths.forEach(({ translationFilePath, keyPath }) => {
    remove(translationFileContents[translationFilePath], ({ path }) => path === keyPath);
  });

  await Promise.all(
    Object.keys(translationFileContents).map((translationFilePath: string) => {
      return writeAsync(translationFilePath, translationFileContents[translationFilePath]).catch(aaa =>
        console.log('writeAsync Error: ', aaa),
      );
    }),
  );
}

async function parseReport() {
  const { argv } = require('yargs');
  const outputDir = argv.generate === 'overwrite-missing' ? 'translation' : 'translation-test';

  const report: string[] = await readAsync('./report.log', 'json');

  generateMissingTranslationFiles(report, outputDir);
  appendMissingTranslationItem(report, outputDir);
  removeMissingSourceItem(report, outputDir);
  removeUnusableSourceItem(report, outputDir);
}

parseReport();
