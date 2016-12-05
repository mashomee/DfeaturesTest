module test.firstParameter;

import test.Test;

class firstParameter : Test
{
    override public void test()
    {
        8.testUint();
        100.mySeconds();
    }
}

void testUint(uint uInt)
{
    import std.conv;
    writeln("in testUint!" ~ to!string(uInt));
}

void mySeconds(int Int)
{
    import std.format;
    writeln(format("%d seconds in mySeconds!", Int));
}