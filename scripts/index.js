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

require('./scanMismatch.js');
