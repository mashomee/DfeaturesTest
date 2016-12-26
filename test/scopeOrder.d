module test.scopeOrder;

import test.Test;

//scope中的success exit failure, 首先按照成功、失败分成两组
//然后每组按照代码中的顺序逆序执行
class scopeOrder : Test
{
    public override void test()
    {
        string scopeExit;
        string scopeSuccess;

        {
            scope(failure)
            {
                writeln("scope failure 1");
            }

            scope(failure)
            {
                writeln("scope failure 2");
            }

            scope(exit)
            {
                writeln("scope exit 1");
                scopeExit ~= "1";
            }

            scope(exit)
            {
                writeln("scope exit 2");
                scopeExit ~= "2";
            }

            scope(failure)
            {
                writeln("scope failure 3");
            }


            scope(success)
            {
                writeln("scope success 1");
                scopeSuccess ~= "1";
            }

            scope(success)
            {
                writeln("scope success 2");
                scopeSuccess ~= "2";
            }

            scope(success)
            {
                writeln("scope success 3");
                scopeSuccess ~= "3";
            }

            scope(exit)
            {
                writeln("scope exit 3");
                scopeExit ~= "3";
            }

            throw new Throwable("Test scopeOrder");
        }

        if(scopeExit == "123")
        {
            writeln("scope exit in proper order");
        }
        else if(scopeExit == "321")
        {
            writeln("scope exit in reverse order");
        }
        else 
        {
            writeln("scope exit in chaos order");
        }

        if(scopeSuccess == "123")
        {
            writeln("scope success in proper order");
        }
        else if(scopeSuccess == "321")
        {
            writeln("scope success in reverse order");
        }
        else 
        {
            writeln("scope success in chaos order");
        }
    }
}