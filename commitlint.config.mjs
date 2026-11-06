// Commit message rules for pull requests (commitlint.yml): Conventional Commits, see
// README, section "CI und Releases". Bodies are written as one sentence per line, so their
// line length is not limited.
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'body-max-line-length': [0],
    'footer-max-line-length': [0],
  },
};
