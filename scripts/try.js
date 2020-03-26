import tryTranslation from './tryTranslation';

tryTranslation("^#ffaafa;Hmm. ^white;Silence burgeoned as his orbitals shattered. ^#ffaafa;I sssuppose you would.").then(res => {
  console.log(JSON.stringify(res));
  // { from: 'en',
  //   to: 'zh',
  //   trans_result: [ { src: 'apple', dst: '苹果' } ]
  // }
});
