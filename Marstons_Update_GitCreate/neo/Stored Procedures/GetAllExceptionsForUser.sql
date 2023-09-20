CREATE PROCEDURE [neo].[GetAllExceptionsForUser] 
(
    @UserID     INT,
    @DatabaseID INT,
	@TradingDate DATETIME,
    @EDISID     INT = NULL,
	@ToCurrentDate BIT = NULL
)
AS

/* for testing purposes only */
--DECLARE @UserID INT     = 499
--DECLARE @DatabaseID INT = 18
/* for testing purposes only */

IF OBJECT_ID('tempdb.dbo.#UserExceptions', 'U') IS NOT NULL
BEGIN
  DROP TABLE #UserExceptions
END

CREATE TABLE #UserExceptions
(
	DatabaseID INT,
	EDISID INT,
	ID INT, 
	[Type] VARCHAR(255), 
	TypeID INT,
	ExceptionID INT,
	TradingDate DATE, 
	Value FLOAT, 
	LowThreshold VARCHAR(255), 
	HighThreshold VARCHAR(255), 
	SiteDescription VARCHAR(255), 
	[DateFormat] VARCHAR(50), 
	EmailReplyTo VARCHAR(255)
)

DECLARE @LocalUserID    INT
DECLARE	@ServerName     VARCHAR(255)
DECLARE @DatabaseName   VARCHAR(255)


DECLARE User_Cursor CURSOR FOR
SELECT DISTINCT
	[d2].[Server] AS [ServerName], 
	[d2].[Name] AS [DatabaseName], 
    [u2].[UserID]
FROM [dbo].[WebSiteUsers] AS [u]
INNER JOIN [dbo].[EDISDatabases] AS [d] ON [u].[DatabaseID] = [d].[ID]
INNER JOIN [dbo].[WebSiteUsers] AS [u2] ON [u].[Login] = [u2].[Login] AND [u].[Password] = [u2].[Password]
INNER JOIN [dbo].[EDISDatabases] AS [d2] ON [u2].[DatabaseID] = [d2].[ID]
WHERE
    [d].[ID] = @DatabaseID
AND	[u].[UserID] = @UserID
AND [d2].[Enabled] = 1
AND	[u2].[Expired] = 0

OPEN User_Cursor

FETCH NEXT FROM User_Cursor
INTO @ServerName, @DatabaseName, @LocalUserID

WHILE @@FETCH_STATUS = 0
BEGIN

	DECLARE @DatabaseString NVARCHAR(616) = N'[' + @ServerName + '].[' + @DatabaseName + '].'
    DECLARE @SiteString NVARCHAR(100) = CASE WHEN @EDISID IS NULL THEN N'' ELSE N', @EDISID = ' + CONVERT(NVARCHAR(10), @EDISID) END 
	-- GET THE USER TYPE
		
	--
	DECLARE @UserExceptionCommand NVARCHAR(MAX) = N'
		INSERT INTO #UserExceptions (DatabaseID, EDISID, ID, [Type], TypeID, TradingDate, Value, LowThreshold, HighThreshold, SiteDescription, [DateFormat], EmailReplyTo)
		EXEC ' + @DatabaseString + 'neo.GetCustomerSitesAndExceptionsForUser @UserID = ' + CONVERT(NVARCHAR(10), @LocalUserID) + @SiteString
		+ ', @TradingDate = ''' + CONVERT(varchar(23), @TradingDate, 121) + ''', @ToCurrentDate = ' + CONVERT(NVARCHAR(1), @ToCurrentDate) + ''
		print @UserExceptionCommand
	EXEC sp_executesql @UserExceptionCommand



	FETCH NEXT FROM User_Cursor
	INTO @ServerName, @DatabaseName, @LocalUserID
END

CLOSE User_Cursor
DEALLOCATE User_Cursor

SELECT 
	DatabaseID,
	EDISID,
	ID, 
	[Type], 
	TypeID,
	TradingDate, 
	Value, 
	LowThreshold, 
	HighThreshold, 
	SiteDescription, 
	[DateFormat], 
	EmailReplyTo
FROM #UserExceptions

IF OBJECT_ID('tempdb.dbo.#UserExceptions', 'U') IS NOT NULL
BEGIN
  DROP TABLE #UserExceptions
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetAllExceptionsForUser] TO PUBLIC
    AS [dbo];

