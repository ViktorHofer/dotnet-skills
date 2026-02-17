#!/usr/bin/env node

// Validates that all SKILL.md files follow repository conventions.
// Run: node eng/validate-skills.js

const fs = require("node:fs");
const path = require("node:path");

const SKILLS_DIR = path.resolve(__dirname, "../src/msbuild-skills/skills");
const DOMAIN_GATE_PATTERN = /Only activate in MSBuild\/\.NET build contexts/;

let errors = 0;

// Find all SKILL.md files (skip shared/)
const skillDirs = fs.readdirSync(SKILLS_DIR, { withFileTypes: true })
  .filter(d => d.isDirectory() && d.name !== "shared");

for (const dir of skillDirs) {
  const skillFile = path.join(SKILLS_DIR, dir.name, "SKILL.md");
  if (!fs.existsSync(skillFile)) continue;

  const content = fs.readFileSync(skillFile, "utf-8");

  // Extract description from YAML frontmatter
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) {
    console.error(`❌ ${dir.name}: Missing YAML frontmatter`);
    errors++;
    continue;
  }

  const frontmatter = match[1];
  const descMatch = frontmatter.match(/description:\s*"([^"]*)"/);
  if (!descMatch) {
    console.error(`❌ ${dir.name}: Missing description in frontmatter`);
    errors++;
    continue;
  }

  const description = descMatch[1];
  if (!DOMAIN_GATE_PATTERN.test(description)) {
    console.error(`❌ ${dir.name}: Description missing domain gate. Must include 'Only activate in MSBuild/.NET build contexts (see shared/domain-check.md for signals).'`);
    errors++;
  }
}

if (errors > 0) {
  console.error(`\n${errors} validation error(s) found.`);
  process.exit(1);
} else {
  console.log(`✅ All ${skillDirs.length} skills pass validation.`);
}
