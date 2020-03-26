import tryTranslation from './tryTranslation';

tryTranslation("And sure enough, the Thief and Stalker fled with stars above,\nholding on to precious gems that they'd been dreaming of.\n\nAll along the watchtower, guards curse with ragged breath,\nwhile both the cunning criminals escape avoiding death.").then(res => {
  console.log(JSON.stringify(res));
  // { from: 'en',
  //   to: 'zh',
  //   trans_result: [ { src: 'apple', dst: '苹果' } ]
  // }
});
