module test.AssociateArrayInitialization;

import test.Test;
import core.stdc.time;
import std.datetime;
import std.conv;

class AssociateArrayInitialization : Test
{
    override public void test()
    {
        string unixTime = to!string(time(null));
        ulong[string] map;
        ulong count;
        try
        {
            map[unixTime]++;//this form is OK
            count = map[unixTime];
        }
        catch(Throwable err)
        {
            writeln(err.toString());
        }

        ulong[string] countMap;

        try
        {
            writefln("wrong error:%d", countMap[unixTime]); //will throw an error
        }
        catch(Throwable err)
        {
            writeln(err.toString());
        }

        writefln("time[%s], count[%d]", unixTime, count + 1);

    }
}