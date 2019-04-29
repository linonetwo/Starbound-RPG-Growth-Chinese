const translate = require('baidu-translate-api');

translate(
  'Flame, the Powerful Affinity. This Affinity grants Fire based Immunities and Resistances, and a Medium Vigor Stat Boost. Provides better Immunities and a Large Strength Stat Boost when upgraded. Be careful, as choosing this Affinity weakens you while Submerged, and makes you weak to Poison.',
  { from: 'en', to: 'zh' },
).then(({ trans_result: { dst } }) => dst);
