import std.stdio;

import test.stringcanbenull;
int main(string[] argv)
{
    
    stringcanbenull test = new stringcanbenull;

    test.test();

    pause();
    return 0;
}

void pause()
{
    string line = stdin.readln();
}