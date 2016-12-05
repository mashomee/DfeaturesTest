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

int main(string[] argv)
{

    try
    {
        Test test = new firstParameter;

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

