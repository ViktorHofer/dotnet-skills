#!/usr/bin/env node

// Compiles skill content from src/plugins/msbuild-skills/skills/ into optimized
// knowledge files for the Copilot Extension to embed as system prompts.

const fs = require("node:fs");
const path = require("node:path");

const SKILLS_DIR = path.resolve(__dirname, "../../plugins/msbuild-skills/skills");
const OUTPUT_DIR = path.resolve(__dirname, "../src/knowledge");

// Mapping: knowledge file → skills to include
const KNOWLEDGE_MAP = {
  "build-errors": [
    "common-build-errors",
    "sourcegen-analyzer-failures",
    "nuget-restore-failures",
    "sdk-workload-resolution",
    "multitarget-tfm-issues",
    "ci-build-failures",
  ],
  performance: [
    "build-perf-baseline",
    "build-perf-diagnostics",
    "incremental-build",
    "build-parallelism",
    "build-caching",
    "eval-performance",
    "analyzer-performance",
  ],
  "style-guide": [
    "msbuild-style-guide",
    "msbuild-antipatterns",
    "directory-build-organization",
    "check-bin-obj-clash",
    "including-generated-files",
  ],
  modernization: ["msbuild-modernization", "directory-build-organization"],
};

// Maximum characters per knowledge file (to stay within token budgets)
const MAX_CHARS = 50000;

function readSkill(skillName) {
  const skillPath = path.join(SKILLS_DIR, skillName, "SKILL.md");
  if (!fs.existsSync(skillPath)) {
    console.warn(`  ⚠ Skill not found: ${skillName} (${skillPath})`);
    return null;
  }

  let content = fs.readFileSync(skillPath, "utf-8");

  // Strip YAML frontmatter
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
  if (frontmatterMatch) {
    content = content.slice(frontmatterMatch[0].length);
  }

  return content.trim();
}

function compileKnowledgeFile(outputName, skillNames) {
  console.log(`\nCompiling: ${outputName}.md`);

  const sections = [];
  let totalChars = 0;

  for (const skillName of skillNames) {
    const content = readSkill(skillName);
    if (!content) continue;

    // Check if adding this skill would exceed the limit
    if (totalChars + content.length > MAX_CHARS) {
      console.warn(
        `  ⚠ Truncating ${skillName} — would exceed ${MAX_CHARS} char limit`
      );
      const remaining = MAX_CHARS - totalChars;
      if (remaining > 500) {
        // Include a truncated version
        sections.push(
          `## ${skillName}\n\n${content.slice(0, remaining)}\n\n[truncated]`
        );
        totalChars += remaining;
      }
      break;
    }

    sections.push(content);
    totalChars += content.length;
    console.log(
      `  ✓ ${skillName} (${content.length.toLocaleString()} chars)`
    );
  }

  const output = sections.join("\n\n---\n\n");
  const outputPath = path.join(OUTPUT_DIR, `${outputName}.md`);
  fs.writeFileSync(outputPath, output, "utf-8");
  console.log(
    `  → ${outputPath} (${output.length.toLocaleString()} chars total)`
  );
}

// Main
function main() {
  console.log("MSBuild Copilot Extension — Knowledge Compiler");
  console.log(`Skills source: ${SKILLS_DIR}`);
  console.log(`Output: ${OUTPUT_DIR}`);

  // Verify skills directory exists
  if (!fs.existsSync(SKILLS_DIR)) {
    console.error(`ERROR: Skills directory not found: ${SKILLS_DIR}`);
    console.error("Make sure you're running from the copilot-extension/ directory.");
    process.exit(1);
  }

  // Create output directory
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  // Compile each knowledge file
  for (const [outputName, skillNames] of Object.entries(KNOWLEDGE_MAP)) {
    compileKnowledgeFile(outputName, skillNames);
  }

  console.log("\n✅ Knowledge compilation complete.");
}

main();
