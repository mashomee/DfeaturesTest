module test.testTemplate;

import test.Test;
import std.file;
import std.conv;

class testTemplate : Test
{
    public override void test() {
        File outFile = File("testTemplate.txt", "w");
        outFile.write(BindCharColumn!(1, "VaraibleName", 999));
        outFile.writeln();
        outFile.write(getColumnStringValue!("VaraibleName", 999));
    }
    
}

template BindCharColumn( int colIdx, string OutvariableName, int colLen)
{
    static assert(colIdx > 0);
    static assert(colLen > 0);
    const string Idx = to!string(colIdx);
    const string Len = to!string(colLen);

    const string variableName = "sz" ~ OutvariableName;
    const string declaration = "scope char["~Len~"] " ~variableName~";";
    const string declarationLen = "int "~variableName~"Len;";
    const string binding = "SQLBindCol(hstmt, "~Idx~", SQL_C_CHAR, cast(char *)"~variableName~", "~Len~", &"~variableName~"Len);";
    const string BindCharColumn = declaration ~ declarationLen ~ binding;
}

template getColumnStringValue(string variableName, int colLen)
{
    static assert(colLen > 0);
    const string Len = to!string(colLen);

    const string getColumnStringValue = " getRightStringValue(sz"~variableName~", " ~ Len ~ ", sz"~variableName~"Len)";
}