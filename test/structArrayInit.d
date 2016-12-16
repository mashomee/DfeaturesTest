module test.structArrayInit;

import test.Test;

class structArrayInit : Test
{
    override public void test() {
    
        mFoo[]  foos = [mFoo("a", true), mFoo("b", false)];
        writefln("mFoo[] length:%d", foos.length);
        writefln("name:%s, bool:%d", foos[0].colName, foos[0].urlEncode);
        writefln("name:%s, bool:%d", foos[1].colName, foos[1].urlEncode);
    }
    
}

struct mFoo
{
    string colName;
    bool urlEncode;
}