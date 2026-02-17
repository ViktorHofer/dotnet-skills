using System;

namespace MissingReference;

public class DataProcessor
{
    // CS0246: The type or namespace name 'JsonSerializer' could not be found
    // Fix: Add <PackageReference Include="System.Text.Json" />
    public string Serialize(object data)
    {
        return System.Text.Json.JsonSerializer.Serialize(data);
    }

    // CS0246: The type or namespace name 'ILogger' could not be found
    // Fix: Add <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />
    public void Process(Microsoft.Extensions.Logging.ILogger logger)
    {
        logger.LogInformation("Processing");
    }
}
