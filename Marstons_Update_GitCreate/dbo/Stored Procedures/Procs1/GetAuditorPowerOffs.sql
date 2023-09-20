CREATE PROCEDURE dbo.GetAuditorPowerOffs
AS

SET NOCOUNT ON

DECLARE @SevenDaysAgo DATETIME
DECLARE @Now DATETIME
DECLARE @OneMonthAgo DATETIME

DECLARE @LatestSitePowerOffs TABLE(EDISID INT NOT NULL, [Date] DATETIME NOT NULL)
DECLARE @LaterSitePowerOns TABLE(EDISID INT NOT NULL, [Date] DATETIME NOT NULL)
DECLARE @SitePowerOffsInLastMonth TABLE(EDISID INT NOT NULL, Occurences INT NOT NULL)

SET @Now = GETDATE()
SET @SevenDaysAgo = DATEADD(day, -7, @Now)
SET @OneMonthAgo = DATEADD(month, -1, @Now)

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @LatestSitePowerOffs
(EDISID, [Date])
SELECT MasterDates.[EDISID], 
       MAX([Date]+ CONVERT(VARCHAR(10), FaultStack.[Time], 8))
FROM FaultStack
JOIN MasterDates ON MasterDates.[ID] = FaultStack.FaultID
WHERE [Date] BETWEEN @SevenDaysAgo AND @Now
AND [Description] = 'Mains power failed'
GROUP BY MasterDates.[EDISID]

INSERT INTO @SitePowerOffsInLastMonth
(EDISID, Occurences)
SELECT MasterDates.[EDISID], COUNT(*)
FROM FaultStack
JOIN MasterDates ON MasterDates.[ID] = FaultStack.FaultID AND MasterDates.EDISID IN (SELECT EDISID FROM 
@LatestSitePowerOffs)
WHERE [Date] BETWEEN @OneMonthAgo AND @Now
AND [Description] = 'Mains power failed'
GROUP BY MasterDates.[EDISID]

INSERT INTO @LaterSitePowerOns
(EDISID, [Date])
SELECT MasterDates.[EDISID], MIN(MasterDates.[Date]+ CONVERT(VARCHAR(10), FaultStack.[Time], 8))
FROM FaultStack
JOIN MasterDates ON MasterDates.[ID] = FaultStack.FaultID
JOIN @LatestSitePowerOffs AS LatestSitePowerOffs ON LatestSitePowerOffs.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @SevenDaysAgo AND @Now
AND [Description] = 'Mains power restored'
AND MasterDates.[Date]+ CONVERT(VARCHAR(10), FaultStack.[Time], 8) > LatestSitePowerOffs.[Date]
GROUP BY MasterDates.[EDISID]

SELECT @CustomerID AS Customer,
	   LatestSitePowerOffs.EDISID,
	   LatestSitePowerOffs.[Date] AS PowerOffDate,
	   LaterSitePowerOns.[Date] AS PowerOnDate,
	   CASE WHEN LaterSitePowerOns.[Date] IS NOT NULL THEN DATEDIFF(Minute, 
LatestSitePowerOffs.[Date], LaterSitePowerOns.[Date]) END As TimeOffMinutes,
	   ISNULL(SitePowerOffsInLastMonth.Occurences, 0) AS OccurencesInLastMonth
FROM @LatestSitePowerOffs AS LatestSitePowerOffs
LEFT JOIN @LaterSitePowerOns AS LaterSitePowerOns ON LaterSitePowerOns.EDISID = LatestSitePowerOffs.EDISID
LEFT JOIN @SitePowerOffsInLastMonth AS SitePowerOffsInLastMonth ON SitePowerOffsInLastMonth.EDISID = 
LatestSitePowerOffs.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorPowerOffs] TO PUBLIC
    AS [dbo];

