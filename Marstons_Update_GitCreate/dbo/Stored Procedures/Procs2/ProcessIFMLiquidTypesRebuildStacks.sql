CREATE PROCEDURE [dbo].[ProcessIFMLiquidTypesRebuildStacks]
(
    @Locale VARCHAR(255) = NULL
)
AS
BEGIN

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @From			DATETIME
DECLARE @To				DATETIME
DECLARE @TestSiteID		VARCHAR(255)
DECLARE @TestPump		INT

SET @From = DATEADD(Day, -7, CAST(CONVERT(VARCHAR(10), GETDATE(), 12) AS DATETIME))
SET @To = DATEADD(Day, -1, CAST(CONVERT(VARCHAR(10), GETDATE(), 12) AS DATETIME))
SET @TestSiteID = NULL
SET @TestPump = NULL

--SET @From = '2011-10-03'
--SET @To = '2011-10-04'
--SET @TestSiteID = '034461'
--SET @TestPump = 3

-- *********************************************************************************************
-- Stage 4
-- All DLData/WaterStack/CleanerStack changes are sorted, so re-build legacy tables.
DECLARE @ThisSiteEDISID INT
DECLARE @ThisSiteEarliestDispense DATETIME

DECLARE curRebuildStacks CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT Sites.EDISID, MIN(StartTime)
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
	LEFT JOIN (
        SELECT SiteProperties.EDISID, SiteProperties.Value AS International
        FROM Properties
        JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
        WHERE Properties.Name = 'International'
        ) AS SiteLocations ON SiteLocations.EDISID = Sites.EDISID
	WHERE (StartTime BETWEEN @From AND @To)	-- *&******************** GET ONLY DATE!!!
	AND (Sites.SiteID = @TestSiteID OR @TestSiteID IS NULL)
	AND Products.IsMetric = 0
	AND Sites.LastDownload > @From	-- is this wise?
	AND (Pump = @TestPump OR @TestPump IS NULL)
	AND Sites.Status <> 9
	AND ((@Locale IS NOT NULL AND SiteLocations.International = @Locale)
	    OR (@Locale IS NULL))
	GROUP BY Sites.EDISID
	
OPEN curRebuildStacks
FETCH NEXT FROM curRebuildStacks INTO @ThisSiteEDISID, @ThisSiteEarliestDispense
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @ThisSiteEarliestDispense = CAST(CONVERT(VARCHAR(10), @ThisSiteEarliestDispense, 12) AS DATETIME)
	IF @ThisSiteEarliestDispense > @From
	BEGIN
		EXEC dbo.RebuildStacksFromDispenseConditions NULL, @ThisSiteEDISID, @ThisSiteEarliestDispense, @To
		--PRINT 'Rebuild xxx from ' + CAST(@ThisSiteEarliestDispense AS VARCHAR) + ' to ' + CAST(@To AS VARCHAR)
		
	END

	ELSE
	BEGIN
		EXEC dbo.RebuildStacksFromDispenseConditions NULL, @ThisSiteEDISID, @From, @To
		--PRINT 'Rebuild yyy from ' + CAST(@From AS VARCHAR) + ' to ' + CAST(@To AS VARCHAR)

	END

	FETCH NEXT FROM curRebuildStacks INTO @ThisSiteEDISID, @ThisSiteEarliestDispense

END

CLOSE curRebuildStacks
DEALLOCATE curRebuildStacks

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ProcessIFMLiquidTypesRebuildStacks] TO PUBLIC
    AS [dbo];

