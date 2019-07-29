
## [转载](https://blog.csdn.net/qh_java/article/details/50413293)

## [转载](https://blog.csdn.net/qh_java/article/details/50421859)


# mysql jdbc驱动源码分析（获取Statement对象）


在前面的文章中我们分析了获取Connection 对象的代码，下面来看看获取Statement的源码：

ConnectionImpl类的createStatement() 方法获取Statement实例

```java

// 获取Statement对象，没有参数则使用默认的参数  
   public java.sql.Statement createStatement() throws SQLException {  
    // 这里的默认值就是在获得ResultSet的值后，不能滚动只能向后移动  
       return createStatement(DEFAULT_RESULT_SET_TYPE, DEFAULT_RESULT_SET_CONCURRENCY);  
   }  
```

```java
public java.sql.Statement createStatement(int resultSetType, int resultSetConcurrency) throws SQLException {

     // StatementImpl 的两个参数，一个是当前数据库的链接Connection 一个是当前用的数据库      
    StatementImpl stmt = new StatementImpl(getMultiHostSafeProxy(), this.database);
    stmt.setResultSetType(resultSetType);
    stmt.setResultSetConcurrency(resultSetConcurrency);
    // 创建statement对象。  
    return stmt;
}

```
StatementImpl对象的获取从上面的代码中能看到是创建了一个StatementImpl对象,
StatementImpl 构造函数源码如下：

```java
/**
 * Constructor for a Statement.
 * 
 * @param c
 *            the Connection instance that creates us
 * @param catalog
 *            the database name in use when we were created
 * 
 * @throws SQLException
 *             if an error occurs.
 */
public StatementImpl(JdbcConnection c, String catalog) throws SQLException {
      //判断当前的链接有没有断开，如果为空或是断开了则抛出异常  
    if ((c == null) || c.isClosed()) {
        throw SQLError.createSQLException(Messages.getString("Statement.0"), MysqlErrorNumbers.SQL_STATE_CONNECTION_NOT_OPEN, null);
    }

    this.connection = c;
    this.session = (NativeSession) c.getSession();
    this.exceptionInterceptor = c.getExceptionInterceptor();

    initQuery();

    this.query.setCurrentCatalog(catalog);

    JdbcPropertySet pset = c.getPropertySet();

    this.dontTrackOpenResources = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_dontTrackOpenResources);
    this.dumpQueriesOnException = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_dumpQueriesOnException);
    this.continueBatchOnError = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_continueBatchOnError).getValue();
    this.pedantic = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_pedantic).getValue();
    this.rewriteBatchedStatements = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_rewriteBatchedStatements);
    this.charEncoding = pset.getStringReadableProperty(PropertyDefinitions.PNAME_characterEncoding).getValue();
    this.profileSQL = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_profileSQL).getValue();
    this.useUsageAdvisor = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_useUsageAdvisor).getValue();
    this.logSlowQueries = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_logSlowQueries).getValue();
    this.maxAllowedPacket = pset.getIntegerReadableProperty(PropertyDefinitions.PNAME_maxAllowedPacket);
    this.dontCheckOnDuplicateKeyUpdateInSQL = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_dontCheckOnDuplicateKeyUpdateInSQL).getValue();
    this.sendFractionalSeconds = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_sendFractionalSeconds);
    this.doEscapeProcessing = pset.getBooleanReadableProperty(PropertyDefinitions.PNAME_enableEscapeProcessing).getValue();

    this.maxFieldSize = this.maxAllowedPacket.getValue();

    if (!this.dontTrackOpenResources.getValue()) {
        c.registerStatement(this);
    }

    int defaultFetchSize = pset.getIntegerReadableProperty(PropertyDefinitions.PNAME_defaultFetchSize).getValue();
    if (defaultFetchSize != 0) {
        setFetchSize(defaultFetchSize);
    }

    boolean profiling = this.profileSQL || this.useUsageAdvisor || this.logSlowQueries;

    if (profiling) {
        this.pointOfOrigin = LogUtils.findCallingClassAndMethod(new Throwable());
        try {
            this.query.setEventSink(ProfilerEventHandlerFactory.getInstance(this.session));
        } catch (CJException e) {
            throw SQLExceptionsMapping.translateException(e, getExceptionInterceptor());
        }
    }

    int maxRowsConn = pset.getIntegerReadableProperty(PropertyDefinitions.PNAME_maxRows).getValue();

    if (maxRowsConn != -1) {
        setMaxRows(maxRowsConn);
    }

    this.holdResultsOpenOverClose = pset.<Boolean> getModifiableProperty(PropertyDefinitions.PNAME_holdResultsOpenOverStatementClose).getValue();

    this.resultSetFactory = new ResultSetFactory(this.connection, this);
}

```


到这里StatementImpl 对象就创建了，从构造函数我们可以看出，
创建的过程就是设置了一些结果集展示的属性，如最大行数，字符编码等，
不管设置什么属性他们都是依赖于当前的链接即Connection 对象的，
如果Connection为null 或者链接被关闭了则会报异常，
即null 或者SQLError.SQL_STATE_CONNECTION_NOT_OPEN 
所以，创建Statement对象的基础是要有Connection。
还有如果有空闲的Statement我们可以重用，不用再次创建Statement对象。

 


## mysql jdbc驱动源码分析（Statement的executeQuery 和executeUpdate方法）

> 基于 mysql-connect-java-8.0.11

在前面的章节中我们获取了Statement对象，下面我们来看看Statement的executeQuery() 和executeUpdate() 方法来执行相关操作。

首先来看看StatementImpl对象的executeQuery() 方法，源码如下：


```java

 /**
     * Execute a SQL statement that returns a single ResultSet
     * 
     * @param sql
     *            typically a static SQL SELECT statement
     * 
     * @return a ResulSet that contains the data produced by the query
     * 
     * @exception SQLException
     *                if a database access error occurs
     */
    // 查询方法，执行给定的sql获取返回结果集  
    public java.sql.ResultSet executeQuery(String sql) throws SQLException {
        synchronized (checkClosed().getConnectionMutex()) {
            
            // mysql 服务的链接  
            JdbcConnection locallyScopedConn = this.connection;

            this.retrieveGeneratedKeys = false;

            // 检测sql是不是null,或者sql.length=0,如果为null 或为0 则抛出异常
            checkNullOrEmptyQuery(sql);

            resetCancelledState();

            implicitlyCloseAllOpenResults();

            if (sql.charAt(0) == '/') {
                if (sql.startsWith(PING_MARKER)) {
                    doPingInstead();

                    return this.results;
                }
            }
            // 设置超时  
            setupStreamingTimeout(locallyScopedConn);

            if (this.doEscapeProcessing) {
                
                // 开始执行，执行sql语句，获取结果  
                Object escapedSqlResult = EscapeProcessor.escapeSQL(sql, this.session.getServerSession().getDefaultTimeZone(),
                        this.session.getServerSession().getCapabilities().serverSupportsFracSecs(), getExceptionInterceptor());
                sql = escapedSqlResult instanceof String ? (String) escapedSqlResult : ((EscapeProcessorResult) escapedSqlResult).escapedSql;
            }

            char firstStatementChar = StringUtils.firstAlphaCharUc(sql, findStartOfStatement(sql));

            checkForDml(sql, firstStatementChar);

            CachedResultSetMetaData cachedMetaData = null;

            if (useServerFetch()) {
                this.results = createResultSetUsingServerFetch(sql);

                return this.results;
            }

            CancelQueryTask timeoutTask = null;

            String oldCatalog = null;

            try {
                timeoutTask = startQueryTimer(this, getTimeoutInMillis());

                if (!locallyScopedConn.getCatalog().equals(getCurrentCatalog())) {
                    oldCatalog = locallyScopedConn.getCatalog();
                    locallyScopedConn.setCatalog(getCurrentCatalog());
                }

                //
                // Check if we have cached metadata for this query...
                // 检测这个查询语句有没有缓存，如果有则直接取缓存  
                if (locallyScopedConn.getPropertySet().getBooleanReadableProperty(PropertyDefinitions.PNAME_cacheResultSetMetadata).getValue()) {
                    cachedMetaData = locallyScopedConn.getCachedMetaData(sql);
                }

                locallyScopedConn.setSessionMaxRows(this.maxRows);

                statementBegins();

                // 调用 MysqlConnection 的方法 getSession(); 获取 com.mysql.cj.Session 
                // 调用 com.mysql.cj.NativeSession 的 execSQL() 方法来执行给定的sql语句，返回结构集  
                this.results = ((NativeSession) locallyScopedConn.getSession()).execSQL(this, sql, this.maxRows, null, createStreamingResultSet(),
                        getResultSetFactory(), getCurrentCatalog(), cachedMetaData, false);

                if (timeoutTask != null) {
                    stopQueryTimer(timeoutTask, true, true);
                    timeoutTask = null;
                }

            } catch (CJTimeoutException | OperationCancelledException e) {
                throw SQLExceptionsMapping.translateException(e, this.exceptionInterceptor);

            } finally {
                this.query.getStatementExecuting().set(false);

                stopQueryTimer(timeoutTask, false, false);

                if (oldCatalog != null) {
                    locallyScopedConn.setCatalog(oldCatalog);
                }
            }

            this.lastInsertId = this.results.getUpdateID();

            if (cachedMetaData != null) {
                locallyScopedConn.initializeResultsMetadataFromCache(sql, cachedMetaData, this.results);
            } else {
                if (this.connection.getPropertySet().getBooleanReadableProperty(PropertyDefinitions.PNAME_cacheResultSetMetadata).getValue()) {
                    locallyScopedConn.initializeResultsMetadataFromCache(sql, null /* will be created */, this.results);
                }
            }

            return this.results;
        }
    }
```


在上面我们看到了具体的方法是在 NativeSession这个类中。下面这个这个类中的execSQL（）方法，源码如下：

```java
/**
 * Send a query to the server. Returns one of the ResultSet objects.
 * To ensure that Statement's queries are serialized, calls to this method
 * should be enclosed in a connection mutex synchronized block.
 * 
 * @param callingQuery
 * @param query
 *            the SQL statement to be executed
 * @param maxRows
 * @param packet
 * @param streamResults
 * @param catalog
 * @param cachedMetadata
 * @param isBatch
 * @return a ResultSet holding the results
 */
// 向服务发送查询语句，而获取一个ResultSet object
public <T extends Resultset> T execSQL(Query callingQuery, String query, int maxRows, NativePacketPayload packet, boolean streamResults,
        ProtocolEntityFactory<T, NativePacketPayload> resultSetFactory, String catalog, ColumnDefinition cachedMetadata, boolean isBatch) {

    long queryStartTime = 0;
    int endOfQueryPacketPosition = 0;
    if (packet != null) {
        endOfQueryPacketPosition = packet.getPosition();
    }

    if (this.gatherPerfMetrics.getValue()) {
        queryStartTime = System.currentTimeMillis();
    }

    this.lastQueryFinishedTime = 0; // we're busy!

    if (this.autoReconnect.getValue() && (getServerSession().isAutoCommit() || this.autoReconnectForPools.getValue()) && this.needsPing && !isBatch) {
        try {
            ping(false, 0);
            this.needsPing = false;

        } catch (Exception Ex) {
            invokeReconnectListeners();
        }
    }

    try {
        if (packet == null) {
            String encoding = this.characterEncoding.getValue();
            //将存储在数据包中的查询发送到服务器。
            return ((NativeProtocol) this.protocol).sendQueryString(callingQuery, query, encoding, maxRows, streamResults, catalog, cachedMetadata,
                    this::getProfilerEventHandlerInstanceFunction, resultSetFactory);
        }
        return ((NativeProtocol) this.protocol).sendQueryPacket(callingQuery, packet, maxRows, streamResults, catalog, cachedMetadata,
                this::getProfilerEventHandlerInstanceFunction, resultSetFactory);

    } catch (CJException sqlE) {
        if (getPropertySet().getBooleanReadableProperty(PropertyDefinitions.PNAME_dumpQueriesOnException).getValue()) {
            String extractedSql = NativePacketPayload.extractSqlFromPacket(query, packet, endOfQueryPacketPosition,
                    getPropertySet().getIntegerReadableProperty(PropertyDefinitions.PNAME_maxQuerySizeToLog).getValue());
            StringBuilder messageBuf = new StringBuilder(extractedSql.length() + 32);
            messageBuf.append("\n\nQuery being executed when exception was thrown:\n");
            messageBuf.append(extractedSql);
            messageBuf.append("\n\n");
            sqlE.appendMessage(messageBuf.toString());
        }

        if ((this.autoReconnect.getValue())) {
            if (sqlE instanceof CJCommunicationsException) {
                // IO may be dirty or damaged beyond repair, force close it.
                this.protocol.getSocketConnection().forceClose();
            }
            this.needsPing = true;
        } else if (sqlE instanceof CJCommunicationsException) {
            invokeCleanupListeners(sqlE);
        }
        throw sqlE;

    } catch (Throwable ex) {
        if (this.autoReconnect.getValue()) {
            if (ex instanceof IOException) {
                // IO may be dirty or damaged beyond repair, force close it.
                this.protocol.getSocketConnection().forceClose();
            } else if (ex instanceof IOException) {
                invokeCleanupListeners(ex);
            }
            this.needsPing = true;
        }
        throw ExceptionFactory.createException(ex.getMessage(), ex, this.exceptionInterceptor);

    } finally {
        if (this.maintainTimeStats.getValue()) {
            this.lastQueryFinishedTime = System.currentTimeMillis();
        }

        if (this.gatherPerfMetrics.getValue()) {
            long queryTime = System.currentTimeMillis() - queryStartTime;

            registerQueryExecutionTime(queryTime);
        }
    }

}
```

调用 NativeProtocol 方法

```java
/**
 * Send a query stored in a packet to the server.
 * 
 * @param callingQuery
 * @param queryPacket
 * @param maxRows
 * @param streamResults
 * @param catalog
 * @param cachedMetadata
 * @param getProfilerEventHandlerInstanceFunction
 * @param resultSetFactory
 * @return
 * @throws IOException
 */
public final <T extends Resultset> T sendQueryPacket(Query callingQuery, NativePacketPayload queryPacket, int maxRows, boolean streamResults,
        String catalog, ColumnDefinition cachedMetadata, GetProfilerEventHandlerInstanceFunction getProfilerEventHandlerInstanceFunction,
        ProtocolEntityFactory<T, NativePacketPayload> resultSetFactory) throws IOException {
    this.statementExecutionDepth++;

    byte[] queryBuf = null;
    int oldPacketPosition = 0;
    long queryStartTime = 0;
    long queryEndTime = 0;

    queryBuf = queryPacket.getByteBuffer();
    oldPacketPosition = queryPacket.getPosition(); // save the packet position

    queryStartTime = getCurrentTimeNanosOrMillis();

    LazyString query = new LazyString(queryBuf, 1, (oldPacketPosition - 1));

    try {

        if (this.queryInterceptors != null) {
            T interceptedResults = invokeQueryInterceptorsPre(query, callingQuery, false);

            if (interceptedResults != null) {
                return interceptedResults;
            }
        }

        if (this.autoGenerateTestcaseScript) {
            StringBuilder debugBuf = new StringBuilder(query.length() + 32);
            generateQueryCommentBlock(debugBuf);
            debugBuf.append(query);
            debugBuf.append(';');
            TestUtils.dumpTestcaseQuery(debugBuf.toString());
        }

        // Send query command and sql query string
        // 发送 查询包 给 mysql 服务
        NativePacketPayload resultPacket = sendCommand(queryPacket, false, 0);

        long fetchBeginTime = 0;
        long fetchEndTime = 0;

        String profileQueryToLog = null;

        boolean queryWasSlow = false;

        if (this.profileSQL || this.logSlowQueries) {
            queryEndTime = getCurrentTimeNanosOrMillis();

            boolean shouldExtractQuery = false;

            if (this.profileSQL) {
                shouldExtractQuery = true;
            } else if (this.logSlowQueries) {
                long queryTime = queryEndTime - queryStartTime;

                boolean logSlow = false;

                if (!this.useAutoSlowLog) {
                    logSlow = queryTime > this.propertySet.getIntegerReadableProperty(PropertyDefinitions.PNAME_slowQueryThresholdMillis).getValue();
                } else {
                    logSlow = this.metricsHolder.isAbonormallyLongQuery(queryTime);
                    this.metricsHolder.reportQueryTime(queryTime);
                }

                if (logSlow) {
                    shouldExtractQuery = true;
                    queryWasSlow = true;
                }
            }

            if (shouldExtractQuery) {
                // Extract the actual query from the network packet
                boolean truncated = false;

                int extractPosition = oldPacketPosition;

                if (oldPacketPosition > this.maxQuerySizeToLog.getValue()) {
                    extractPosition = this.maxQuerySizeToLog.getValue() + 1;
                    truncated = true;
                }

                profileQueryToLog = StringUtils.toString(queryBuf, 1, (extractPosition - 1));

                if (truncated) {
                    profileQueryToLog += Messages.getString("Protocol.2");
                }
            }

            fetchBeginTime = queryEndTime;
        }

        T rs = readAllResults(maxRows, streamResults, resultPacket, false, cachedMetadata, resultSetFactory);

        long threadId = getServerSession().getCapabilities().getThreadId();
        int queryId = (callingQuery != null) ? callingQuery.getId() : 999;
        int resultSetId = rs.getResultId();
        long eventDuration = queryEndTime - queryStartTime;

        if (queryWasSlow && !this.serverSession.queryWasSlow() /* don't log slow queries twice */) {
            StringBuilder mesgBuf = new StringBuilder(48 + profileQueryToLog.length());

            mesgBuf.append(Messages.getString("Protocol.SlowQuery",
                    new Object[] { String.valueOf(this.useAutoSlowLog ? " 95% of all queries " : this.slowQueryThreshold), this.queryTimingUnits,
                            Long.valueOf(queryEndTime - queryStartTime) }));
            mesgBuf.append(profileQueryToLog);

            ProfilerEventHandler eventSink = getProfilerEventHandlerInstanceFunction.apply();

            eventSink.consumeEvent(
                    new ProfilerEventImpl(ProfilerEvent.TYPE_SLOW_QUERY, "", catalog, threadId, queryId, resultSetId, System.currentTimeMillis(),
                            eventDuration, this.queryTimingUnits, null, LogUtils.findCallingClassAndMethod(new Throwable()), mesgBuf.toString()));

            if (this.propertySet.getBooleanReadableProperty(PropertyDefinitions.PNAME_explainSlowQueries).getValue()) {
                if (oldPacketPosition < MAX_QUERY_SIZE_TO_EXPLAIN) {
                    queryPacket.setPosition(1); // skip first byte 
                    explainSlowQuery(query.toString(), profileQueryToLog);
                } else {
                    this.log.logWarn(Messages.getString("Protocol.3", new Object[] { MAX_QUERY_SIZE_TO_EXPLAIN }));
                }
            }
        }

        if (this.profileSQL || this.logSlowQueries) {

            ProfilerEventHandler eventSink = getProfilerEventHandlerInstanceFunction.apply();

            String eventCreationPoint = LogUtils.findCallingClassAndMethod(new Throwable());

            if (this.logSlowQueries) {
                if (this.serverSession.noGoodIndexUsed()) {
                    eventSink.consumeEvent(
                            new ProfilerEventImpl(ProfilerEvent.TYPE_SLOW_QUERY, "", catalog, threadId, queryId, resultSetId, System.currentTimeMillis(),
                                    eventDuration, this.queryTimingUnits, null, eventCreationPoint, Messages.getString("Protocol.4") + profileQueryToLog));
                }
                if (this.serverSession.noIndexUsed()) {
                    eventSink.consumeEvent(
                            new ProfilerEventImpl(ProfilerEvent.TYPE_SLOW_QUERY, "", catalog, threadId, queryId, resultSetId, System.currentTimeMillis(),
                                    eventDuration, this.queryTimingUnits, null, eventCreationPoint, Messages.getString("Protocol.5") + profileQueryToLog));
                }
                if (this.serverSession.queryWasSlow()) {
                    eventSink.consumeEvent(new ProfilerEventImpl(ProfilerEvent.TYPE_SLOW_QUERY, "", catalog, threadId, queryId, resultSetId,
                            System.currentTimeMillis(), eventDuration, this.queryTimingUnits, null, eventCreationPoint,
                            Messages.getString("Protocol.ServerSlowQuery") + profileQueryToLog));
                }
            }

            fetchEndTime = getCurrentTimeNanosOrMillis();

            eventSink.consumeEvent(new ProfilerEventImpl(ProfilerEvent.TYPE_QUERY, "", catalog, threadId, queryId, resultSetId, System.currentTimeMillis(),
                    eventDuration, this.queryTimingUnits, null, eventCreationPoint, profileQueryToLog));

            eventSink.consumeEvent(new ProfilerEventImpl(ProfilerEvent.TYPE_FETCH, "", catalog, threadId, queryId, resultSetId, System.currentTimeMillis(),
                    (fetchEndTime - fetchBeginTime), this.queryTimingUnits, null, eventCreationPoint, null));
        }

        if (this.hadWarnings) {
            scanForAndThrowDataTruncation();
        }

        if (this.queryInterceptors != null) {
            T interceptedResults = invokeQueryInterceptorsPost(query, callingQuery, rs, false);

            if (interceptedResults != null) {
                rs = interceptedResults;
            }
        }

        return rs;
    } catch (CJException sqlEx) {
        if (this.queryInterceptors != null) {
            invokeQueryInterceptorsPost(query, callingQuery, null, false); // we don't do anything with the result set in this case
        }

        if (callingQuery != null) {
            callingQuery.checkCancelTimeout();
        }

        throw sqlEx;

    } finally {
        this.statementExecutionDepth--;
    }
}


```

com.mysql.cj.protocol.Protocol 接口

```java

 /**
     * Send a command to the MySQL server.
     * 
     * @param queryPacket
     *            a packet pre-loaded with data for the protocol (eg.
     *            from a client-side prepared statement). The first byte of
     *            this packet is the MySQL protocol 'command' from MysqlDefs
     * @param skipCheck
     *            do not call checkErrorPacket() if true
     * @param timeoutMillis
     *            timeout
     * 
     * @return the response packet from the server
     * 
     * @throws CJException
     *             if an I/O error or SQL error occurs
     */

    M sendCommand(Message queryPacket, boolean skipCheck, int timeoutMillis);
```

com.mysql.cj.protocol.Protocol 实现方法 NativePacketPayload 类

```java
 @Override
public final NativePacketPayload sendCommand(Message queryPacket, boolean skipCheck, int timeoutMillis) {
    int command = queryPacket.getByteBuffer()[0];
    this.commandCount++;

    if (this.queryInterceptors != null) {
        NativePacketPayload interceptedPacketPayload = (NativePacketPayload) invokeQueryInterceptorsPre(queryPacket, false);

        if (interceptedPacketPayload != null) {
            return interceptedPacketPayload;
        }
    }

    this.packetReader.resetMessageSequence();

    int oldTimeout = 0;

    if (timeoutMillis != 0) {
        try {
            oldTimeout = this.socketConnection.getMysqlSocket().getSoTimeout();
            this.socketConnection.getMysqlSocket().setSoTimeout(timeoutMillis);
        } catch (SocketException e) {
            throw ExceptionFactory.createCommunicationsException(this.propertySet, this.serverSession,
                    this.getPacketSentTimeHolder().getLastPacketSentTime(), this.getPacketReceivedTimeHolder().getLastPacketReceivedTime(), e,
                    getExceptionInterceptor());
        }
    }

    try {

        checkForOutstandingStreamingData();

        // Clear serverStatus...this value is guarded by an external mutex, as you can only ever be processing one command at a time
        this.serverSession.setStatusFlags(0, true);
        this.hadWarnings = false;
        this.setWarningCount(0);

        //
        // Compressed input stream needs cleared at beginning of each command execution...
        //
        if (this.useCompression) {
            int bytesLeft = this.socketConnection.getMysqlInput().available();

            if (bytesLeft > 0) {
                this.socketConnection.getMysqlInput().skip(bytesLeft);
            }
        }

        try {
            clearInputStream();
            this.packetSequence = -1;
            
            // 发送包
            send(queryPacket, queryPacket.getPosition());

        } catch (CJException ex) {
            // don't wrap CJExceptions
            throw ex;
        } catch (Exception ex) {
            throw ExceptionFactory.createCommunicationsException(this.propertySet, this.serverSession,
                    this.getPacketSentTimeHolder().getLastPacketSentTime(), this.getPacketReceivedTimeHolder().getLastPacketReceivedTime(), ex,
                    getExceptionInterceptor());
        }

        NativePacketPayload returnPacket = null;

        if (!skipCheck) {
            if ((command == NativeConstants.COM_STMT_EXECUTE) || (command == NativeConstants.COM_STMT_RESET)) {
                this.packetReader.resetMessageSequence();
            }

            returnPacket = checkErrorMessage(command);

            if (this.queryInterceptors != null) {
                returnPacket = (NativePacketPayload) invokeQueryInterceptorsPost(queryPacket, returnPacket, false);
            }
        }

        return returnPacket;
    } catch (IOException ioEx) {
        this.serverSession.preserveOldTransactionState();
        throw ExceptionFactory.createCommunicationsException(this.propertySet, this.serverSession, this.getPacketSentTimeHolder().getLastPacketSentTime(),
                this.getPacketReceivedTimeHolder().getLastPacketReceivedTime(), ioEx, getExceptionInterceptor());
    } catch (CJException e) {
        this.serverSession.preserveOldTransactionState();
        throw e;

    } finally {
        if (timeoutMillis != 0) {
            try {
                this.socketConnection.getMysqlSocket().setSoTimeout(oldTimeout);
            } catch (SocketException e) {
                throw ExceptionFactory.createCommunicationsException(this.propertySet, this.serverSession,
                        this.getPacketSentTimeHolder().getLastPacketSentTime(), this.getPacketReceivedTimeHolder().getLastPacketReceivedTime(), e,
                        getExceptionInterceptor());
            }
        }
    }
}

```

NativePacketPayload 类 方法 

```java

/**
 * @param packet
 * @param packetLen
 *            length of header + payload
 */
@Override
public final void send(Message packet, int packetLen) {
    try {
        if (this.maxAllowedPacket.getValue() > 0 && packetLen > this.maxAllowedPacket.getValue()) {
            throw new CJPacketTooBigException(packetLen, this.maxAllowedPacket.getValue());
        }

        this.packetSequence++;
        
        // 调用发包  
        this.packetSender.send(packet.getByteBuffer(), packetLen, this.packetSequence);

        //
        // Don't hold on to large packets
        //
        if (packet == this.sharedSendPacket) {
            reclaimLargeSharedSendPacket();
        }
    } catch (IOException ioEx) {
        throw ExceptionFactory.createCommunicationsException(this.getPropertySet(), this.serverSession,
                this.getPacketSentTimeHolder().getLastPacketSentTime(), this.getPacketReceivedTimeHolder().getLastPacketReceivedTime(), ioEx,
                getExceptionInterceptor());
    }
}

```

CompressedPacketSender.java

发送 package

```java
 /**
 * Packet sender implementation for the compressed MySQL protocol. 
 * For compressed transmission of multi-packets, split the packets up in the same way as the
 * uncompressed protocol. We fit up to MAX_PACKET_SIZE bytes of split uncompressed packet, 
 * including the header, into an compressed packet. The first packet
 * of the multi-packet is 4 bytes of header and MAX_PACKET_SIZE - 4 bytes of the payload. 
 * The next packet must send the remaining four bytes of the payload
 * followed by a new header and payload. If the second split packet is also around MAX_PACKET_SIZE in length, 
 * then only MAX_PACKET_SIZE - 4 (from the
 * previous packet) - 4 (for the new header) can be sent. 
 * This means the payload will be limited by 8 bytes and this will continue to increase by 4 at every
 * iteration.
 */
public void send(byte[] packet, int packetLen, byte packetSequence) throws IOException {
    this.compressedSequenceId = packetSequence;

    // short-circuit send small packets without compression and return
    if (packetLen < MIN_COMPRESS_LEN) {
        writeCompressedHeader(packetLen + NativeConstants.HEADER_LENGTH, this.compressedSequenceId, 0);
        writeUncompressedHeader(packetLen, packetSequence);
        this.outputStream.write(packet, 0, packetLen);
        this.outputStream.flush();
        return;
    }

    if (packetLen + NativeConstants.HEADER_LENGTH > NativeConstants.MAX_PACKET_SIZE) {
        this.compressedPacket = new byte[NativeConstants.MAX_PACKET_SIZE];
    } else {
        this.compressedPacket = new byte[NativeConstants.HEADER_LENGTH + packetLen];
    }

    PacketSplitter packetSplitter = new PacketSplitter(packetLen);

    int unsentPayloadLen = 0;
    int unsentOffset = 0;
    // loop over constructing and sending compressed packets
    while (true) {
        this.compressedPayloadLen = 0;

        if (packetSplitter.nextPacket()) {
            // rest of previous packet
            if (unsentPayloadLen > 0) {
                addPayload(packet, unsentOffset, unsentPayloadLen);
            }

            // current packet
            int remaining = NativeConstants.MAX_PACKET_SIZE - unsentPayloadLen;
            // if remaining is 0 then we are sending a very huge packet such that are 4-byte header-size carryover from last packet accumulated to the size
            // of a whole packet itself. We don't handle this. Would require 4 million packet segments (64 gigs in one logical packet)
            int len = Math.min(remaining, NativeConstants.HEADER_LENGTH + packetSplitter.getPacketLen());
            int lenNoHdr = len - NativeConstants.HEADER_LENGTH;
            addUncompressedHeader(packetSequence, packetSplitter.getPacketLen());
            addPayload(packet, packetSplitter.getOffset(), lenNoHdr);

            completeCompression();
            // don't send payloads with incompressible data
            if (this.compressedPayloadLen >= len) {
                // combine the unsent and current packet in an uncompressed packet
                writeCompressedHeader(unsentPayloadLen + len, this.compressedSequenceId++, 0);
                this.outputStream.write(packet, unsentOffset, unsentPayloadLen);
                writeUncompressedHeader(lenNoHdr, packetSequence);
                this.outputStream.write(packet, packetSplitter.getOffset(), lenNoHdr);
            } else {
                sendCompressedPacket(len + unsentPayloadLen);
            }

            packetSequence++;
            unsentPayloadLen = packetSplitter.getPacketLen() - lenNoHdr;
            unsentOffset = packetSplitter.getOffset() + lenNoHdr;
            resetPacket();
        } else if (unsentPayloadLen > 0) {
            // no more packets, send remaining unsent data
            addPayload(packet, unsentOffset, unsentPayloadLen);
            completeCompression();
            if (this.compressedPayloadLen >= unsentPayloadLen) {
                writeCompressedHeader(unsentPayloadLen, this.compressedSequenceId, 0);
                this.outputStream.write(packet, unsentOffset, unsentPayloadLen);
            } else {
                sendCompressedPacket(unsentPayloadLen);
            }
            resetPacket();
            break;
        } else {
            // nothing left to send (only happens on boundaries)
            break;
        }
    }

    this.outputStream.flush();

    // release reference to (possibly large) compressed packet buffer
    this.compressedPacket = null;
}

    
```

```java
/**
 * Send a compressed packet.
 */
private void sendCompressedPacket(int uncompressedPayloadLen) throws IOException {
    writeCompressedHeader(this.compressedPayloadLen, this.compressedSequenceId++, uncompressedPayloadLen);

    // compressed payload
    this.outputStream.write(this.compressedPacket, 0, this.compressedPayloadLen);
}
```


简单总结：

我们从整个过程中看到，所有的基础都是Connection 即客户端和服务端的链接也就是和服务器Socket的链接，如果socket断了，就不能进行沟通了。
而当有了Socket之后我们可以执行查询方法或更新方法来获取结果集对象，但是在获取结果集对象的时候我们要设置结果集的类型，
因为设置不同的结果集类型，我们对获得的结果集对象ResultSet对象会有不同的操作即有的可以向结果集前端移动动，
有的可以向结果集后端移动等等，这些都要在生成ResultSet 对象前进行设置。



其实看源码的目的是更清楚，明白的了解jdbc的整个过程但是，在看的过程中发现，能力有限，不能静下心来一个一个的看懂，
而只能草草的结束，从中了解了大体过程，但是提升不大，希望下次来一次的时候能够有提升，不过学习的时候还是有些收获在会后的一篇中会进行总结。