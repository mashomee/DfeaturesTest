import std.stdio;

import test.Test;
import test.stringcanbenull;
import test.JSONObjectKeyIn;
import test.structArrayInit;

int main(string[] argv)
{
    
    Test test = new structArrayInit;

    test.test();

    pause();
    return 0;
}

void pause()
{
    string line = stdin.readln();
}

