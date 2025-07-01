import eslintPluginNext from "@next/eslint-plugin-next"
import eslintPluginImport from "eslint-plugin-import"
import eslintPluginStorybook from "eslint-plugin-storybook"
import typescriptEslint from "typescript-eslint"
import * as fs from "fs"

const eslintIgnore = [
  ".git/",
  ".next/",
  "node_modules/",
  "dist/",
  "build/",
  "coverage/",
  "tests/",
  "services/",
  "*.min.js",
  "*.config.js",
  "*.d.ts",
]

const config = typescriptEslint.config(
  {
    ignores: eslintIgnore,
  },
  ...eslintPluginStorybook.configs["flat/recommended"],
  typescriptEslint.configs.recommended,
  eslintPluginImport.flatConfigs.recommended,
  {
    plugins: {
      "@next/next": eslintPluginNext,
    },
    rules: {
      ...eslintPluginNext.configs.recommended.rules,
      ...eslintPluginNext.configs["core-web-vitals"].rules,
      "@next/next/no-html-link-for-pages": "off", // ✅ Disable classic pages dir warning
      "@next/next/no-duplicate-head": "off", // ✅ Disable duplicate head warning
    },
  },
  {
    settings: {
      tailwindcss: {
        callees: ["classnames", "clsx", "ctl", "cn", "cva"],
      },
      "import/resolver": {
        typescript: true,
        node: true,
      },
    },
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
      "sort-imports": [
        "error",
        {
          ignoreCase: true,
          ignoreDeclarationSort: true,
        },
      ],
      "import/order": [
        "warn",
        {
          groups: ["external", "builtin", "internal", "sibling", "parent", "index"],
          pathGroups: [
            ...getDirectoriesToSort().map((singleDir) => ({
              pattern: `${singleDir}/**`,
              group: "internal",
            })),
            { pattern: "env", group: "internal" },
            { pattern: "theme", group: "internal" },
            { pattern: "public/**", group: "internal", position: "after" },
          ],
          pathGroupsExcludedImportTypes: ["internal"],
          alphabetize: {
            order: "asc",
            caseInsensitive: true,
          },
        },
      ],
    },
  }
)

function getDirectoriesToSort() {
  const ignoredSortingDirectories = [".git", ".next", ".vscode", "node_modules"]
  return fs
    .readdirSync(process.cwd())
    .filter((file) => fs.statSync(`${process.cwd()}/${file}`).isDirectory())
    .filter((f) => !ignoredSortingDirectories.includes(f))
}

export default config
