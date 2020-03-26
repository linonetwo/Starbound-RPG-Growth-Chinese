// @flow
import BaiduTranslate from 'baidu-translate';
import promiseRetry from 'promise-retry';
import dotenv from 'dotenv';

dotenv.config();
const translate = new BaiduTranslate(process.env.TRANSLATION_APP_ID, process.env.TRANSLATION_SECRET, 'zh', 'en');

function fixMistranslation(text: string) {
  return text
    .replace(/\^?红色(：|:|；)?/g, '^red;')
    .replace(/\^?绿色(：|:|；)?/g, '^green;')
    .replace(/\^?白色(：|:|；)?/g, '^white;')
    .replace(/\^?黄色(：|:|；)?/g, '^yellow;')
    .replace(/\^?(橘|橙)色(：|:|；)?/g, '^orange;')
    .replace(/\^?灰色(：|:|；)?/g, '^gray;')
    .replace(/\^?蓝色(：|:|；)?/g, '^blue;')
    .replace(/\^?(品|洋)红色?(：|:|；)?/g, '^magenta;')
    .replace(/\^?重置(：|:|；)?/g, '^reset;')
    .replace(/\^?暗影(：|:|；)?/g, '^shadow;');
}

export default function tryTranslation(value: string | Object): Promise<string | Object> {
  if (typeof value !== 'string') return Promise.resolve(value);
  if (!value) return Promise.resolve('');
  let lastResult = 'null';
  let retryCount = 0;
  return promiseRetry(
    (retry, number) =>
      translate(value)
        .then(({ trans_result: result }) => {
          if (result && result.length > 0) {
            const [{ dst }] = result;
            return fixMistranslation(dst);
          }
          lastResult = result;
          retryCount = number;
          retry();
        })
        .catch(() => {
          retryCount = number;
          retry();
        }),
    { retries: 100, maxTimeout: 10000, randomize: true },
  ).catch(error => {
    return `Translation Error: ${error} result: ${lastResult}, From: ${value}, Count: ${retryCount}\nRetry Again\n--\n\n `;
  });
}
