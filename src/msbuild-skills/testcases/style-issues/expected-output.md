# Expected Findings: style-issues

## Problem Summary
A solution with two projects (LibA, LibB) containing multiple MSBuild anti-patterns and style violations.

## Expected Findings

### 1. Hardcoded Absolute Paths
- **Issue**: Both LibA and LibB use hardcoded absolute paths for OutputPath (e.g., `C:\Build\Output\`)
- **Solution**: Use relative paths or MSBuild properties like `$(ArtifactsPath)`

### 2. Unquoted Condition
- **Issue**: MSBuild condition uses unquoted comparison (`$(Configuration) == Debug` instead of `'$(Configuration)' == 'Debug'`)
- **Solution**: Quote both sides of the condition

### 3. Duplicated Properties Across Projects
- **Issue**: LangVersion, Nullable, Company, and other properties are duplicated identically in both LibA.csproj and LibB.csproj
- **Solution**: Extract shared properties into a `Directory.Build.props` file

### 4. Explicit Compile Includes
- **Issue**: Files are listed explicitly with `<Compile Include="...">` in SDK-style project
- **Solution**: Remove — SDK-style projects use implicit globbing

### 5. Reference Instead of PackageReference
- **Issue**: NuGet package referenced using old-style `<Reference>` with `<HintPath>` instead of `<PackageReference>`
- **Solution**: Replace with `<PackageReference Include="..." Version="..." />`

### 6. Exec Instead of Built-in Task
- **Issue**: `<Exec Command="mkdir ...">` used where MSBuild's built-in `<MakeDir>` task would be more appropriate
- **Solution**: Replace with `<MakeDir Directories="..." />`

### 7. No Directory.Build.props
- **Issue**: No centralized build properties file exists for the solution
- **Solution**: Create `Directory.Build.props` with shared settings

## Key Concepts That Should Be Mentioned
- Directory.Build.props for centralized settings
- MSBuild condition quoting rules
- SDK-style implicit globbing
- PackageReference vs Reference
- Built-in MSBuild tasks vs Exec
- Cross-platform path handling
