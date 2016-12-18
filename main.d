import std.stdio;

import test.stringcanbenull;
import test.JSONObjectKeyIn;

int main(string[] argv)
{
    
    JSONObjectKeyIn test = new JSONObjectKeyIn;

    test.test();

    pause();
    return 0;
}

void pause()
{
    string line = stdin.readln();
}

