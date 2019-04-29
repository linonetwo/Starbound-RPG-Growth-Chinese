// @flow
import { findAsync, readAsync, writeAsync, existsAsync, dirAsync } from 'fs-jetpack';
import { dirname } from 'path';
import { it, _ } from 'param.macro';
import { keyPathInObject, sanitizeJSON } from './utils'

async function parseReport() {
  const report: string[] = await readAsync('./report.log', 'json');
  await Promise.all(
    report
      .filter(it.startsWith('翻译文件缺失'))
      .map(it.replace('翻译文件缺失 ', ''))
      .map(itt => `${dirname(itt)}`)
      // .map(itt => `translation/${dirname(itt)}`)
      .map(dirAsync(_)),
  );
}

parseReport();
