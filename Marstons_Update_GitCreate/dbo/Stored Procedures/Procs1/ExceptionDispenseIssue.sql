CREATE PROCEDURE [dbo].[ExceptionDispenseIssue]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */
--DECLARE @EDISID INT = NULL

SET DATEFIRST 1;

DECLARE @Today DATETIME = CAST(GETDATE() AS DATE)
DECLARE @DateOfInterest DATETIME = DATEADD(day, -1, CAST(GETDATE() AS DATE))
DECLARE @HourDifference INT = DATEDIFF(hour, @DateOfInterest, @Today)

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionDispenseIssue' -- Do we have permission to access this?
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, NULL, @Today
END

DECLARE @PintThreshold INT = 100

CREATE TABLE #Sites(EDISID INT, Hidden BIT)

INSERT INTO #Sites (EDISID, [Hidden])
SELECT Sites.EDISID, [Hidden]
FROM Sites
WHERE [Hidden] = 0
AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
AND [Status] IN (1, 3, 10) -- Installed (Active), Installed (Legals), Installed (Free-Of-Tie)
AND SiteOnline <= @DateOfInterest
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))

CREATE TABLE #Dispenses
(
	EDISID INT,
	[Date] DATETIME,
	[Shift] INT,
	Pump INT,
	ProductID INT,
	Quantity FLOAT
)

INSERT INTO #Dispenses
SELECT 
    [S].[EDISID],
    [MD].[Date], 
    [D].[Shift], 
    [D].[Pump],
	[P].ID,
    SUM([D].[Quantity]) AS [Quantity]
FROM #Sites [S]
INNER JOIN [dbo].[MasterDates] AS [MD] ON [S].[EDISID] = [MD].[EDISID]
INNER JOIN [dbo].[DLData] AS [D] ON [MD].[ID] = [D].[DownloadID]
INNER JOIN [dbo].[Products] AS [P] ON [D].[Product] = [P].[ID]
WHERE 
    [MD].[Date] = @DateOfInterest AND [MD].[Date] <= @Today
AND [P].[IsWater] = 0
GROUP BY 
    [S].[EDISID],
    [MD].[Date], 
    [D].[Shift], 
    [D].[Pump],
	[P].ID

DECLARE @ProblemPumps TABLE
(
	EDISID int,
	Pump int,
	ProductID int
)

INSERT INTO @ProblemPumps
SELECT DISTINCT
    [EDISID],
	d.[Pump],
	d.ProductID
FROM #Dispenses d
WHERE d.Quantity > @PintThreshold
UNION
SELECT DISTINCT
	[EDISID],
	d.[Pump],
	d.ProductID
FROM #Dispenses d
GROUP BY
	d.EDISID,
	d.[Date],
	d.Pump,
	d.ProductID
HAVING COUNT(1) >= @HourDifference

SELECT  EDISID, SUBSTRING (
		(
		SELECT ';' + CAST(Pump AS varchar(255))
		FROM @ProblemPumps WHERE 
			EDISID = Results.EDISID
		FOR XML PATH (''),TYPE).value('.','VARCHAR(4000)')
		,2,4000
	) AS ProductList, ProductID, Pump
FROM @ProblemPumps Results --removed group by as we now need separate notifications for each product 
--(generate notifications should ensure multiple notifications aren't raised in SiteNotification, just stored against product) 

DROP TABLE #Dispenses
DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionDispenseIssue] TO PUBLIC
    AS [dbo];

