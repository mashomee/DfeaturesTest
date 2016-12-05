module test.firstParameter;

import test.Test;
import std.variant;
import std.format;

class firstParameter : Test
{
    override public void test()
    {
        8.testUint();
        100.mySeconds();
        test2();
    }

    public void test2()
    {
        string op = "[+]";
        string tryUseType(string tp)
        {
            import std.format : format;
            return q{
                static if (allowed!%1$s && T.allowed!%1$s)
                    if (convertsTo!%1$s && other.convertsTo!%1$s)
                        return VariantN(get!%1$s %2$s other.get!%1$s);
            }.format(tp, op);
        }

        void test3()
        {
            auto outFile = File("C:\\Users\\s-pc\\Desktop\\qqqqW.txt", "w");

            try{
                string test = "testFormat:%1$s, %2$s, %3$d, %1$s".format("1", "22", 333);
                outFile.writeln(test);
                writeln(test.idup);
            }catch(Throwable error)
            {
                writeln(error.msg);
            }
            outFile.writeln(tryUseType("uint"));
            outFile.writeln(tryUseType("int"));
            outFile.writeln(tryUseType("ulong"));
            outFile.writeln(tryUseType("long"));
            outFile.writeln(tryUseType("float"));
            outFile.writeln(tryUseType("double"));
            outFile.writeln(tryUseType("real"));
        }

                test3();
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