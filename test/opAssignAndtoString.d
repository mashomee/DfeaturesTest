module test.opAssignAndtoString;

import test.Test;

class opAssignAndtoString : Test
{
     override public void test()
    {
        MyTest a = new MyTest();
        MyTest b = new MyTest();
        a.i = 1;
        a.j = 2;
        a.k = 3.14;

        b = a;

        writeln(a);
        writeln(b);
    }
}





class MyTest
{
    import std.stdio;
    import std.string;
    import std.conv;
    import std.uuid;
    import std.datetime;
    import std.signals;
    import std.json;
    import std.file;
    import std.outbuffer;
public:
    int i;
    int j;
    float k;
    //++错误	1	Error: class  identity assignment operator overload is illegal
    /++
    public void opAssign(MyTest rh)
    {
        this.j = rh.i;
        this.i = rh.j;
        this.k = rh.k;
    }
    ++/
    override string toString() {
        OutBuffer buffer = new OutBuffer;
        buffer.writefln("i:%d,j:%d,k:%f", i,j,k);
        return buffer.toString();
    }

}
