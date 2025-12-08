module.exports = {
  extends: [require.resolve('@haven/config/eslint/react')],
  parserOptions: {
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
  },
  rules: {
    'react/react-in-jsx-scope': 'off',
  },
  ignorePatterns: ['.expo', 'node_modules', 'babel.config.js'],
};
