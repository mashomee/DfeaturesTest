import std.stdio;


import std.stdio;  // Uses writefln()
import std.string; // Uses toStringz()
import core.sys.windows.windows;
import std.container;
import std.range;
import std.algorithm;
import std.conv;
import core.stdc.time;
import std.c.windows.sql;
import std.c.windows.sqlext;
import std.c.windows.sqltypes;
import std.c.windows.odbc32dll;
import std.windows.charset;
import std.datetime;
import std.file;
import std.path;



class TestMysqlException : Exception
{
    @safe pure nothrow
        this()
        {
            super("TestMysqlException error");
        }

    @safe pure nothrow
        this(string msg, string fn = __FILE__, size_t ln = __LINE__, Throwable next = null)
        {
            super(msg, fn, ln, next);
        }
}

int main(string[] argv)
{
    writeln("Hello D-World!");

    initODBC();

    //listAllDrivers();
    
    //newConnection();

    testInsertBlob();
    return 0;
}

private static const string pathPicOne = "C:\\Users\\Public\\Pictures\\Sample Pictures\\flower.jpg";
private static const string pathPicTwo = "D:\\xce\\mysql-connector-c-6.1.6-win32.msi";
void testInsertBlob()
{
    HSTMT hstmt = null;
    HDBC hdbc = null;
    scope(exit)
    {
        if(hstmt !is null)
        {
            SQLFreeHandle(SQL_HANDLE_STMT, hstmt); 
            hstmt = null;
        }
        if(hdbc !is null)
        {
            SQLFreeHandle(SQL_HANDLE_DBC, hdbc); 
            hdbc = null;
        }
    }

    //插入两张图片数据
    auto pic1 = File(pathPicOne, "rb");
    auto pic2 = File(pathPicTwo, "rb");

    //缓冲区
    /++
    ubyte[] pic1Buffer;
    ubyte[] pic2Buffer;
    pic1Buffer.length = cast(uint)getSize(pathPicOne);
    pic2Buffer.length = cast(uint)getSize(pathPicTwo);
    ++/

    SQLCHAR[] pic1Buffer = pic1.rawRead(new SQLCHAR[cast(uint)getSize(pathPicOne)]);
    SQLCHAR[] pic2Buffer = pic2.rawRead(new SQLCHAR[cast(uint)getSize(pathPicTwo)]);

    hdbc = newConnection();
    if(hdbc is null)
    {
        throw new TestMysqlException("连接数据库失败！");
    }

    //组织sql语句
    string sqlStmt = "insert into picture(name, data) values(?,?)";

    //准备
    RETCODE rc= SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    checkErrorhstmt(rc, hstmt);

    rc = SQLPrepare(hstmt, cast(char*)std.string.toStringz(sqlStmt), SQL_NTS);
    checkErrorhstmt(rc, hstmt);



    SQLINTEGER putDataAtExec = SQL_DATA_AT_EXEC;
    string name1 = baseName(pathPicOne);
    rc = SQLBindParameter(hstmt, cast(SQLUINTEGER)(1), cast(short)SQL_PARAM_INPUT, cast(short)SQL_C_CHAR, cast(short)SQL_CHAR, 0, 0
                                    , cast(SQLPOINTER)1, 0, &putDataAtExec);
    checkErrorhstmt(rc, hstmt);

    rc = SQLBindParameter(hstmt, cast(SQLUINTEGER)(2), cast(short)SQL_PARAM_INPUT, cast(short)SQL_C_BINARY, cast(short)SQL_LONGVARBINARY, 0, 0
                          , cast(SQLPOINTER)2, 0, &putDataAtExec);
    checkErrorhstmt(rc, hstmt);

    //执行1
    SQLPOINTER whichParam;
    rc = SQLExecute(hstmt);
    if(SQL_NEED_DATA == checkErrorhstmt(rc, hstmt))
    {
        rc = SQLParamData(hstmt, cast(SQLPOINTER*)&whichParam);
        while(SQL_NEED_DATA == checkErrorhstmt(rc, hstmt))
        {
            LogErr(format("whichParam:%x", whichParam));
            if(whichParam == cast(SQLPOINTER)1)
            {
                rc = SQLPutData(hstmt, cast(SQLPOINTER)(name1.ptr), cast(SQLINTEGER)(name1.length));
            }
            else if(whichParam == cast(SQLPOINTER)2)
            {
                rc = SQLPutData(hstmt, cast(SQLPOINTER)(pic1Buffer.ptr), cast(SQLINTEGER)(pic1Buffer.length));
            }
            else
            {
                LogErr("what ???");
            }
            checkErrorhstmt(rc, hstmt);


            rc = SQLParamData(hstmt, cast(SQLPOINTER*)&whichParam);
        }
    }

    string name2 = baseName(pathPicTwo);;
    rc = SQLBindParameter(hstmt, cast(SQLUINTEGER)(1), cast(short)SQL_PARAM_INPUT, cast(short)SQL_C_CHAR, cast(short)SQL_CHAR, 0, 0
                          , cast(SQLPOINTER)1, 0, &putDataAtExec);
    checkErrorhstmt(rc, hstmt);

    rc = SQLBindParameter(hstmt, cast(SQLUINTEGER)(2), cast(short)SQL_PARAM_INPUT, cast(short)SQL_C_BINARY, cast(short)SQL_LONGVARBINARY, 0, 0
                          , cast(SQLPOINTER)2, 0, &putDataAtExec);
    checkErrorhstmt(rc, hstmt);

    //执行2
    rc = SQLExecute(hstmt);
    if(SQL_NEED_DATA == checkErrorhstmt(rc, hstmt))
    {
        rc = SQLParamData(hstmt, cast(SQLPOINTER*)&whichParam);
        while(SQL_NEED_DATA == checkErrorhstmt(rc, hstmt))
        {
            LogErr(format("whichParam:%x", whichParam));
            if(whichParam == cast(SQLPOINTER)1)
            {
                rc = SQLPutData(hstmt, cast(SQLPOINTER)(name2.ptr), cast(SQLINTEGER)(name2.length));
            }
            else if(whichParam == cast(SQLPOINTER)2)
            {
                rc = SQLPutData(hstmt, cast(SQLPOINTER)(pic2Buffer.ptr), cast(SQLINTEGER)(pic2Buffer.length));
            }
            else
            {
                LogErr("what ???");
            }
            checkErrorhstmt(rc, hstmt);


            rc = SQLParamData(hstmt, cast(SQLPOINTER*)&whichParam);
        }
    }
    
}


void testReadBlob()
{
}

public void testBlob()
{
    void testInsertBlob();
    void testReadBlob();
}

private  static string   sLibName   = r"odbc32.dll"c;
private HINSTANCE hODBC32DLL = null; 

public bool initODBC()
{
    // Loading C:\windows\system32\odbc32.dll
    //if(exists(sLibName))

    {
        
        hODBC32DLL = LoadLibraryA( std.string.toStringz( sLibName ) );
        writefln( "Library \"%s\" loaded, ODBC32.DLL handle=%d"c, sLibName, cast(int)hODBC32DLL );
        if (hODBC32DLL <= cast(HINSTANCE)0)
        {
            // writefln( r"C:\windows\system32\odbc32.dll not found!"c );
            hODBC32DLL = null;
            //return false;
            sLibName   = r"C:\windows\system32\odbc32.dll"c;
            hODBC32DLL = LoadLibraryA( std.string.toStringz(sLibName) );
        }

    }
    /**

    //else
    {
    sLibName   = r"C:\windows\system32\odbc32.dll"c;
    hODBC32DLL = LoadLibraryA( std.string.toStringz(sLibName) );
    }
    **/


    if(hODBC32DLL <= cast(HINSTANCE)0)
    {
        hODBC32DLL = null;
        writefln("load odbc lib failed");
        return false;
    }
    writefln("load odbc lib success");
    SQLAllocConnect     = cast(pfn_SQLAllocConnect)GetProcAddress( hODBC32DLL, cast(char *)"SQLAllocConnect"c ); 
    SQLAllocEnv         = cast(pfn_SQLAllocEnv)GetProcAddress( hODBC32DLL, cast(char *)"SQLAllocEnv"c ); 
    SQLAllocHandle      = cast(pfn_SQLAllocHandle)GetProcAddress( hODBC32DLL, cast(char *)"SQLAllocHandle"c );
    SQLAllocStmt        = cast(pfn_SQLAllocStmt)GetProcAddress( hODBC32DLL, cast(char *)"SQLAllocStmt"c ); 
    SQLBindCol          = cast(pfn_SQLBindCol)GetProcAddress( hODBC32DLL, cast(char *)"SQLBindCol"c );
    SQLBindParam        = cast(pfn_SQLBindParam)GetProcAddress( hODBC32DLL, cast(char *)"SQLBindParam"c );
    SQLBindParameter    = cast(pfn_SQLBindParameter)GetProcAddress( hODBC32DLL, cast(char *)"SQLBindParameter"c );
    SQLBrowseConnect    = cast(pfn_SQLBrowseConnect)GetProcAddress( hODBC32DLL, cast(char *)"SQLBrowseConnect"c );
    SQLBulkOperations   = cast(pfn_SQLBulkOperations)GetProcAddress( hODBC32DLL, cast(char *)"SQLBulkOperations"c );
    SQLCancel           = cast(pfn_SQLCancel)GetProcAddress( hODBC32DLL, cast(char *)"SQLCancel"c );    
    SQLCloseCursor      = cast(pfn_SQLCloseCursor)GetProcAddress( hODBC32DLL, cast(char *)"SQLCloseCursor"c );    
    SQLColAttribute     = cast(pfn_SQLColAttribute)GetProcAddress( hODBC32DLL, cast(char *)"SQLColAttribute"c );
    SQLColAttributes    = cast(pfn_SQLColAttributes)GetProcAddress( hODBC32DLL, cast(char *)"SQLColAttributes"c );
    SQLColumnPrivileges = cast(pfn_SQLColumnPrivileges)GetProcAddress( hODBC32DLL, cast(char *)"SQLColumnPrivileges"c );
    SQLColumns          = cast(pfn_SQLColumns)GetProcAddress( hODBC32DLL, cast(char *)"SQLColumns"c ); 
    SQLConnect          = cast(pfn_SQLConnect)GetProcAddress( hODBC32DLL, cast(char *)"SQLConnect"c ); 
    SQLCopyDesc         = cast(pfn_SQLCopyDesc)GetProcAddress( hODBC32DLL, cast(char *)"SQLCopyDesc"c ); 
    SQLDataSources      = cast(pfn_SQLDataSources)GetProcAddress( hODBC32DLL, cast(char *)"SQLDataSources"c ); 
    SQLDescribeCol      = cast(pfn_SQLDescribeCol)GetProcAddress( hODBC32DLL, cast(char *)"SQLDescribeCol"c );
    SQLDescribeParam    = cast(pfn_SQLDescribeParam)GetProcAddress( hODBC32DLL, cast(char *)"SQLDescribeParam"c );
    SQLDisconnect       = cast(pfn_SQLDisconnect)GetProcAddress( hODBC32DLL, cast(char *)"SQLDisconnect"c ); 
    SQLDriverConnect    = cast(pfn_SQLDriverConnect)GetProcAddress( hODBC32DLL, cast(char *)"SQLDriverConnect"c ); 
    SQLDrivers          = cast(pfn_SQLDrivers)GetProcAddress( hODBC32DLL, cast(char *)"SQLDrivers"c );
    SQLEndTran          = cast(pfn_SQLEndTran)GetProcAddress( hODBC32DLL, cast(char *)"SQLEndTran"c );
    SQLError            = cast(pfn_SQLError)GetProcAddress( hODBC32DLL, cast(char *)"SQLError"c );
    SQLExecDirect       = cast(pfn_SQLExecDirect)GetProcAddress( hODBC32DLL, cast(char *)"SQLExecDirect"c );
    SQLExecute          = cast(pfn_SQLExecute)GetProcAddress( hODBC32DLL, cast(char *)"SQLExecute"c );
    SQLExtendedFetch    = cast(pfn_SQLExtendedFetch)GetProcAddress( hODBC32DLL, cast(char *)"SQLExtendedFetch"c );
    SQLFetch            = cast(pfn_SQLFetch)GetProcAddress( hODBC32DLL, cast(char *)"SQLFetch"c );
    SQLFetchScroll      = cast(pfn_SQLFetchScroll)GetProcAddress( hODBC32DLL, cast(char *)"SQLFetchScroll"c );
    SQLForeignKeys      = cast(pfn_SQLForeignKeys)GetProcAddress( hODBC32DLL, cast(char *)"SQLForeignKeys"c );
    SQLFreeConnect      = cast(pfn_SQLFreeConnect)GetProcAddress( hODBC32DLL, cast(char *)"SQLFreeConnect"c ); 
    SQLFreeEnv          = cast(pfn_SQLFreeEnv)GetProcAddress( hODBC32DLL, cast(char *)"SQLFreeEnv"c ); 
    SQLFreeHandle       = cast(pfn_SQLFreeHandle)GetProcAddress( hODBC32DLL, cast(char *)"SQLFreeHandle"c );
    SQLFreeStmt         = cast(pfn_SQLFreeStmt)GetProcAddress( hODBC32DLL, cast(char *)"SQLFreeStmt"c );
    SQLGetConnectAttr   = cast(pfn_SQLGetConnectAttr)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetConnectAttr"c );
    SQLGetConnectOption = cast(pfn_SQLGetConnectOption)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetConnectOption"c );
    SQLGetCursorName    = cast(pfn_SQLGetCursorName)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetCursorName"c );
    SQLGetData          = cast(pfn_SQLGetData)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetData"c );
    SQLGetDescField     = cast(pfn_SQLGetDescField)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetDescField"c );
    SQLGetDescRec       = cast(pfn_SQLGetDescRec)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetDescRec"c );
    SQLGetDiagField     = cast(pfn_SQLGetDiagField)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetDiagField"c );
    SQLGetDiagRec       = cast(pfn_SQLGetDiagRec)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetDiagRec"c );
    SQLGetEnvAttr       = cast(pfn_SQLGetEnvAttr)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetEnvAttr"c );
    SQLGetFunctions     = cast(pfn_SQLGetFunctions)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetFunctions"c );
    SQLGetStmtAttr      = cast(pfn_SQLGetStmtAttr)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetStmtAttr"c );
    SQLGetStmtOption    = cast(pfn_SQLGetStmtOption)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetStmtOption"c );
    SQLGetTypeInfo      = cast(pfn_SQLGetTypeInfo)GetProcAddress( hODBC32DLL, cast(char *)"SQLGetTypeInfo"c );
    SQLMoreResults      = cast(pfn_SQLMoreResults)GetProcAddress( hODBC32DLL, cast(char *)"SQLMoreResults"c );
    SQLNativeSql        = cast(pfn_SQLNativeSql)GetProcAddress( hODBC32DLL, cast(char *)"SQLNativeSql"c );
    SQLNumParams        = cast(pfn_SQLNumParams)GetProcAddress( hODBC32DLL, cast(char *)"SQLNumParams"c );
    SQLNumResultCols    = cast(pfn_SQLNumResultCols)GetProcAddress( hODBC32DLL, cast(char *)"SQLNumResultCols"c );
    SQLParamData        = cast(pfn_SQLParamData)GetProcAddress( hODBC32DLL, cast(char *)"SQLParamData"c );
    SQLParamOptions     = cast(pfn_SQLParamOptions)GetProcAddress( hODBC32DLL, cast(char *)"SQLParamOptions"c );
    SQLPrepare          = cast(pfn_SQLPrepare)GetProcAddress( hODBC32DLL, cast(char *)"SQLPrepare"c );
    SQLPrimaryKeys      = cast(pfn_SQLPrimaryKeys)GetProcAddress( hODBC32DLL, cast(char *)"SQLPrimaryKeys"c );
    SQLProcedureColumns = cast(pfn_SQLProcedureColumns)GetProcAddress( hODBC32DLL, cast(char *)"SQLProcedureColumns"c );
    SQLProcedures       = cast(pfn_SQLProcedures)GetProcAddress( hODBC32DLL, cast(char *)"SQLProcedures"c );
    SQLPutData          = cast(pfn_SQLPutData)GetProcAddress( hODBC32DLL, cast(char *)"SQLPutData"c );
    SQLRowCount         = cast(pfn_SQLRowCount)GetProcAddress( hODBC32DLL, cast(char *)"SQLRowCount"c );
    SQLSetConnectAttr   = cast(pfn_SQLSetConnectAttr)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetConnectAttr"c );
    SQLSetConnectOption = cast(pfn_SQLSetConnectOption)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetConnectOption"c );
    SQLSetCursorName    = cast(pfn_SQLSetCursorName)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetCursorName"c );
    SQLSetDescField     = cast(pfn_SQLSetDescField)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetDescField"c );
    SQLSetDescRec       = cast(pfn_SQLSetDescRec)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetDescRec"c );
    SQLSetEnvAttr       = cast(pfn_SQLSetEnvAttr)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetEnvAttr"c );
    SQLSetParam         = cast(pfn_SQLSetParam)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetParam"c );
    SQLSetPos           = cast(pfn_SQLSetPos)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetPos"c );
    SQLSetStmtAttr      = cast(pfn_SQLSetStmtAttr)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetStmtAttr"c );
    SQLSetStmtOption    = cast(pfn_SQLSetStmtOption)GetProcAddress( hODBC32DLL, cast(char *)"SQLSetStmtOption"c );
    SQLSpecialColumns   = cast(pfn_SQLSpecialColumns)GetProcAddress( hODBC32DLL, cast(char *)"SQLSpecialColumns"c );
    SQLStatistics       = cast(pfn_SQLStatistics)GetProcAddress( hODBC32DLL, cast(char *)"SQLStatistics"c );
    SQLTablePrivileges  = cast(pfn_SQLTablePrivileges)GetProcAddress( hODBC32DLL, cast(char *)"SQLTablePrivileges"c );
    SQLTables           = cast(pfn_SQLTables)GetProcAddress( hODBC32DLL, cast(char *)"SQLTables"c );
    SQLTransact         = cast(pfn_SQLTransact)GetProcAddress( hODBC32DLL, cast(char *)"SQLTransact"c );
    //SQLTransact         = cast(pfn_SetSQLConnectAttr)GetProcAddress( hODBC32DLL, cast(char *)"SetSQLConnectAttr"c );

    return true;    
}

class LocalConfig
{
    private this()
    {}
    public ~this()
    {}

    private static LocalConfig configInstance;
    public static LocalConfig instance()
    {
        return configInstance;
    }

    private string _mssqlDBName;
    private string _mssqllocalip;
    private string _mssqlDBPort;
    private string _mssqlodbcuser;
    private string _mssqlodbcpw;

    @property string mssqlDBName(){return _mssqlDBName;}
    @property string mssqllocalip(){return _mssqllocalip;}
    @property string mssqlDBPort(){return _mssqlDBPort;}
    @property string mssqlodbcuser(){return _mssqlodbcuser;}
    @property string mssqlodbcpw(){return _mssqlodbcpw;}

    public void init(string dbName, string ip, string port, string user, string pw)
    {
        _mssqlDBName = dbName.idup;
        _mssqllocalip = ip.idup;
        _mssqlDBPort = port.idup;
        _mssqlodbcuser = user.idup;
        _mssqlodbcpw = pw.idup;
    }
}

public void listAllDrivers()
{
    HENV henv = null;
    HDBC hdbc = null;

    RETCODE rc;
    //申请环境句柄
    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    if(rc != SQL_SUCCESS)
    {
        LogErr("申请环境句柄失败11111。。。。");
        return ;
    }
    //设置环境
    rc = SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION, cast(void *)SQL_OV_ODBC3, 0);
    if(rc != SQL_SUCCESS)
    {
        LogErr("设置环境失败11111。。。。");
        return ;
    }
    
    char[1000] buffer;
    short bufferLen;
    char[500] attrs;
    short attrsLen;
    rc = SQLDrivers(henv, cast(ushort)SQL_FETCH_FIRST, cast(SQLCHAR*)buffer, cast(short)999, &bufferLen, cast(SQLCHAR*)attrs, cast(short)499, &attrsLen);
    while(rc != SQL_NO_DATA)
    {
       if(! checkErrHdbc(rc, henv))
       {
           break;
       }
        LogErr("Driver" ~ buffer[0..bufferLen].idup);
        LogErr("ATTR" ~ attrs[0..attrsLen].idup);

        rc = SQLDrivers(henv, cast(ushort)SQL_FETCH_NEXT, cast(SQLCHAR*)buffer, cast(short)999, &bufferLen, cast(SQLCHAR*)attrs, cast(short)499, &attrsLen);
    }
}

public bool checkErrHdbc(RETCODE rc, HANDLE handle)
{
    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        char szError[500];
        char szSqlState[50];
        int iNativeErrorPtr = 0;
        int iPtr = 0;
        SQLGetDiagRec(cast(short)SQL_HANDLE_DBC,
                      cast(void*)handle,
                      cast(short)1,
                      cast(SQLCHAR*)szSqlState,
                      &iNativeErrorPtr,
                      cast(SQLCHAR*)szError, 
                      cast(short)499, 
                      cast(short*)&iPtr);
        LogErr(": checkErrHdbc" ~ cast(string)szError);
        return false;
    }

    return true;
}

RETCODE checkErrorhstmt(RETCODE rc, HANDLE handle)
{
    LogErr(format(" checkErrorhstmt retCode:%d", rc));

    if(rc == SQL_NEED_DATA)
    {
        return SQL_NEED_DATA;
    }

    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        char szError[500];
        char szSqlState[50];
        int iNativeErrorPtr = 0;
        int iPtr = 0;
        SQLGetDiagRec(cast(short)SQL_HANDLE_STMT,
                      cast(void*)handle,
                      cast(short)1,
                      cast(SQLCHAR*)szSqlState,
                      &iNativeErrorPtr,
                      cast(SQLCHAR*)szError, 
                      cast(short)499, 
                      cast(short*)&iPtr);
        LogErr(": checkErrorhstmt" ~ cast(string)szError[0 .. iPtr]);
        LogErr(format("errCode:[%d] SQlSTAT:[%s]",iNativeErrorPtr, cast(string)szSqlState[0 .. 5]));
        throw new TestMysqlException(cast(string)szError);
    }
    return 0;
}
public	HDBC  newConnection()
{
    //simpleLog.logRunInfo("~~~~~~~~~~~~~~~~~~~~~~~~*进入创建数据库连接的函数！~~~~~~~~~~~~~~~~~~~~~~~~~\n");
    HENV henv = null;
    HDBC hdbc = null;
   
    scope char[1024]  sOutConnectString;
    short   shtOutConnectStringLength = 0;

    //string  sDSNLessConnect = r"Driver={SQL Server};Database=";
    string  sDSNLessConnect = r"Driver={MySQL ODBC 5.3 Unicode Driver};Database=";
    LocalConfig config = LocalConfig.instance();
    if(config !is null)
    {
        sDSNLessConnect ~= config.mssqlDBName;
        sDSNLessConnect ~= ";";
        sDSNLessConnect ~= "Server=";

        if(config.mssqllocalip.length > 0)
        {
            sDSNLessConnect ~= config.mssqllocalip;

        }

        sDSNLessConnect ~=","~ to!string(config.mssqlDBPort)~ ";";
        sDSNLessConnect ~= "UID=";
        sDSNLessConnect ~= config.mssqlodbcuser;
        sDSNLessConnect ~= ";";
        sDSNLessConnect ~= "PWD=";
        sDSNLessConnect ~= config.mssqlodbcpw;
        sDSNLessConnect ~= ";"c;
    }
    RETCODE rc;
    //申请环境句柄
    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    if(rc != SQL_SUCCESS)
    {
        LogErr("申请环境句柄失败11111。。。。");
        return null;
    }
    //设置环境
    rc = SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION, cast(void *)SQL_OV_ODBC3, 0);
    if(rc != SQL_SUCCESS)
    {
        LogErr("设置环境失败11111。。。。");
        return null;
    }
    //申请连接句柄
    rc = SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);
    if(rc != SQL_SUCCESS)
    {
        LogErr("申请连接句柄失败11111。。。。");
        return null;
    }
    

    //sDSNLessConnect = "Driver={SQL Server};Database=ST2303BS_SD;SERVER=192.168.3.46;PORT=1433;UID=sa;PWD=sdgq.1234";
    sDSNLessConnect = "Driver={MySQL ODBC 5.3 Ansi Driver};Database=test;SERVER=192.168.3.46;PORT=3306;UID=test;PWD=jnsenter";

    
    LogErr(sDSNLessConnect);

    rc = SQLDriverConnect(hdbc, null, 
                          cast(char *)std.string.toStringz(sDSNLessConnect), 
                          cast(short)sDSNLessConnect.length, 
                          cast(char *)sOutConnectString, 
                          cast(short)sOutConnectString.length, 
                          &shtOutConnectStringLength, cast(ushort)SQL_DRIVER_NOPROMPT);

    if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
    {
        char szError[500];
        char szSqlState[50];
        int iNativeErrorPtr = 0;
        int iPtr = 0;
        SQLGetDiagRec(cast(short)SQL_HANDLE_DBC,
                      cast(void*)hdbc,
                      cast(short)1,
                      &szSqlState[0],
                      &iNativeErrorPtr,
                      &szError[0], 
                      cast(short)499, 
                      cast(short*)&iPtr);
        LogErr(cast(string)szError);
        return null;
    }
    return hdbc;
}

public void LogErr(string msg)
{
    auto log =  File("DebugLog.txt", "a");
    log.writeln(msg);
}


private pfn_SQLAllocConnect     SQLAllocConnect    ; 
private pfn_SQLAllocEnv         SQLAllocEnv     ; 
private pfn_SQLAllocHandle      SQLAllocHandle    ;
private pfn_SQLAllocStmt        SQLAllocStmt     ; 
private pfn_SQLBindCol          SQLBindCol      ;
private pfn_SQLBindParam        SQLBindParam    ;
private pfn_SQLBindParameter    SQLBindParameter  ;
private pfn_SQLBrowseConnect    SQLBrowseConnect ;
private pfn_SQLBulkOperations   SQLBulkOperations ;
private pfn_SQLCancel           SQLCancel   ;    
private pfn_SQLCloseCursor      SQLCloseCursor  ;    
private pfn_SQLColAttribute     SQLColAttribute  ;
private pfn_SQLColAttributes    SQLColAttributes ;
private  pfn_SQLColumnPrivileges SQLColumnPrivileges ;
private pfn_SQLColumns          SQLColumns      ; 
private pfn_SQLConnect          SQLConnect    ; 
private  pfn_SQLCopyDesc         SQLCopyDesc     ; 
private  pfn_SQLDataSources      SQLDataSources  ; 
private   pfn_SQLDescribeCol      SQLDescribeCol  ;
private  pfn_SQLDescribeParam    SQLDescribeParam ;
private  pfn_SQLDisconnect       SQLDisconnect  ; 
private  pfn_SQLDriverConnect    SQLDriverConnect ; 
private  pfn_SQLDrivers          SQLDrivers  ;
private  pfn_SQLEndTran          SQLEndTran  ;
private  pfn_SQLError            SQLError ;
private  pfn_SQLExecDirect       SQLExecDirect ;
private  pfn_SQLExecute          SQLExecute ;
private  pfn_SQLExtendedFetch    SQLExtendedFetch ;
private  pfn_SQLFetch            SQLFetch       ;
private  pfn_SQLFetchScroll      SQLFetchScroll   ;
private  pfn_SQLForeignKeys      SQLForeignKeys  ;
private  pfn_SQLFreeConnect      SQLFreeConnect  ; 
private  pfn_SQLFreeEnv          SQLFreeEnv     ; 
private  pfn_SQLFreeHandle       SQLFreeHandle     ;
private  pfn_SQLFreeStmt         SQLFreeStmt    ;
private  pfn_SQLGetConnectAttr   SQLGetConnectAttr  ;
private  pfn_SQLGetConnectOption SQLGetConnectOption ;
private  pfn_SQLGetCursorName    SQLGetCursorName  ;
private  pfn_SQLGetData          SQLGetData      ;
private  pfn_SQLGetDescField     SQLGetDescField ;
private   pfn_SQLGetDescRec       SQLGetDescRec  ;
private   pfn_SQLGetDiagField     SQLGetDiagField;
private   pfn_SQLGetDiagRec       SQLGetDiagRec ;
private   pfn_SQLGetEnvAttr       SQLGetEnvAttr ;
private   pfn_SQLGetFunctions     SQLGetFunctions ;
private   pfn_SQLGetStmtAttr      SQLGetStmtAttr;
private   pfn_SQLGetStmtOption    SQLGetStmtOption;
private   pfn_SQLGetTypeInfo      SQLGetTypeInfo;
private   pfn_SQLMoreResults      SQLMoreResults ;
private   pfn_SQLNativeSql        SQLNativeSql;
private   pfn_SQLNumParams        SQLNumParams;
private   pfn_SQLNumResultCols    SQLNumResultCols ;
private   pfn_SQLParamData        SQLParamData ;
private   pfn_SQLParamOptions     SQLParamOptions;
private  pfn_SQLPrepare          SQLPrepare   ;
private   pfn_SQLPrimaryKeys      SQLPrimaryKeys ;
private   pfn_SQLProcedureColumns SQLProcedureColumns;
private   pfn_SQLProcedures       SQLProcedures;
private   pfn_SQLPutData          SQLPutData ;
private   pfn_SQLRowCount         SQLRowCount ;
private   pfn_SQLSetConnectAttr   SQLSetConnectAttr ;
private   pfn_SQLSetConnectOption SQLSetConnectOption ;
private   pfn_SQLSetCursorName    SQLSetCursorName ;
private   pfn_SQLSetDescField     SQLSetDescField ;
private   pfn_SQLSetDescRec       SQLSetDescRec;
private  pfn_SQLSetEnvAttr       SQLSetEnvAttr ;
private   pfn_SQLSetParam         SQLSetParam ;
private   pfn_SQLSetPos           SQLSetPos ;
private   pfn_SQLSetStmtAttr      SQLSetStmtAttr;
private  pfn_SQLSetStmtOption    SQLSetStmtOption;
private   pfn_SQLSpecialColumns   SQLSpecialColumns;
private   pfn_SQLStatistics       SQLStatistics ;
private   pfn_SQLTablePrivileges  SQLTablePrivileges;
private    pfn_SQLTables           SQLTables ;
private    pfn_SQLTransact         SQLTransact;    
