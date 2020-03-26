// @flow
import BaiduTranslate from 'baidu-translate';
import promiseRetry from 'promise-retry';
import dotenv from 'dotenv';

dotenv.config();
const translate = new BaiduTranslate(process.env.TRANSLATION_APP_ID, process.env.TRANSLATION_SECRET, 'zh', 'en');

function fixMistranslation(text: string) {
  return text
    .replace(/\^?(品|洋)红(色|的)?(：|:|；)?/g, '^magenta;')
    .replace(/\^?红(色|的)(：|:|；)?/g, '^red;')
    .replace(/\^?绿(色|的)(：|:|；)?/g, '^green;')
    .replace(/\^?白(色|的)(：|:|；)?/g, '^white;')
    .replace(/\^?黄(色|的)(：|:|；)?/g, '^yellow;')
    .replace(/\^?(橘|橙)(色|的)(：|:|；)?/g, '^orange;')
    .replace(/\^?灰(色|的)(：|:|；)?/g, '^gray;')
    .replace(/\^?蓝(色|的)(：|:|；)?/g, '^blue;')
    .replace(/\^?(重置|复位)(：|:|；)?/g, '^reset;')
    .replace(/\^?暗影(：|:|；)?/g, '^shadow;')
    .replace(/\^?黑(色|的)(：|:|；)?/g, '^black;')
    .replace(/(\^#[a-z0-9]{6})；/g, '$1;')
    // 奇怪的翻译
    .replace(/功率倍增/g, '增加攻击力乘数')
    .replace(/关键机会/g, '暴击几率')
    .replace(/纸卷/g, '卷轴')
    .replace(/身体形态/g, '物理形态') // physical form
    .replace(/魔术师们/g, '重甲战士们') // Juggernauts
    .replace(/技术员/g, '重甲战士们') // Technomancer
    .replace('\n个', '\n')
    .replace(/(一次火灾|初级射击|主火|一次射击|初级火|一级火)/, '主要攻击') // Primary Fire
    .replace(/(次要攻击|次要攻击)/, '次要攻击') // Secondary Fire
    .replace('乙醚', '以太') // Aether
    .replace('核磁共振', '生存食品包') // MRE+
    .replace('电阻', '豁免') // Physical Resistance
    .replace('功率倍增', '攻击力增加') // Increased Power Multiplier
}

function replaceNto1111(text: string) {
  // 防止 \n 影响了翻译
  return text.replace('\n\n', ' 2222 ').replace('\n', ' 1111 ')
}
function replace1111toN(text: string) {
  // 防止 \n 影响了翻译
  return text.replace('1111', '\n').replace('2222', '\n\n')
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
