import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { createRequire } from "node:module";

const require = createRequire("C:/Users/david/Documents/Development/Projects/afrobiomefoods/package.json");
const ts = require("typescript");

const androidRoot = "C:/Users/david/Documents/Development/Projects/afrobiomefoods";
const iosRoot = "C:/Users/david/Documents/Development/Projects/afrobiomefoods-ios";
const resourceDir = path.join(iosRoot, "IgboFoodHeritage", "Resources");
const imageDir = path.join(resourceDir, "Images");

function read(rel) {
  return fs.readFileSync(path.join(androidRoot, rel), "utf8");
}

function toScript(src) {
  const stripped = src
    .replace(/^import .*\r?\n/gm, "")
    .replace(/^export \{[\s\S]*?^};?\r?\n/m, "");
  const js = ts.transpileModule(stripped, {
    compilerOptions: {
      target: ts.ScriptTarget.ES2022,
      module: ts.ModuleKind.ESNext,
    },
  }).outputText;
  return js.replace(/\bexport (const|function|let|var)/g, "$1");
}

function run(src, names) {
  const sandbox = { console };
  vm.createContext(sandbox);
  vm.runInContext(`${src}\n${names.map((n) => `this.${n} = ${n};`).join("\n")}`, sandbox, {
    timeout: 15000,
  });
  const out = {};
  for (const name of names) out[name] = sandbox[name];
  return out;
}

function requires(src) {
  const map = {};
  const re = /"([^"]+)":\s*require\("([^"]+)"\)/g;
  let match;
  while ((match = re.exec(src))) {
    map[match[1]] = match[2];
  }
  return map;
}

function safeName(recipeId, role, sourcePath) {
  const ext = path.extname(sourcePath).toLowerCase() || ".jpg";
  return `${recipeId}-${role}${ext}`;
}

function copyAsset(relativeRequire, destName) {
  const rel = relativeRequire.replace(/^\.\.\/assets\//, "assets/");
  const from = path.join(androidRoot, rel);
  if (!fs.existsSync(from)) {
    throw new Error(`Missing image: ${from}`);
  }
  fs.copyFileSync(from, path.join(imageDir, destName));
}

const iconDir = path.join(iosRoot, "IgboFoodHeritage", "Assets.xcassets", "AppIcon.appiconset");
fs.mkdirSync(imageDir, { recursive: true });
fs.mkdirSync(iconDir, { recursive: true });

const finalMap = requires(read("data/recipeFinalImages.ts"));
const ingredientMap = requires(read("data/recipeIngredientImages.ts"));

let recipeSrc = toScript(read("data/recipes.ts"));
recipeSrc = recipeSrc.replace(/: Omit<Recipe, "ingredient_image">\[\]/g, "");
recipeSrc = recipeSrc.replace(/final_image:\s*recipeFinalImage\("[^"]+"\),?\r?\n/g, "");
recipeSrc = recipeSrc.split("const recipes")[0];
const { recipeCategories, recipeEntries } = run(recipeSrc, ["recipeCategories", "recipeEntries"]);

const recipes = recipeEntries.map((recipe) => {
  const finalRel = finalMap[recipe.recipe_id];
  const ingredientRel = ingredientMap[recipe.recipe_id];
  const finalName = finalRel ? safeName(recipe.recipe_id, "final", finalRel) : "app-icon.png";
  const ingredientName = ingredientRel
    ? safeName(recipe.recipe_id, "ingredient", ingredientRel)
    : "app-icon.png";
  if (finalRel) copyAsset(finalRel, finalName);
  if (ingredientRel) copyAsset(ingredientRel, ingredientName);
  return {
    ...recipe,
    final_image: finalName,
    ingredient_image: ingredientName,
  };
});

copyAsset("../assets/images/icon.png", "app-icon.png");
fs.copyFileSync(
  path.join(androidRoot, "assets/images/icon.png"),
  path.join(iconDir, "icon.png"),
);

const i18nSrc = toScript(read("lib/i18n.ts")).split("const dicts")[0];
const { en, ig, fr } = run(i18nSrc, ["en", "ig", "fr"]);

const nutritionSrc = toScript(read("data/nutrition.ts"));
const nutrition = run(nutritionSrc, ["conditionTopics", "ingredients", "mythFacts"]);

const servicesSrc = toScript(read("data/services.ts"));
const { services } = run(servicesSrc, ["services"]);

const communitySrc = toScript(read("data/community.ts"));
const { communityPosts } = run(communitySrc, ["communityPosts"]);

const catalog = {
  strings: { en, ig, fr },
  categories: recipeCategories,
  recipes,
  services,
  community: communityPosts,
  nutrition: {
    conditions: nutrition.conditionTopics,
    ingredients: nutrition.ingredients,
    myths: nutrition.mythFacts,
  },
};

fs.writeFileSync(path.join(resourceDir, "catalog.json"), JSON.stringify(catalog));
console.log(
  JSON.stringify({
    recipes: recipes.length,
    services: services.length,
    posts: communityPosts.length,
    conditions: nutrition.conditionTopics.length,
    stringKeys: Object.keys(en).length,
    images: fs.readdirSync(imageDir).length,
  }),
);
