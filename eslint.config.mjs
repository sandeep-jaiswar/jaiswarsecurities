
import globals from "globals";
import tseslint from "typescript-eslint";
import nodePlugin from "eslint-plugin-node";
import nextPlugin from "@next/eslint-plugin-next";
import prettierConfig from "eslint-config-prettier";
import tsPlugin from "@typescript-eslint/eslint-plugin";

export default tseslint.config(
  {
    ignores: [
      ".git/",
      "node_modules/",
      "dist/",
      "build/",
      "client/.next/",
      "coverage/",
      "*.min.js",
      "*.d.ts",
    ],
  },
  {
    plugins: {
      "@typescript-eslint": tsPlugin,
    },
  },
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        project: true,
      },
      globals: {
        ...globals.node,
      },
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,
    }
  },
  {
    files: ["client/**/*.ts", "client/**/*.tsx"],
    languageOptions: {
      globals: {
        ...globals.browser,
      },
    },
    plugins: {
      "@next/next": nextPlugin,
    },
    rules: {
      ...nextPlugin.configs.recommended.rules,
      ...nextPlugin.configs["core-web-vitals"].rules,
      "@next/next/no-html-link-for-pages": "off",
    },
  },
  {
    files: ["services/**/*.ts"],
    plugins: {
      node: nodePlugin,
    },
    rules: {
      ...nodePlugin.configs.recommended.rules,
    },
  },
  {
    rules: {
      ...prettierConfig.rules,
      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
    },
  },
);
