module test.JSONObjectKeyIn;

import test.Test;
import std.json;

class JSONObjectKeyIn : Test
{
    override public void test() {
        JSONValue jsValue;
        jsValue["exists"] = "Exists";

        if("exists" in jsValue)
        {
            writeln("jsValue[\"exists\"] = \"Exists\";" ~ " \"exists\" exists. ");
            writeln("typeof(\"exists\" in jsValue) = " ~ "const(JSONValue)");
        }
        if("not exists" in jsValue)
        {
            writeln("not exists" ~ " exists!");
        }
        else
        {
            writeln("not exists not exists!");
        }
    }
}