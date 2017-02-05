module db.DBQuery;
/++
import std.c.windows.sql;
import std.c.windows.sqlext;
import std.c.windows.sqltypes;
import std.c.windows.odbc32dll;

import std.stdio;
import std.string;
import std.format;
import std.traits;

import db.mssqldbfunction_st;
import db.sqlConnectionItemBean;
import db.SqlConnectionPool;

import logger.simpleLog;

class DBOperationException : Exception
{
    @safe pure nothrow
        this()
        {
            super("DBOperationException!");
        }

    @safe pure nothrow
        this(string msg, string fn = __FILE__, size_t ln = __LINE__, Throwable next = null)
        {
            super(msg, fn, ln, next);
        }
}

struct DBQuery
{
    private bool _onDebug = false;
    private void _debug(string msg, string fileName = __FILE__, int lineNum = __LINE__)
    {
        if(_onDebug)
        simpleLog.logErrorInfo(msg, fileName, lineNum);

        return;
    }

    public void onDebug()
    {
        _onDebug = true;
    }
    ~this()
    {
        try
        {
            if(_hstmt !is null)
            {
                ST_SQLFreeHandle(SQL_HANDLE_STMT, _hstmt);
            }

            if(_hdbc !is null)
            {
                _hdbc = null;
            }

            if(_connection !is null)
            {
                if(_connPool !is null)
                {
                    _connPool.giveBackConnectItem(_connection);
                }
                else
                {
                    _connection = null;
                }
            }

            if(_connPool !is null)
            {
                _connPool = null;
            }
        }
        catch(Throwable err)
        {
            simpleLog.logErrorInfo(err.toString());
        }
    }

    private SqlConnectionPool _connPool = null;
    private sqlConnectionItemBean _connection = null;
    private HDBC _hdbc = null;
    private HSTMT _hstmt = null;
    private string _sqlStatement = "";

    //获取sql句柄错误信息
    void logHSTMTErrorInfo(string fileName = __FILE__, int lineNum = __LINE__)
    {
        char[500] szError;
        char[50] szSqlState;
        int iNativeErrorPtr = 0;
        int iPtr = 0;
        ST_SQLGetDiagRec(cast(short)SQL_HANDLE_STMT,
                      cast(void*)_hstmt,
                      cast(short)1,
                      &szSqlState[0],
                      &iNativeErrorPtr,
                      &szError[0],
                      cast(short)499,
                      cast(short*)&iPtr);
        simpleLog.logErrorInfo(cast(string)(szError), fileName, lineNum);
        simpleLog.logErrorInfo(format("sqlstat[%s]", cast(char*)szSqlState), fileName, lineNum);
        return;
    }
    //检查连接和语句句柄
    private bool _checkHSTMT()
    {
        _debug("_checkHSTMT begin........................");
        if(_hstmt !is null)
        {
            return true;
        }

        if(_connPool is null)
        {
            _connPool = SqlConnectionPool.getInstance();
            if(_connPool is null)
            {
                simpleLog.logErrorInfo("Get _connPool failed!");
                return false;
            }
        }

        if(_connection is null)
        {
            _connection = _connPool.getConnection();
            if(_connection is null)
            {
                simpleLog.logErrorInfo("Get _connection failed!");
                return false;
            }
        }

        if(_hdbc is null)
        {
            _hdbc = _connection.getHDBC();
            if(_hdbc is null)
            {
                simpleLog.logErrorInfo("Get _hdbc failed!");
                return false;
            }
        }

        //每执行一次就将HSTMT释放，放弃以前的结果集，从新获取
        SQLRETURN ret;
        if(_hstmt is null)
        {
            ret = ST_SQLAllocHandle(SQL_HANDLE_STMT, _hdbc, &_hstmt);
            if(_hstmt is null)
            {
                if(ret != SQL_SUCCESS)
                {
                    logHSTMTErrorInfo();
                }
                simpleLog.logErrorInfo("Get _hstmt failed!");
                return false;
            }
        }
        else
        {
            ret = ST_SQLFreeHandle(SQL_HANDLE_STMT, _hstmt);
            if(ret != SQL_SUCCESS)
            {
                logHSTMTErrorInfo();
            }
            ret = ST_SQLAllocHandle(SQL_HANDLE_STMT, _hdbc, &_hstmt);
            if(_hstmt is null)
            {
                if(ret != SQL_SUCCESS)
                {
                    logHSTMTErrorInfo();
                }
                simpleLog.logErrorInfo("Get _hstmt failed!");
                return false;
            }
        }
        return true;
        _debug("_checkHSTMT end........................");
    }

    //格式化获取sql语句
    public immutable(string) Format(Char, Args...)(in Char[] fmt, Args args) if(isSomeChar!Char)
    {
        //import std.format : format;
        try
        {
            _sqlStatement = std.format.format(fmt, args);
            _debug("formatSql:[" ~ _sqlStatement ~ "]");
            return _sqlStatement;
        }
        catch(Throwable err)
        {
            simpleLog.logErrorInfo(err.toString());
            writeln(err.msg);
            throw new DBOperationException(err.msg);
        }
    }
    //直接获取sql语句
    public immutable(string) setSql(string sql)
    {
        _sqlStatement =sql.idup;
        return _sqlStatement;
    }

    //查询的参数有？占位符时保存占位符序号和占位符参数的名称和类型等信息
    string[int] paramBindValues;
    SQLSMALLINT[int] paramTypes;//参数类型和参数序号的对应关系
    //绑定变量， sql语句中有？时调用此接口
    public void bind(int idx, int value)
    {

        if(idx <= 0)
        {
            throw new DBOperationException("ST_SQLBindParameter illegal index bind int");
        }

        import std.conv: to;
        paramBindValues[idx] = to!string(value);
    }

    public void bind(int idx, string value)
    {
        if(idx <= 0)
        {
            throw new DBOperationException("ST_SQLBindParameter illegal index bind string");
        }

        paramBindValues[idx] = value.idup;
    }


    //列名和位置的映射
    private int[string] columnIndex;
    //位置和值的映射
    import std.variant;
    private Variant[int] currentRow;

    //如果是字符串类型，保存获取的字符串的长度
    private SQLINTEGER*[int] realLenths;

    //执行直接执行sql
    public void execute()
    {
        _debug("excute begin.............");
        if(_sqlStatement.empty)
        {
            throw new DBOperationException("sql statement is empty !");
        }

        if(!_checkHSTMT())
        {
            throw new DBOperationException("Check HSTMT failed !");
        }

        SQLRETURN ret =ST_SQLPrepare(_hstmt, cast(SQLCHAR*)toStringz(_sqlStatement), SQL_NTS);
        if(ret != SQL_SUCCESS)
        {
            logHSTMTErrorInfo();
        }

        if(ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO && ret != SQL_NO_DATA)
        {
            throw new DBOperationException(format("sql prepare failed:![%s]", _sqlStatement));
        }



        //获取结果
        /++
        | sqlserver type   | odbc type          | odbc type code | D type                   |
        | bigint           | SQL_BIGINT         |             -5 | int                      |
        | binary           | SQL_BINARY         |             -2 | not use                  |
        | bit              | SQL_BIT            |             -7 | int                      |
        | char             | SQL_CHAR           |              1 | string                   |
        | datetime         | SQL_TYPE_TIMESTAMP |             93 | string                   |
        | decimal          | SQL_DECIMAL        |              3 | not use                  |
        | float            | SQL_FLOAT          |              6 | float                    |
        | image            | SQL_LONGVARBINARY  |             -4 | not use                  |
        | int              | SQL_INTEGER        |              4 | int                      |
        | money            | SQL_DECIMAL        |              3 | not use                  |
        | nchar            | SQL_WCHAR          |             -8 | string, double length                  |
        | ntext            | SQL_WLONGVARCHAR   |            -10 | not use                  |
        | numeric          | SQL_NUMERIC        |              2 | not use                  |
        | nvarchar         | SQL_WVARCHAR       |             -9 | string, double length |
        | real             | SQL_REAL           |              7 | not use                  |
        | smalldatetime    | SQL_TYPE_TIMESTAMP |             93 | not use                  |
        | smallint         | SQL_SMALLINT       |              5 | not use                  |
        | smallmoney       | SQL_DECIMAL        |              3 | not use                  |
        | sql_variant      |                    |           -150 | not use                  |
        | text             | SQL_LONGVARCHAR    |             -1 | not use                  |
        | timestamp        |                    |             -2 | not use                  |
        | tinyint          | SQL_TINYINT        |             -6 | not use                  |
        | uniqueidentifier |                    |            -11 | not use                  |
        | varbinary        | SQL_VARBINARY      |             -3 | not use                  |
        |                  | SQL_TIMESTAMP      |             11 | not use                  |
        | varchar          |                    |             12 | string                   |
        ++/
        //或者使用SQLPrepare来准备数据
        SQLSMALLINT colsCount;
        ret = ST_SQLNumResultCols(_hstmt, &colsCount);
        if(ret != SQL_SUCCESS)
        {
            logHSTMTErrorInfo();
            throw new DBOperationException("ST_SQLNumResultCols failed ! ");
        }
        _debug("colsCount[" ~ std.conv.to!string(colsCount) ~ "]");
        int whatthefuck;
        int whatthefuck2;
        immutable(int) COLMAXLEN=300;
        SQLUSMALLINT nthCol = 0;
        SQLSMALLINT nameColBufferLength = COLMAXLEN;
        SQLSMALLINT nameColRealLength = 0;
        SQLSMALLINT typeCol;
        SQLUINTEGER defColLength = 0;
        SQLSMALLINT defColScale = 0;
        SQLSMALLINT Nullable = 0;
        SQLCHAR[COLMAXLEN]   nameCol;//sql server数据库列的最大长度为128,查询语句中列的别名最长也是128, 单可能是双字节
        //To be removed
        int iCondition = colsCount;//unknow error!!!!
        for(int i = 0; i < colsCount, writefln("colsCount= %d in for", colsCount), i < iCondition; ++i)
        {
writefln("colsCount= %d in for line[%d]", colsCount, __LINE__);
            nthCol = cast(SQLUSMALLINT)(i + 1);
            ret = ST_SQLDescribeCol(_hstmt, nthCol, cast(SQLCHAR*)nameCol, nameColBufferLength, &nameColRealLength, &typeCol, &defColLength, &defColScale, &Nullable);
            _debug(std.format.format("idx[%d], nameColRealLength[%d], colName[%s], colDefineLength[%d], colDefineScale[%d], colType[%d], colNullable[%d]",
                                nthCol, nameColRealLength, nameCol[0..nameColRealLength], defColLength, defColScale, typeCol, Nullable));
            if(ret != SQL_SUCCESS)
            {
                logHSTMTErrorInfo();
            }

            if(ret == SQL_ERROR || ret == SQL_INVALID_HANDLE || ret == SQL_STILL_EXECUTING)
            {
                throw new DBOperationException(format("SQLDescribeCol failed! colIndex[%d]", i));
            }

            //将列名称和位置保存下来
writefln("colsCount= %d in for line[%d]", colsCount, __LINE__);
            string columnName = cast(string)nameCol[0..nameColRealLength].idup;
            columnIndex[columnName] = i + 1;
            //实际长度置为0
            realLenths[i+1] = null;

writefln("colsCount= %d in for line[%d]", colsCount, __LINE__);
            switch(typeCol)
            {
                case SQL_BIGINT : //bigint -5 => long SQL_C_LONG
                    {
                        long* tmp = new long;
                        currentRow[i+1] = tmp;
                        ret = ST_SQLBindCol(_hstmt, nthCol, SQL_C_LONG, tmp, 0, null);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind long Column failed!" ~ " type: bigint ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind long Column OK" ~ " type: bigint ");
                    }
                    break;
                case SQL_BIT : //bit -7 int
                    {
                        char* tmp = new char;
                        currentRow[i+1] = tmp;
                        ret = ST_SQLBindCol(_hstmt, nthCol, SQL_C_CHAR, tmp, 1, null);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind char Column failed!" ~ " type: bit ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind char Column OK" ~ " type: bit ");
                    }
                    break;
                case SQL_CHAR : //char 1 char
                    {
                        char[] tmp;
                        SQLINTEGER* tmpLen = new SQLINTEGER;
                        tmp.length = defColLength;
                        currentRow[i+1] = (tmp);
                        realLenths[i+1] = tmpLen;
                        ret = ST_SQLBindCol(_hstmt, nthCol, cast(SQLSMALLINT)SQL_C_CHAR, cast(SQLPOINTER)tmp, defColLength, tmpLen);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind char[] Column failed!" ~ " type: char ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind char[] Column OK" ~ " type: char ");
                    }
                    break;
                case SQL_TYPE_TIMESTAMP : //datetime 93 char
                    {
                        char[] tmp;
                        SQLINTEGER* tmpLen = new SQLINTEGER;
                        tmp.length = defColLength + 2;
                        currentRow[i+1] = (tmp);
                        realLenths[i+1] = tmpLen;
                        ret = ST_SQLBindCol(_hstmt, nthCol, cast(SQLSMALLINT)SQL_C_CHAR, cast(SQLPOINTER)tmp, defColLength, tmpLen);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind char[] Column failed!" ~ " type: timestamp ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind char[] Column OK" ~ " type: timestamp ");
                    }
                    break;
                case SQL_FLOAT : //float 6 double
                    {
                        double* tmp = new double;
                        currentRow[i+1] = tmp;
                        ret = ST_SQLBindCol(_hstmt, nthCol, cast(SQLSMALLINT)SQL_C_FLOAT, cast(SQLPOINTER)tmp, 0, null);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind double Column failed!" ~ " type: float ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind double Column OK" ~ " type: float ");
                    }
                    break;
                case SQL_INTEGER : //int 4  -> SQL_INTEGER 64 long
                    {
                        long* tmp = new long;
                        currentRow[i+1] = tmp;
                        ret = ST_SQLBindCol(_hstmt, nthCol, SQL_C_LONG, tmp, 0, null);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind long Column failed!" ~ " type: integer ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind long Column OK" ~ " type: integer ");
                    }
                    break;
                case SQL_WCHAR : //nchar -8 char  length * 2
                    {
                        char[] tmp;
                        SQLINTEGER* tmpLen = new SQLINTEGER;
                        tmp.length = defColLength * 2;
                        currentRow[i+1] = (tmp);
                        realLenths[i+1] = tmpLen;
                        ret = ST_SQLBindCol(_hstmt, nthCol, cast(SQLSMALLINT)SQL_C_CHAR, cast(SQLPOINTER)tmp, defColLength, tmpLen);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind char[] Column failed!" ~ " type: wchar ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind char[] Column OK" ~ " type: wchar ");
                    }
                    break;
                case SQL_WVARCHAR : //nvarchar -9 char length * 2
                    {
                        char[] tmp;
                        SQLINTEGER* tmpLen = new SQLINTEGER;
                        tmp.length = defColLength * 2;
                        currentRow[i+1] = (tmp);
                        realLenths[i+1] = tmpLen;
                        ret = ST_SQLBindCol(_hstmt, nthCol, cast(SQLSMALLINT)SQL_C_CHAR, cast(SQLPOINTER)tmp, defColLength, tmpLen);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind char[] Column failed!" ~ " type: wvarchar ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind char[] Column OK" ~ " type: wvarchar ");
                    }
                    break;
                case 12 : //varchar 12 char
                    {
                        char[] tmp;
                        SQLINTEGER* tmpLen = new SQLINTEGER;
                        tmp.length = defColLength * 2;
                        currentRow[i+1] = (tmp);
                        realLenths[i+1] = tmpLen;
                        ret = ST_SQLBindCol(_hstmt, nthCol, cast(SQLSMALLINT)SQL_C_CHAR, cast(SQLPOINTER)tmp, defColLength, tmpLen);
                        if(ret != SQL_SUCCESS)
                        {
                            logHSTMTErrorInfo();
                            _debug("Bind char[] Column failed!" ~ " type: varchar ");
                            throw new DBOperationException(std.format.format("Bind col[%s] failed!", columnName));
                        }
                        _debug("Bind char[] Column OK" ~ " type: varchar ");
                    }
                    break;
                default :
                    {
                        _debug("Bind Column failed!" ~ "default branch! ");
                        throw new DBOperationException("unsupported column type, column: "~ columnName);
                    }
            }
        }

        //执行sql
        ret = ST_SQLExecute(_hstmt);
        if(ret != SQL_SUCCESS)
        {
            logHSTMTErrorInfo();
        }
        if(ret == SQL_ERROR
           || ret == SQL_INVALID_HANDLE)
        {
            throw new DBOperationException("Error when execute sql :" ~ _sqlStatement);
        }

        foreach(key, value; columnIndex)
        {
            _debug(format("key[%s],value[%d]", key, value));
        }
        _debug("excute end.............");


        //绑定参数
        //获取需要绑定的参数的个数
        SQLSMALLINT paramNum;
        ret = ST_SQLNumParams(_hstmt, &paramNum);
        if(ret != SQL_SUCCESS)
        {
            logHSTMTErrorInfo();
        }
        if(ret == SQL_ERROR || ret == SQL_INVALID_HANDLE)
        {
            throw new DBOperationException("ST_SQLNumParams failed!");
        }

        //获取需要绑定参数的类型的信息,绑定参数
        _debug(format("paramNum[%d]", paramNum));
        
        for(int idx = 1; idx < paramNum + 1; ++idx)
        {
        SQLSMALLINT sqlType;
        SQLUSMALLINT sqlPrecision;
        SQLSMALLINT sqlScale;
        SQLSMALLINT sqlNullable;
        ret = ST_SQLDescribeParam(_hstmt, cast(SQLUSMALLINT)idx, &sqlType, &sqlPrecision, &sqlScale, &sqlNullable);
        if(ret != SQL_SUCCESS)
        {
        logHSTMTErrorInfo();
        }
        if(ret == SQL_ERROR || ret == SQL_INVALID_HANDLE || ret == SQL_NO_DATA_FOUND)
        {
        throw new DBOperationException(format("ST_SQLDescribeParam failed! index:%d", idx));
        }
        //alias SQLRETURN function( SQLHSTMT, SQLUSMALLINT, SQLSMALLINT, SQLSMALLINT,SQLSMALLINT, SQLUINTEGER, SQLSMALLINT,
        //                                  SQLPOINTER, SQLINTEGER, SQLINTEGER * ) pfn_SQLBindParameter;
        //ST_SQLBindParameter
        paramTypes[idx] = sqlType;
        if(!(idx in paramBindValues))
        {
        throw new DBOperationException(format("param[%d] not binded!", idx));
        }

        //获取此参数的绑定值
        _debug(format("bind param, index[%d], value[%s]", idx, paramBindValues[idx]));
        ret = ST_SQLBindParameter(_hstmt, cast(SQLUSMALLINT)idx, SQL_PARAM_INPUT, SQL_C_DEFAULT, SQL_CHAR,
        cast(SQLUINTEGER)paramBindValues[idx].length, 0, cast(void*)paramBindValues[idx].ptr, paramBindValues[idx].length, null);
        if(ret != SQL_SUCCESS)
        {
        logHSTMTErrorInfo();
        }

        if(ret == SQL_ERROR || ret == SQL_INVALID_HANDLE)
        {
        throw new DBOperationException(format("ST_SQLBindParameter failed! index:%d", idx));
        }


        }
    }


    //获取下一行
    public bool nextRow()
    {
        SQLRETURN ret = ST_SQLFetch(_hstmt);
        if(ret != SQL_SUCCESS)
        {
            logHSTMTErrorInfo();
        }
        if(ret == SQL_ERROR
           || ret == SQL_INVALID_HANDLE)
        {
            throw new DBOperationException("Fetch NextRow Error!");
        }

        if(ret == SQL_NO_DATA
           || ret == SQL_NO_DATA_FOUND)
        {
            return false;
        }

        if(ret == SQL_STILL_EXECUTING)
        {
            throw new DBOperationException("Fetch NextRow Still Executing!");
        }

        return true;
    }

    public string getString(string colName)
    {
        _debug(format("getString(string) colName[%s]", colName));

        foreach(key, value; columnIndex)
        {
            _debug(format("key[%s],value[%d]", key, value));
        }
        if(colName in columnIndex)
        {
            return getString(columnIndex[colName]);
        }
        else
        {
            throw new DBOperationException(format("No such Column in Result!! [%s]", colName));
        }
    }

    public string getString(int idx)
    {
        import std.conv;

        _debug(std.format.format("getString, currentRow.length[%d], requestIdx[%d]", currentRow.length, idx));
        if(idx > currentRow.length)
        {
            import std.conv;
            throw new DBOperationException("column index beyond the max index[" ~ to!string(currentRow.length) ~ "]");
        }

        Variant var =  currentRow[idx];
        try
        {
            //_debug("getString: realLenths[idx] = " ~ to!string(*realLenths[idx]));
            if( realLenths[idx] !is null)
            {
                if(*realLenths[idx] <0)
                return "".idup;
            }

            //char[] value = var.get!(char[]);
            //string value = var.get!(string);
            string retStr;
            if(var.type == typeid(long*))
            {
                retStr = to!string(*var.get!(long*));
                _debug("long:[" ~ retStr ~ "]");
            }
            else if(var.type == typeid(char*))
            {
                //retStr = to!string(*var.get!(char*));
                retStr = to!string((*cast(char[]*)(var.get!(char*)))[0..*realLenths[idx]]);
                _debug("char:[" ~ retStr ~ "]");
            }
            else if(var.type == typeid(char[]))
            {
                retStr = to!string((var.get!(char[]))[0..*realLenths[idx]]);
                _debug("char[]:[" ~ retStr ~ "]");
            }
            else if(var.type == typeid(double*))
            {
                retStr = to!string(*var.get!(double*));
                _debug("double:[" ~ retStr ~ "]");
            }
            else
            {
                throw new DBOperationException("type not keep one way with execute");
            }

            return retStr;
        }
        catch(Throwable err)
        {
            throw new DBOperationException("getString failed! error:" ~ err.msg);
        }
    }
    //alias SQLRETURN function( in SQLHENV, in SQLUSMALLINT, out SQLCHAR *, in SQLSMALLINT, out SQLSMALLINT *,
                              //out SQLCHAR *, in SQLSMALLINT, out SQLSMALLINT * ) pfn_SQLDataSources;
}
++/