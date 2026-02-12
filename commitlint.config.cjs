module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'perf',
        'refactor',
        'docs',
        'ci',
        'test',
        'chore'
      ]
    ],
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [0],
  },
};
