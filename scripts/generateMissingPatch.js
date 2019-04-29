// @flow
import { findAsync, readAsync, writeAsync, existsAsync, dirAsync } from 'fs-jetpack';
import { dirname } from 'path';
import { it, _ } from 'param.macro';

async function parseReport() {
  const report: string[] = await readAsync('./report.log', 'json');
  await Promise.all(
    report
      .filter(it.startsWith('翻译文件缺失'))
      .map(it.replace('翻译文件缺失 ', ''))
      .map(dirname)
      .map(dirAsync(_)),
  );
}

parseReport();
