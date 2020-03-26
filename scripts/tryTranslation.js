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
    .replace(/\^?(重置|复位)(：|:|；)?/g, '^reset;')
    .replace(/\^?暗影(：|:|；)?/g, '^shadow;')
    // 奇怪的翻译
    .replace(/功率倍增/g, '增加攻击力乘数')
    .replace(/关键机会/g, '暴击几率')
}

function replaceNto1111(text: string) {
  // 防止 \n 影响了翻译
  return text.replace('\n', ' 1111 ')
}
function replace1111toN(text: string) {
  // 防止 \n 影响了翻译
  return text.replace('1111', '\n')
}

export default function tryTranslation(value: string | Object): Promise<string | Object> {
  if (typeof value !== 'string') return Promise.resolve(value);
  if (!value) return Promise.resolve('');
  let lastResult = 'null';
  let retryCount = 0;
  return promiseRetry(
    (retry, number) =>
      translate(replaceNto1111(value))
        .then(({ trans_result: result }) => {
          if (result && result.length > 0) {
            const [{ dst }] = result;
            return fixMistranslation(replace1111toN(dst));
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
