import std.stdio;

import test.Test;
import test.stringcanbenull;
import test.JSONObjectKeyIn;
import test.structArrayInit;
import test.scopeOrder;
import test.testTemplate;
import test.JSONInitType;
import test.DiffCstringDstring;
import test.opAssignAndtoString;
import test.firstParameter;
import std.string;
import std.array;
//import test.testSortAArray;
import test.testdebugFacility;

int main(string[] argv)
{

    try
    {
        Test test = new testdebugFacility;
        //testHere();
        test.test();
    }
    catch(Throwable error)
    {
        writeln(error.toString());
    }

    pause();
    return 0;
}

void pause()
{
    string line = stdin.readln();
}

void testHere()
{
    string testStr = "afecda-asdf;";
    testStr = replace(testStr, ";", "','");
    writeln(format("sql in list: '%s'", testStr));
}
