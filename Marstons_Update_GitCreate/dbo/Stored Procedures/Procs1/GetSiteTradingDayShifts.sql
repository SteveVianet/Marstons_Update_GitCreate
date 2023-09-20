CREATE PROCEDURE [dbo].[GetSiteTradingDayShifts]
(
	@EDISID			INT,
	@TradingDate	DATETIME
)
AS

SET DATEFIRST 1

DECLARE @Sites TABLE(EDISID INT)
DECLARE @SiteGroupID INT
DECLARE @PrimaryEDISID INT

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID = @EDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID
 
INSERT INTO @Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
 
IF @SiteGroupID IS NOT NULL
BEGIN
	SELECT @PrimaryEDISID = EDISID
	FROM SiteGroupSites
	WHERE SiteGroupSites.IsPrimary = 1
	AND SiteGroupID = @SiteGroupID
END
ELSE
BEGIN
	SET @PrimaryEDISID = @EDISID
END

SELECT	Sites.EDISID, 
		@TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME) AS ShiftStartTime,
		DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), @TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME)) AS ShiftEndTime
FROM Sites
JOIN OwnerTradingShifts ON OwnerTradingShifts.OwnerID = Sites.OwnerID AND OwnerTradingShifts.[DayOfWeek] = DATEPART(DW, @TradingDate)
LEFT JOIN SiteTradingShifts ON SiteTradingShifts.EDISID = Sites.EDISID AND SiteTradingShifts.[DayOfWeek] = DATEPART(DW, @TradingDate)
WHERE Sites.EDISID = @PrimaryEDISID
AND DATEPART(DW, @TradingDate) = COALESCE(SiteTradingShifts.[DayOfWeek], OwnerTradingShifts.[DayOfWeek])
GROUP BY Sites.EDISID, 
		@TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME),
		DATEADD(MINUTE, COALESCE(SiteTradingShifts.ShiftDurationMinutes, OwnerTradingShifts.ShiftDurationMinutes), @TradingDate + CAST(COALESCE(SiteTradingShifts.ShiftStartTime, OwnerTradingShifts.ShiftStartTime) AS TIME))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTradingDayShifts] TO PUBLIC
    AS [dbo];

