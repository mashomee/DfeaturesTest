import std.stdio;

import test.Test;
import test.stringcanbenull;
import test.JSONObjectKeyIn;
import test.structArrayInit;
import test.scopeOrder;
import test.testTemplate;

int main(string[] argv)
{

    try
    {
        Test test = new testTemplate;

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

