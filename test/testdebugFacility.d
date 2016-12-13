module test.testdebugFacility;

import test.Test;


class testdebugFacility : Test
{
    override public void test() {
        testB(1);
        testB(2);
        testB(3);
        testB(4);
        testB(5);
        testB(6);
        testB(7);
    }
    
    //__FILE__, __LINE__, __MODULE__, __FUNCTION__, __PRETTY_FUNCTION__ to loc.
    private void testB(int value , string file = __FILE__, int line = __LINE__, string moduleName = __MODULE__, string funcName = __FUNCTION__, string prettyFunc = __PRETTY_FUNCTION__)
    {
        writefln("fileName = %s\n, line = %d\n, module = %s\n, function = %s\n, prettyFunc = %s"
                 , file
                 , line
                 , moduleName
                 , funcName
                 , prettyFunc);
        writefln("value = %d\n", value);
    }
}