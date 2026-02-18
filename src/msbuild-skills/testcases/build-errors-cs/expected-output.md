# Expected Findings: build-errors-cs

## Problem Summary
Two .NET projects fail to build due to C# compilation errors.

## Expected Findings

### 1. MissingReference.csproj — Missing Package References
- **Issue**: Code uses `System.Text.Json.JsonSerializer` and `Microsoft.Extensions.Logging.ILogger` without the required NuGet package references
- **Error codes**: CS0246 (type or namespace not found)
- **Solution**: Add `<PackageReference Include="System.Text.Json" />` and `<PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />` to the .csproj

### 2. TypeMismatch.csproj — Type Errors
- **Issue**: Code contains a string-to-int assignment and a null-to-non-nullable assignment
- **Error codes**: CS0029 (cannot implicitly convert type), CS8600 (converting null to non-nullable)
- **Solution**: Fix the type assignments in the source code

## Key Concepts That Should Be Mentioned
- CS0246 error and missing PackageReference as root cause
- CS0029 implicit conversion error
- CS8600 nullable reference type warning/error
- How to add PackageReference to resolve missing types

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Identified CS0246 error in MissingReference project
- [ ] Mentioned System.Text.Json as missing package
- [ ] Mentioned Microsoft.Extensions.Logging.Abstractions as missing package
- [ ] Provided correct PackageReference XML for both packages
- [ ] Identified CS0029 in TypeMismatch (type conversion error)
- [ ] Identified CS8600 in TypeMismatch (nullable reference)
- [ ] Explained root cause (string-to-int assignment)
- [ ] Provided correct code fix for type mismatch
- [ ] Mentioned PackageReference as the mechanism to resolve missing types
- [ ] All solutions preserve existing code logic

Total: __/10

## Expected Skills
- common-build-errors
