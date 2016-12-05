module test.DiffCstringDstring;
import test.Test;
import std.string;
import std.stdio;
import std.conv;

class DiffCstringDstring : Test
{
    override public void test() {
        import core.stdc.string : strlen;
        string abc = "abc";    
        const char* Cabc = std.string.toStringz(abc);

        writeln(abc);
        writeln("length of abc:" ~ to!string(abc.length));
        writeln("abc.sizeof:" ~ to!string(abc.sizeof));
        outputByte(abc.ptr);
        writeln(Cabc);
        writeln("Cabc.sizeof:" ~ to!string(Cabc.sizeof));
        outputByte(Cabc);
        writeln(cast(int)Cabc[0]);
    }
    
    void outputByte(void* ptr)
    {
        outputByte(cast(const(void*))ptr);
    }

    void outputByte(const void* ptr)
    {
        void * myptr = cast(void *)ptr;
        writeln("begin output:");
        writeln(myptr);
        while(!myptr++)
        {
            ubyte thisByte = *(cast(ubyte*)myptr);
            write(thisByte);
            write( "|");
            writeln();
        }
        writeln("end output.");
    }
}