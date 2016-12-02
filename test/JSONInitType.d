module test.JSONInitType;

import test.Test;
import std.json;
import std.stdio: Out = writeln;

class JSONInitType : Test
{
    override public void test() {
        JSONValue jsValue;
        switch(jsValue.type)
        {
            case JSON_TYPE.NULL:
                {
                    Out("Init type NULL");
                }
                break;
            default:
                {
                    Out("don't know!");
                }
        }

        if(jsValue.type == JSON_TYPE.ARRAY)
        {
            Out("type NULL == ARRAY!");
        }
        else
        {
            Out("type NULl != ARRAY!");
        }

        jsValue.type = JSON_TYPE.ARRAY;
        if(jsValue.type == JSON_TYPE.ARRAY)
        {
            Out("type can converted To ARRAY!");
        }
        else
        {
            Out("type can not converted To ARRAY!");
        }
    }
    
}