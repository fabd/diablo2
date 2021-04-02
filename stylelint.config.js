module.exports = {
  extends: [
    // note this already extends `stylelint-config-recommended`
    "stylelint-config-recommended-scss",
    // add this last! turns off all the rules that conflict with Prettier
    "stylelint-config-prettier",
  ],

  rules: {
    "block-no-empty": null,
    "color-hex-length": null,
    "comment-empty-line-before": null,
    "declaration-empty-line-before": null,
    "no-descending-specificity": null,
  },
};
