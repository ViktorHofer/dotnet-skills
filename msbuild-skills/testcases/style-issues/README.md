# Style Issues — Code Review Test

Two projects with multiple MSBuild anti-patterns for testing `msbuild-style-guide` and `directory-build-organization` skills.

## Issues Present

1. **Duplicated properties** across LibA and LibB (LangVersion, Nullable, Company, etc.)
2. **Hardcoded absolute paths** for OutputPath
3. **Unquoted conditions** (`$(Configuration) == Debug` should be `'$(Configuration)' == 'Debug'`)
4. **Explicit Compile includes** (SDK handles this automatically)
5. **`<Reference>` with HintPath** instead of `<PackageReference>`
6. **`<Exec>` for simple operations** (Message task would be better)
7. **No Directory.Build.props** to centralize shared settings
8. **No Central Package Management**

## Skills Tested

- `msbuild-style-guide` — Style violations and anti-patterns
- `directory-build-organization` — Missing centralization
- `msbuild-code-review` agent — Full automated review

## How to Test

Ask the AI: "Review these project files for best practices"
Or: "Set up Directory.Build.props for this solution"
