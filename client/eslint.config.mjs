
import globals from "globals";
import tseslint from "typescript-eslint";
import pluginImport from "eslint-plugin-import";
import nextPlugin from "@next/eslint-plugin-next";

export default tseslint.config(
  {
    ignores: [
      ".git/",
      ".next/",
      "node_modules/",
      "dist/",
      "build/",
      "coverage/",
      "*.min.js",
      "*.config.js",
      "*.d.ts",
    ],
  },
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
  },
  ...tseslint.configs.recommended,
  {
    plugins: {
      "@next/next": nextPlugin,
    },
    rules: {
      ...nextPlugin.configs.recommended.rules,
      ...nextPlugin.configs["core-web-vitals"].rules,
    },
  },
  {
    plugins: {
        import: pluginImport
    },
    settings: {
      "import/resolver": {
        typescript: true,
        node: true,
      },
    },
    rules: {
      "import/order": [
        "warn",
        {
          "groups": ["external", "builtin", "internal", "sibling", "parent", "index"],
          "alphabetize": {
            order: "asc",
            caseInsensitive: true,
          },
        },
      ],
      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
    },
  }
);
