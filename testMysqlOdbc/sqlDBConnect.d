module db.sqlDBConnect;

import std.stdio;
import std.string;
import core.sys.windows.windows;
import std.conv;
import core.stdc.stdlib;
import core.stdc.time;
import std.c.windows.sql;
import std.c.windows.sqlext;
import std.c.windows.sqltypes;
import std.c.windows.odbc32dll;
import std.windows.charset;
import std.datetime;
import std.json;
import std.uuid;
import toolkit.toolfunction;
import std.container;
import vibe.textfilter.urlencode;
import std.array;
import core.memory;
import std.traits;

import db.sqlConnectionItemBean;
import db.SqlConnectionPool;
import logger.simpleLog;
import db.mssqldbfunction;

/**********************************************************************
* 标识在操作数据库过程中出现错误
*/
class DBConnException : Exception
{
    @safe pure nothrow
        this()
        {
            super("DBConnect error");
        }

    @safe pure nothrow
        this(string msg, string fn = __FILE__, size_t ln = __LINE__, Throwable next = null)
        {
            super(msg, fn, ln, next);
        }
}

class sqlDBConnect
{
    this()
    {
        _initOK = false;
        _connectionPool = null;
        _connection = null;
        _hstmt = null;
        _hdbc = null;

        if(init())
        {
            _initOK = true;
        }

        _isDebug = false;
        version(Debug)
        {
            _isDebug = true;
        }
    }

    ~this()
    {
        if(_hdbc !is null)
        {
            _hdbc = null;
        }

        if(_hstmt !is null)
        {
            SQLFreeHandle(SQL_HANDLE_STMT, _hstmt); 
            _hstmt = null;
        }
        
        if(_connection !is null)
        {
            _connectionPool.giveBackConnectItem(_connection);
            _connection = null;
        }
    }

    private bool _isDebug;
    private bool isDebug()
    {
        return _isDebug;
    }

    //odbc函数
    private static HINSTANCE hODBC32DLL = null; 
	//private const static string   sLibName   = r"C:\windows\system32\odbc32.dll"c;

	private static   pfn_SQLAllocConnect     SQLAllocConnect = null; 
	private static   pfn_SQLAllocEnv         SQLAllocEnv = null; 
	private static   pfn_SQLAllocHandle      SQLAllocHandle = null;
	private static   pfn_SQLAllocStmt        SQLAllocStmt = null; 
	private static   pfn_SQLBindCol          SQLBindCol = null;
	private static   pfn_SQLBindParam        SQLBindParam = null    ;
	private static   pfn_SQLBindParameter    SQLBindParameter = null  ;
	private static   pfn_SQLBrowseConnect    SQLBrowseConnect = null ;
	private static   pfn_SQLBulkOperations   SQLBulkOperations = null ;
	private static   pfn_SQLCancel           SQLCancel = null   ;    
	private static   pfn_SQLCloseCursor      SQLCloseCursor = null  ;    
	private static   pfn_SQLColAttribute     SQLColAttribute = null  ;
	private static   pfn_SQLColAttributes    SQLColAttributes = null ;
	private static   pfn_SQLColumnPrivileges SQLColumnPrivileges = null ;
	private static   pfn_SQLColumns          SQLColumns = null      ; 
	private static   pfn_SQLConnect          SQLConnect = null    ; 
	private static   pfn_SQLCopyDesc         SQLCopyDesc = null     ; 
	private static   pfn_SQLDataSources      SQLDataSources = null  ; 
	private static   pfn_SQLDescribeCol      SQLDescribeCol = null  ;
	private static   pfn_SQLDescribeParam    SQLDescribeParam = null ;
	private static   pfn_SQLDisconnect       SQLDisconnect = null  ; 
	private static   pfn_SQLDriverConnect    SQLDriverConnect = null ; 
	private static   pfn_SQLDrivers          SQLDrivers = null  ;
	private static   pfn_SQLEndTran          SQLEndTran = null  ;
	private static   pfn_SQLError            SQLError = null ;
	private static   pfn_SQLExecDirect       SQLExecDirect = null ;
	private static   pfn_SQLExecute          SQLExecute = null ;
	private static   pfn_SQLExtendedFetch    SQLExtendedFetch = null ;
	private static   pfn_SQLFetch            SQLFetch = null       ;
	private static   pfn_SQLFetchScroll      SQLFetchScroll = null   ;
	private static   pfn_SQLForeignKeys      SQLForeignKeys = null  ;
	private static   pfn_SQLFreeConnect      SQLFreeConnect = null  ; 
	private static   pfn_SQLFreeEnv          SQLFreeEnv = null     ; 
	private static   pfn_SQLFreeHandle       SQLFreeHandle = null     ;
	private static   pfn_SQLFreeStmt         SQLFreeStmt = null    ;
	private static   pfn_SQLGetConnectAttr   SQLGetConnectAttr = null  ;
	private static   pfn_SQLGetConnectOption SQLGetConnectOption = null ;
	private static   pfn_SQLGetCursorName    SQLGetCursorName = null  ;
	private static   pfn_SQLGetData          SQLGetData = null      ;
	private static   pfn_SQLGetDescField     SQLGetDescField = null ;
	private static   pfn_SQLGetDescRec       SQLGetDescRec = null  ;
	private static   pfn_SQLGetDiagField     SQLGetDiagField = null;
	private static   pfn_SQLGetDiagRec       SQLGetDiagRec = null ;
	private static   pfn_SQLGetEnvAttr       SQLGetEnvAttr = null ;
	private static   pfn_SQLGetFunctions     SQLGetFunctions = null ;
	private static   pfn_SQLGetStmtAttr      SQLGetStmtAttr = null;
	private static   pfn_SQLGetStmtOption    SQLGetStmtOption = null;
	private static   pfn_SQLGetTypeInfo      SQLGetTypeInfo = null;
	private static   pfn_SQLMoreResults      SQLMoreResults = null ;
	private static   pfn_SQLNativeSql        SQLNativeSql = null;
	private static   pfn_SQLNumParams        SQLNumParams = null;
	private static   pfn_SQLNumResultCols    SQLNumResultCols = null ;
	private static   pfn_SQLParamData        SQLParamData = null ;
	private static   pfn_SQLParamOptions     SQLParamOptions = null;
	private static   pfn_SQLPrepare          SQLPrepare = null   ;
	private static   pfn_SQLPrimaryKeys      SQLPrimaryKeys = null ;
	private static   pfn_SQLProcedureColumns SQLProcedureColumns = null;
	private static   pfn_SQLProcedures       SQLProcedures = null;
	private static   pfn_SQLPutData          SQLPutData = null ;
	private static   pfn_SQLRowCount         SQLRowCount = null ;
	private static   pfn_SQLSetConnectAttr   SQLSetConnectAttr = null ;
	private static   pfn_SQLSetConnectOption SQLSetConnectOption = null ;
	private static   pfn_SQLSetCursorName    SQLSetCursorName = null ;
	private static   pfn_SQLSetDescField     SQLSetDescField = null ;
	private static   pfn_SQLSetDescRec       SQLSetDescRec = null;
	private static   pfn_SQLSetEnvAttr       SQLSetEnvAttr = null ;
	private static   pfn_SQLSetParam         SQLSetParam = null ;
	private static   pfn_SQLSetPos           SQLSetPos = null ;
	private static   pfn_SQLSetStmtAttr      SQLSetStmtAttr = null;
	private static   pfn_SQLSetStmtOption    SQLSetStmtOption = null;
	private static   pfn_SQLSpecialColumns   SQLSpecialColumns = null;
	private static   pfn_SQLStatistics       SQLStatistics = null ;
	private static   pfn_SQLTablePrivileges  SQLTablePrivileges = null;
	private static   pfn_SQLTables           SQLTables = null ;
	private static   pfn_SQLTransact         SQLTransact = null;   

    private void logErr(Char, Args...)(in Char[] fmt, Args args)if (isSomeChar!Char)
    {
        simpleLog.logErrorInfo(format(fmt, args));
    }

    private void Debug(Char, Args...)(in Char[] fmt, Args args)if (isSomeChar!Char)
    {
        if(isDebug())
        {
            logErr(fmt, args);
        }
    }

    private static synchronized bool initSQLFuncPtr()
    {
        if(SQLAllocConnect !is null)
        {
            return true;
        }

        if(SqlConnectionPool.getInstance().getODBCHandle()){
            hODBC32DLL = SqlConnectionPool.getInstance().getODBCHandle();
        }else{
            return false;
        }

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

        return true;
    }

    private bool init()
    {
        try
        {
            if(!initSQLFuncPtr())
            {
                return false;
            }

            _connectionPool = SqlConnectionPool.getInstance();
            if(_connectionPool is null)
            {
                return false;
            }

            _connection = _connectionPool.getConnection();
            if(_connection is null)
            {
                return false;
            }

            _hdbc = _connection.getHDBC();
            if(_hdbc is null)
            {
                return false;
            }
        }
        catch(Throwable err)
        {
            throw new DBConnException(err.toString());
        }

        return false;
    }

    //初始化
    private SqlConnectionPool _connectionPool;
    private sqlConnectionItemBean _connection;
    private HDBC _hdbc;
    bool _initOK;

    private HSTMT _hstmt;

    private void checkError(SQLRETURN retcode)
    {
        //Debug("retcode = %d in checkError", retcode);
        if(_hstmt is null)
        {
            throw new DBConnException("_hstmt is null in checkError!");
        }

        if(retcode != SQL_SUCCESS && retcode != SQL_SUCCESS_WITH_INFO)
        {
            char szError[500];
            char szSqlState[50];
            int iNativeErrorPtr = 0;
            int iPtr = 0;
            SQLGetDiagRec(cast(short)SQL_HANDLE_STMT,
                          cast(void*)_hstmt,
                          cast(short)1,
                          &szSqlState[0],
                          &iNativeErrorPtr,
                          &szError[0], 
                          cast(short)499, 
                          cast(short*)&iPtr);
            simpleLog.logErrorInfo(cast(string)szError);
            throw new DBConnException(cast(string)szError);
        }
    }

    //提交或者回退
    private bool EndTran(int RollorCommit)
    {
        if(!_initOK)
        {
            throw new DBConnException("init db failed!!");
        }

        if(_hdbc is null)
        {
            return false;
        }

        SQLRETURN retcode = SQLEndTran(cast(SQLSMALLINT)SQL_HANDLE_DBC, _hdbc, cast(SQLSMALLINT)RollorCommit);
        checkError(retcode);

        return true;
    }

    public bool RollBack()
    {
        return EndTran(SQL_ROLLBACK);
    }

    public bool Commit()
    {
        return EndTran(SQL_COMMIT);
    }

    private string _sqlStatement;
    public string Format(Char, Args...)(in Char[] fmt, Args args)if (isSomeChar!Char)
    {
        _sqlStatement = format(fmt, args).idup;
        return _sqlStatement.idup;
    }

    public ref sqlDBConnect opOpAssign(string op, C)(C z)
        if (op == "~" && isSomeChar!C)
    {
        _sqlStatement ~= cast(string)(z).idup;
        return this;
    }

    public const string getSqlStatment()
    {
        return _sqlStatement;
    }

    private enum BindValueType{STRING, ULONG, LONG, DOUBLE};
    private union BindValue
    {
        string strValue;
        ulong ulValue;
        long lValue;
        double rValue;
    };
    private struct BindParam
    {
        BindValueType type;
        BindValue value;
    }

    private BindParam[uint] _bindedParams;
    public void Bind(T)(uint idxParam, T value)
    {
        static if(is(typeof(value) == string)
                  || (isSomeString!(T))
                  )
        {
            BindParam bindParam;
            bindParam.type = BindValueType.STRING;
            bindParam.value.strValue = cast(string)(value).idup;
            _bindedParams[idxParam] = bindParam;
        }
        else static if(is(typeof(value) == int)
                       || is(typeof(value) == long)
                       || is(typeof(value) == short)
                       || is(typeof(value) == byte)
                       )
        {
            BindParam bindParam;
            bindParam.type = BindValueType.LONG;
            bindParam.value.lValue = cast(long)(value);
            _bindedParams[idxParam] = bindParam;
        }
        else static if(is(typeof(value) == uint)
                       || is(typeof(value) == ulong)
                       || is(typeof(value) == ushort)
                       || is(typeof(value) == ubyte)
                       )
        {
            BindParam bindParam;
            bindParam.type = BindValueType.ULONG;
            bindParam.value.ulValue = cast(ulong)(value);
            _bindedParams[idxParam] = bindParam;
        }
        else static if(is(typeof(value) == real)
                       || is(typeof(value) == double)
                       || is(typeof(value) == float)
                       )
        {
            BindParam bindParam;
            bindParam.type = BindValueType.DOUBLE;
            bindParam.value.rValue = cast(double)(value);
            _bindedParams[idxParam] = bindParam;
        }
        else
        {
            throw new DBConnException("not supported BindParam Type");
        }
    }

    alias SQLUINTEGER ColumnLen;
    alias SQLINTEGER DataLen;
    private enum ResultValueType{LONG, STRING, DOUBLE, ULONG};
    private union ResultValue
    {
        string strValue;
        long lValue;
        double rValue;
        ulong ulValue;
    };
    private struct ResultColumn
    {
        string colTitle;
        ResultValueType type;
        ColumnLen Len;
    }

    private struct ColumnData
    {
        ResultValueType type;
        ResultValue value;
        DataLen dataLen;
    }
    
    ResultColumn[uint] _rowDefine;
    ColumnData[uint] _currentRow;
    SQLSMALLINT _numOfcolumns;

    //执行sql语句
    public void Execute()
    {
        bBindResultCol = false;
        //清空之前的结果集
        foreach(key, column; _currentRow)
        {
            _currentRow.remove(key);
        }

        //释放之前的语句描述符
        RETCODE retcode = SQLFreeHandle(SQL_HANDLE_STMT, _hstmt);
        if(_hstmt !is null)
        {
            checkError(retcode);
        }

        //获取语句描述符
        retcode = SQLAllocHandle(SQL_HANDLE_STMT, _hdbc, &_hstmt);
        checkError(retcode);

        //准备
        retcode = SQLPrepare(_hstmt, cast(char*)std.string.toStringz(_sqlStatement), SQL_NTS);
        checkError(retcode);

        //绑定
        SQLSMALLINT numOfParams;
        retcode = SQLNumParams(_hstmt, &numOfParams);
        checkError(retcode);

        for(int Idx = 0; Idx < numOfParams; ++Idx)
        {
            SQLSMALLINT paramType;
            SQLUINTEGER paramSize;
            SQLSMALLINT paramScale;
            SQLSMALLINT paramNullable;

            retcode = SQLDescribeParam(_hstmt, cast(SQLUINTEGER)(Idx + 1), &paramType, &paramSize, &paramScale, &paramNullable);
            checkError(retcode);

            BindParam param;
            if(Idx + 1 <= _bindedParams.keys.length)
            {
                param = _bindedParams[Idx + 1];
            }
            else
            {
                throw new DBConnException(format("parameter:%d not binded!", Idx + 1));
            }
            
            SQLPOINTER valuePtr = null;
            SQLINTEGER valueLen = 0;
            writefln("%d", paramType);
            switch(param.type)
            {
                case BindValueType.DOUBLE:
                    {
                        valuePtr = &param.value.rValue;
                        valueLen = param.value.rValue.sizeof;
                        retcode = SQLBindParameter(_hstmt, cast(SQLUINTEGER)(Idx + 1), SQL_PARAM_INPUT, SQL_C_DEFAULT, paramType, paramSize, paramScale
                                                   , valuePtr, valueLen, &valueLen);
                        break;
                    }
                case BindValueType.LONG:
                    {
                        valuePtr = &param.value.lValue;
                        valueLen = param.value.lValue.sizeof;
                        retcode = SQLBindParameter(_hstmt, cast(SQLUINTEGER)(Idx + 1), SQL_PARAM_INPUT, SQL_C_DEFAULT, paramType, paramSize, paramScale
                                                   , valuePtr, valueLen, &valueLen);
                        break;
                    }
                case BindValueType.STRING:
                    {
                        valuePtr = cast(void*)(param.value.strValue.idup);
                        valueLen = (cast(const char[])(param.value.strValue)).length;
                        retcode = SQLBindParameter(_hstmt, cast(SQLUINTEGER)(Idx + 1), SQL_PARAM_INPUT, SQL_C_DEFAULT, paramType, paramSize, paramScale
                                                   , valuePtr, valueLen, &valueLen);
                        break;
                    }
                case BindValueType.ULONG:
                    {
                        valuePtr = &param.value.ulValue;
                        valueLen = param.value.ulValue.sizeof;
                        retcode = SQLBindParameter(_hstmt, cast(SQLUINTEGER)(Idx + 1), SQL_PARAM_INPUT, SQL_C_DEFAULT, paramType, paramSize, paramScale
                                                   , valuePtr, valueLen, &valueLen);
                        break;
                    }
                default:
                    {
                        break;
                    }
            }

            
            checkError(retcode);
        }

        //执行
        retcode = SQLNumResultCols(_hstmt, &_numOfcolumns);
        checkError(retcode);

        static const int COLNAMEMAX = 128;
        for(int idx = 0; idx < _numOfcolumns; ++idx)
        {
            scope SQLCHAR[COLNAMEMAX] szColName;
            scope SQLSMALLINT colNameLen;
            scope SQLSMALLINT colType;
            scope SQLUINTEGER colSize;
            scope SQLSMALLINT colScale;
            scope SQLSMALLINT Nullable;
            retcode = SQLDescribeCol(_hstmt, cast(SQLUSMALLINT)(idx+1), cast(char*)szColName, COLNAMEMAX, &colNameLen, &colType, &colSize, &colScale, &Nullable);
            checkError(retcode);
            
            //Debug("colName:%s, colNameLen:%d, colType:%d, colSize:%d, colScale:%d, Nullable:%d", cast(string)szColName[0 .. colNameLen], colNameLen, colType, colSize, colScale, Nullable);

            ResultColumn column;// = new ResultColumn;
            column.colTitle = szColName[0 .. colNameLen].idup;
            switch(colType)
            {
                case SQL_BIGINT:
                case SQL_INTEGER:
                case SQL_SMALLINT:
                case SQL_TINYINT:
                    {
                        column.type = ResultValueType.LONG;
                        break;
                    }
                case SQL_C_UBIGINT:
                case SQL_C_ULONG:
                case SQL_C_USHORT:
                case SQL_C_UTINYINT:
                    {
                        column.type = ResultValueType.ULONG;
                        break;
                    }
                case SQL_CHAR:
                case SQL_VARCHAR:
                case SQL_WCHAR:

                // * The previous definitions for SQL_UNICODE_ are historical and obsolete *
                case SQL_WVARCHAR:
                case SQL_WLONGVARCHAR:


                case SQL_TYPE_TIMESTAMP://不知道时间类型怎么处理呢。。。。
                    {
                        column.type = ResultValueType.STRING;
                        break;
                    }
                case SQL_DECIMAL:
                case SQL_DOUBLE:
                case SQL_FLOAT:
                case SQL_REAL:
                    {
                        column.type = ResultValueType.DOUBLE;
                        break;
                    }
                default:
                    {
                        column.type = ResultValueType.STRING;
                    }
            }
            
            column.Len = cast(ColumnLen)colSize;
            _rowDefine[idx + 1] = column;
        }

        retcode = SQLExecute(_hstmt);
        checkError(retcode);
    }

    //获取结果集
    char[][] strBindValues;
    int[] strBindValueLens;
    double[] rBindValues;
    long[] lBindValues;
    ulong[] ulBindValues;
    bool bBindResultCol = false;
    public bool GetRow()
    {
        RETCODE retcode;
        
        strBindValues.length = _numOfcolumns; 
        strBindValueLens.length = _numOfcolumns;
        rBindValues.length = _numOfcolumns;
        lBindValues.length = _numOfcolumns;
        if(!bBindResultCol)
        {
            for(int idx = 0; idx < _numOfcolumns; ++idx)
            {
                ResultColumn thisColumn = _rowDefine[idx + 1];

                ColumnData oneColumn;
                oneColumn.type = thisColumn.type;

                if(oneColumn.type == ResultValueType.LONG)
                {
                    retcode = SQLBindCol(_hstmt, cast(SQLUSMALLINT)(idx + 1), SQL_C_LONG, &lBindValues[idx + 1], 0, null);
                }else if(oneColumn.type == ResultValueType.DOUBLE)
                {
                    retcode = SQLBindCol(_hstmt, cast(SQLUSMALLINT)(idx + 1), SQL_C_DOUBLE, &rBindValues[idx + 1], 0, null);
                }else if(oneColumn.type == ResultValueType.STRING)
                {
                    strBindValues[idx + 1].length = thisColumn.Len + 1;
                    retcode = SQLBindCol(_hstmt, cast(SQLUSMALLINT)(idx + 1), SQL_C_CHAR, cast(char*)(strBindValues[idx+1]), thisColumn.Len + 1, &strBindValueLens[idx + 1]);
                }else if(oneColumn.type == ResultValueType.ULONG)
                {
                    retcode = SQLBindCol(_hstmt, cast(SQLUSMALLINT)(idx + 1), SQL_C_ULONG, &ulBindValues[idx + 1], 0, null);
                }
                checkError(retcode);

                _currentRow[idx + 1] = oneColumn;
            }
        }
       
        bBindResultCol = true;

        retcode = SQLFetch(_hstmt);
        if(retcode == SQL_NO_DATA_FOUND)
        {
            return false;
        }
        else
        {
            checkError(retcode);
        }

        for(int n = 0; n < _numOfcolumns; ++n)
        {

            switch(_currentRow[n + 1].type)
            {
                case ResultValueType.STRING:
                    {
                        if(strBindValueLens[n+1] >= 0)
                        {
                            _currentRow[n + 1].value.strValue = strBindValues[n+1][0 .. strBindValueLens[n+1]].idup;
                        }
                        else
                        {
                            _currentRow[n + 1].value.strValue = "".idup;
                        }
                        break;
                    }
                case ResultValueType.LONG:
                    {
                        _currentRow[n + 1].value.lValue = lBindValues[n + 1];
                        break;
                    }
                case ResultValueType.ULONG:
                    {
                        _currentRow[n + 1].value.ulValue = ulBindValues[n + 1];
                        break;
                    }
                case ResultValueType.DOUBLE:
                    {
                        _currentRow[n + 1].value.rValue = rBindValues[n + 1];
                        break;
                    }
                default:
                    {
                        throw new DBConnException("Unsupported Value Type!");
                    }
            }
            
        }

        return true;
    }

    //打印当前结果集
    public void DebugCurrentRowData()
    {
        Debug("************************************************************888");
        foreach(key, column; _currentRow)
        {
            string value;
            switch(column.type)
            {
                case ResultValueType.DOUBLE:
                    {
                        value = to!string(column.value.rValue);
                        break;
                    }
                case ResultValueType.LONG:
                    {
                        value = to!string(column.value.lValue);
                        break;
                    }
                case ResultValueType.ULONG:
                    {
                        value = to!string(column.value.ulValue);
                        break;
                    }
                case ResultValueType.STRING:
                    {
                        value = format("stringValue[%s]", column.value.strValue);
                        break;
                    }
                default:
                    {
                        throw new DBConnException("DebugCurrentRowData!");
                    }
            }
            Debug("columnTitle:[%s] columnIndex:[%d], value:[%s]", _rowDefine[key].colTitle, key, value);
        }
        Debug("************************************************************9999");
    }
}
