namespace TypeMismatch;

public class Calculator
{
    // CS0029: Cannot implicitly convert type 'string' to 'int'
    public int Add(string a, string b)
    {
        int result = a + b;
        return result;
    }

    // CS8600: Converting null literal to non-nullable type
    public string GetName()
    {
        string name = null;
        return name;
    }
}
