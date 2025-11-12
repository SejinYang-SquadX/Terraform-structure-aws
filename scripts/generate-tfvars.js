#!/usr/bin/env node
/**
 * Generates a tfvars file by reading variable defaults from variables.tf.
 * Usage: npm run generate:tfvars -- [output tfvars path]
 */
import fs from "fs";
import path from "path";
import process from "process";
import { fileURLToPath } from "url";
import hcl from "hcl2-parser";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const variablesPath = path.join(repoRoot, "variables.tf");
const defaultOutput = path.join(repoRoot, "env", "dev.tfvars");

const args = process.argv.slice(2);
const forceIndex = args.indexOf("--force");
const force = forceIndex !== -1;
if (force) {
  args.splice(forceIndex, 1);
}
const outputPath = path.resolve(args[0] ?? defaultOutput);

if (!fs.existsSync(variablesPath)) {
  console.error(`variables.tf not found at ${variablesPath}`);
  process.exit(1);
}

if (fs.existsSync(outputPath) && !force) {
  console.error(`Refusing to overwrite existing file: ${outputPath}`);
  console.error("Pass --force if you really want to replace it.");
  process.exit(1);
}

const hclSource = fs.readFileSync(variablesPath, "utf8");
const parsed = hcl.parseToObject(hclSource);
const variableBlocks = parsed.variable ?? {};
const lines = [];

for (const [name, attributes] of Object.entries(variableBlocks)) {
  const description = attributes.description;
  const defaultValue = attributes.default;
  const renderedValue = renderValue(defaultValue);
  const header = description ? `# ${description}\n` : "";
  const value = renderedValue ?? "\"<fill-me>\"";
  lines.push(`${header}${name} = ${value}`);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${lines.join("\n\n")}\n`);
console.log(`Generated ${path.relative(repoRoot, outputPath)}`);

function renderValue(value) {
  if (value === undefined) {
    return null;
  }
  if (value === null) {
    return "null";
  }
  if (typeof value === "string") {
    return JSON.stringify(value);
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  if (Array.isArray(value)) {
    const items = value.map((item) => renderValue(item) ?? "null");
    return `[${items.join(", ")}]`;
  }
  if (typeof value === "object") {
    const entries = Object.entries(value).map(
      ([key, val]) => `  ${key} = ${renderValue(val) ?? "null"}`
    );
    return `{\n${entries.join("\n")}\n}`;
  }
  return null;
}
