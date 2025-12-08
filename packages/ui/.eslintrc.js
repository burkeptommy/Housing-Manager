module.exports = {
  extends: [require.resolve('@haven/config/eslint/react')],
  parserOptions: {
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
  },
};
