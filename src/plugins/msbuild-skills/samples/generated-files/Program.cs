namespace GeneratedFiles;

public class App
{
    public static void Main()
    {
        // This will fail with CS0103 because VersionInfo is generated
        // but not included in the Compile items
        System.Console.WriteLine(VersionInfo.Version);
    }
}
