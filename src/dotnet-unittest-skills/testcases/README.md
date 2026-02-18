# Dotnet-Unittest-Skills Evaluation Testcases

These scenarios evaluate the `dotnet-unittest` skill's ability to generate high-quality unit tests.

## Scenarios

| Scenario | Framework | Complexity | Key Test Aspects |
|----------|-----------|------------|-----------------|
| `calculator-xunit` | xUnit | Simple (no deps) | `[Fact]`/`[Theory]`, `Assert.Throws<T>`, checked overflow, parameterized testing |
| `order-service-mstest` | MSTest | Complex (DI + async) | `[TestClass]`/`[TestMethod]`, Moq mocking, async patterns, business rule validation |

## How It Works

Each scenario provides:
- A production C# project with classes to test
- A test project with the framework referenced but **no test code**
- An `eval-test-prompt.txt` asking Copilot to generate unit tests
- An `expected-output.md` rubric used to grade the response

The evaluation pipeline runs each scenario with vanilla Copilot (no plugins) and with the `dotnet-unittest-skills`
plugin installed, then uses an LLM-as-judge to score both responses against the rubric.
