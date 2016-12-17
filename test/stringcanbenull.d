module test.stringcanbenull;

import std.string;
import std.stdio;
import std.conv;

class stringcanbenull
{
    public void test()
    {
        string a = "";
        string b = null;
        string c;
        
        writefln("string a = \"\"; => value:%s", valueIs(a));
        writefln("string b = null; => value:%s", valueIs(b));
        writefln("string c; => value:%s", valueIs(c));

        //string is array of char, so dynamic array is null if not initialized.
        writeln("----------------------dynamic array---------------------------");
        int[] aryIntA = [];
        int[] aryIntB = null;
        int[] aryIntC;
        int[] aryIntD = [1];
        aryIntD.length = 0;

        writefln("int[] aryIntA = []; => value:%s", valueIs(aryIntA));
        writefln("int[] aryIntB = null; => value:%s", valueIs(aryIntB));
        writefln("int[] aryIntC; => value:%s", valueIs(aryIntC));
        writefln("int[] aryIntD = [1]; => value:%s\naryIntD.length = 0;", valueIs(aryIntD));

        writeln("----------------------static array---------------------------");
        //int[0] aryIntE = [];
        //int[1] aryIntF = null;
        int[2] aryIntG;
        int[2] aryIntH = [0,1];
        writefln("int[0] aryIntE = []; => value:%s", "illegal");
        writefln("int[1] aryIntF = null; => value:%s", "illegal");
        writefln("int[2] aryIntG; => value:%s", valueIs(aryIntG));
        writefln("int[2] aryIntH = [0,1];; => value:%s", valueIs(aryIntG));
    }

    private string valueIs(string str)
    {
        if(str is null)
        {
            return "null";
        }
        else if(str == "")
        {
            return "\"\"(empty)";
        }
        else
        {
            return str.idup;
        }
    }

    private string valueIs(int[] aryInt)
    {
        if(aryInt is null)
        {
            return "null";
        }
        else if(aryInt == [])
        {
            return "[](empty)";
        }
        else
        {
            return "size:" ~ to!string(aryInt.length);
        }
    }
}