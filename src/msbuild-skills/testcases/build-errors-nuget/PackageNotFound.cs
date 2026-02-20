using Newtonsoft.Json;

namespace PackageNotFound;

public class Placeholder
{
    public string Serialize() => JsonConvert.SerializeObject(new { Name = "test" });
}
