#!/usr/bin/env node

// Shared knowledge compiler for the MSBuild skills repository.
// Compiles skill SKILL.md files into knowledge bundles for different consumers:
//   - Copilot Extension (src/copilot-extension/src/knowledge/)
//   - Agentic Workflows (src/msbuild-skills/templates/agentic-workflows/shared/)
//
// Usage: node scripts/compile-knowledge.js

const fs = require("node:fs");
const path = require("node:path");

const SKILLS_DIR = path.resolve(__dirname, "../src/msbuild-skills/skills");

// Output targets — each target gets its own set of knowledge files
const TARGETS = {
  "copilot-extension": {
    outputDir: path.resolve(__dirname, "../src/copilot-extension/src/knowledge"),
    maxChars: 50000,
    knowledgeMap: {
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
      ],
      "style-guide": [
        "msbuild-style-guide",
        "msbuild-antipatterns",
        "directory-build-organization",
        "check-bin-obj-clash",
        "including-generated-files",
      ],
      modernization: [
        "msbuild-modernization",
        "directory-build-organization",
      ],
    },
  },
  "agentic-workflows": {
    outputDir: path.resolve(
      __dirname,
      "../src/msbuild-skills/templates/agentic-workflows/shared/compiled"
    ),
    maxChars: 40000, // gh aw has tighter context budgets
    knowledgeMap: {
      "build-failure-knowledge": [
        "common-build-errors",
        "sourcegen-analyzer-failures",
        "nuget-restore-failures",
        "sdk-workload-resolution",
        "binlog-failure-analysis",
      ],
      "pr-review-knowledge": [
        "msbuild-antipatterns",
        "msbuild-style-guide",
        "msbuild-modernization",
        "directory-build-organization",
        "check-bin-obj-clash",
        "incremental-build",
      ],
      "perf-audit-knowledge": [
        "build-perf-baseline",
        "build-perf-diagnostics",
        "incremental-build",
        "build-parallelism",
        "build-caching",
        "eval-performance",
      ],
    },
  },
};

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

function compileKnowledgeFile(outputName, skillNames, outputDir, maxChars) {
  const ext = ".lock.md";
  console.log(`  Compiling: ${outputName}${ext}`);

  const sections = [];
  let totalChars = 0;

  const header = `<!-- AUTO-GENERATED — DO NOT EDIT. Regenerate with: node eng/compile-knowledge.js -->\n\n`;
  totalChars += header.length;

  for (const skillName of skillNames) {
    const content = readSkill(skillName);
    if (!content) continue;

    if (totalChars + content.length > maxChars) {
      console.warn(
        `    ⚠ Truncating ${skillName} — would exceed ${maxChars} char limit`
      );
      const remaining = maxChars - totalChars;
      if (remaining > 500) {
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
      `    ✓ ${skillName} (${content.length.toLocaleString()} chars)`
    );
  }

  const output = header + sections.join("\n\n---\n\n");
  const outputPath = path.join(outputDir, `${outputName}${ext}`);
  fs.writeFileSync(outputPath, output, "utf-8");
  console.log(
    `    → ${outputName}${ext} (${output.length.toLocaleString()} chars total)`
  );
}

function compileTarget(targetName, config) {
  console.log(`\n📦 Target: ${targetName}`);
  console.log(`   Output: ${config.outputDir}`);

  fs.mkdirSync(config.outputDir, { recursive: true });

  for (const [outputName, skillNames] of Object.entries(config.knowledgeMap)) {
    compileKnowledgeFile(
      outputName,
      skillNames,
      config.outputDir,
      config.maxChars
    );
  }
}

// Main
function main() {
  console.log("MSBuild Skills — Knowledge Compiler");
  console.log(`Skills source: ${SKILLS_DIR}`);

  if (!fs.existsSync(SKILLS_DIR)) {
    console.error(`ERROR: Skills directory not found: ${SKILLS_DIR}`);
    process.exit(1);
  }

  // Compile a specific target or all targets
  const targetArg = process.argv[2];
  if (targetArg) {
    if (!TARGETS[targetArg]) {
      console.error(`ERROR: Unknown target '${targetArg}'`);
      console.error(`Available targets: ${Object.keys(TARGETS).join(", ")}`);
      process.exit(1);
    }
    compileTarget(targetArg, TARGETS[targetArg]);
  } else {
    for (const [name, config] of Object.entries(TARGETS)) {
      compileTarget(name, config);
    }
  }

  console.log("\n✅ Knowledge compilation complete.");
}

main();
