import BaiduTranslate from 'baidu-translate';

const translate = new BaiduTranslate('20190429000292817', 'zEah9krJpPiesWKhfSJG', 'zh', 'en');

translate(
  "The Wizard: Ranged Utility. Does better with Staffs and Wands. The Wizard's skills mostly improve utility and movement. The Wizard can randomly apply Elemental Status (Fire, Ice, Lightning) to enemies while hitting them, and fares better against the Elements while holding Wands or Staffs.",
).then(res => {
  console.log(res);
  // { from: 'en',
  //   to: 'zh',
  //   trans_result: [ { src: 'apple', dst: '苹果' } ]
  // }
});
