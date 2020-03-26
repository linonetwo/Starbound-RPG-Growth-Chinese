import tryTranslation from './tryTranslation';

tryTranslation('Arena Battle : Shattered Stars').then(res => {
  console.log(JSON.stringify(res));
  // { from: 'en',
  //   to: 'zh',
  //   trans_result: [ { src: 'apple', dst: '苹果' } ]
  // }
});
