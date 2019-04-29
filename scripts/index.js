#!/usr/bin/env node
require('@babel/register')({
  ignore: [/\/(build|node_modules)\//],
  presets: [
    [
      '@babel/preset-env',
      {
        targets: {
          node: 'current',
        },
      },
    ],
  ],
  plugins: [
    'macros',
    '@babel/plugin-proposal-do-expressions',
    '@babel/plugin-proposal-optional-chaining',
    '@babel/plugin-syntax-flow',
    '@babel/plugin-transform-flow-strip-types',
    [
      'flow-runtime',
      {
        assert: true,
        annotate: true,
        warn: true,
      },
    ],
  ],
});

const { argv } = require('yargs');

if (argv.scan) {
  require('./scanMismatch.js');
} else if (argv.generate) {
  require('./generateMissingPatch.js');
} else if (argv.try) {
  require('./try.js');
} else {
  console.log('look at ./scripts/index.js');
}
