# Template Engine Skills — Evaluation Testcases

Scenarios for measuring whether the template-engine-skills plugin (with DotnetTemplateMCP) improves Copilot's responses compared to vanilla Copilot.

## Scenarios

| Testcase | What It Tests | Key MCP Advantage |
|----------|--------------|-------------------|
| [`create-webapi-auth`](create-webapi-auth/) | Create a Web API with specific parameters (auth, controllers, HTTPS) | `template_from_intent` + `template_instantiate` with validation and smart defaults |
| [`cpm-add-project`](cpm-add-project/) | Add a project to a CPM-enabled solution | Automatic CPM detection, version stripping, Directory.Packages.props updates |
| [`scaffold-solution`](scaffold-solution/) | Create multi-project solution (API + classlib + tests) | `template_compose` for orchestrated multi-template workflows |
| [`find-right-template`](find-right-template/) | Find the right template for a vague requirement | `template_search` with live NuGet data vs. training-data guessing |
| [`inspect-template-params`](inspect-template-params/) | Show all parameters and constraints for a template | `template_inspect` with live structured metadata vs. hallucinated params |

## How It Works

Each scenario is run twice through Copilot CLI:
1. **Vanilla** — No plugins, Copilot on its own
2. **Skilled** — With the `template-engine-skills` plugin (including MCP server)

Both outputs are scored against the `expected-output.md` rubric (Accuracy, Completeness, Actionability, Clarity — each 0–10).

## Running

See [eng/evaluation/README.md](../../../eng/evaluation/README.md) for pipeline setup and execution instructions.
