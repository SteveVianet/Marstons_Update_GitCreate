CREATE PROCEDURE [dbo].[GetLatestDownloadedDate]
(
	@EDISID INT
)

AS

DECLARE @Today DATETIME
DECLARE @TestDate DATETIME
DECLARE @TestTime DATETIME
DECLARE @NewDate  DATETIME
DECLARE @MainDate DATETIME

SET NOCOUNT ON

SET @Today = GETDATE()

SELECT @MainDate = SiteOnline FROM Sites WHERE EDISID = @EDISID

SELECT Top 1 
	@TestTime = CAST(CONVERT(VARCHAR(10), StartTime, 108) AS DateTime), 
	@TestDate = DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) 
FROM DispenseActions
WHERE EDISID = @EDISID
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))  <= @Today
ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))  DESC, CAST(CONVERT(VARCHAR(10), StartTime, 108) AS DateTime) DESC

SET @NewDate = CAST(STR(DATEPART(year,@TestDate),4) + '-' + STR(DATEPART(month,@TestDate),LEN(DATEPART(month,@TestDate))) + '-' + 
STR(DATEPART(day,@TestDate),LEN(DATEPART(day,@TestDate))) + ' ' + STR(DATEPART(hour,@TestTime),LEN(DATEPART(hour,@TestTime))) + ':' + 
STR(DATEPART(minute,@TestTime),LEN(DATEPART(minute,@TestTime))) + ':' + STR(DATEPART(second,@TestTime),LEN(DATEPART(second,@TestTime))) AS 
DATETIME)

IF @NewDate > @MainDate
 BEGIN

  SET @MainDate = @NewDate
 END

SELECT Top 1 @TestTime = CAST('1899-12-30 ' + STR(CAST(STR([Shift]) AS INT)-1) + ':00:00' AS DATETIME), @TestDate = MasterDates.[Date] FROM 
DLData
JOIN MasterDates ON MasterDates.ID = DLData.DownloadID
WHERE EDISID = @EDISID
AND [Date] <= @Today
ORDER BY [Date] DESC, Shift DESC

SET @NewDate = CAST(STR(DATEPART(year,@TestDate),4) + '-' + STR(DATEPART(month,@TestDate),LEN(DATEPART(month,@TestDate))) + '-' + 
STR(DATEPART(day,@TestDate),LEN(DATEPART(day,@TestDate))) + ' ' + STR(DATEPART(hour,@TestTime),LEN(DATEPART(hour,@TestTime))) + ':' + 
STR(DATEPART(minute,@TestTime),LEN(DATEPART(minute,@TestTime))) + ':' + STR(DATEPART(second,@TestTime),LEN(DATEPART(second,@TestTime))) AS 
DATETIME)

IF @NewDate > @MainDate
 BEGIN
  --SELECT 'Using DLData'
  SET @MainDate = @NewDate
 END

SELECT Top 1 @TestTime = [Time], @TestDate = MasterDates.[Date] FROM WaterStack
JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
WHERE EDISID = @EDISID
AND [Date] <= @Today
ORDER BY [Date] DESC, [Time] DESC

SET @NewDate = CAST(STR(DATEPART(year,@TestDate),4) + '-' + STR(DATEPART(month,@TestDate),LEN(DATEPART(month,@TestDate))) + '-' + 
STR(DATEPART(day,@TestDate),LEN(DATEPART(day,@TestDate))) + ' ' + STR(DATEPART(hour,@TestTime),LEN(DATEPART(hour,@TestTime))) + ':' + 
STR(DATEPART(minute,@TestTime),LEN(DATEPART(minute,@TestTime))) + ':' + STR(DATEPART(second,@TestTime),LEN(DATEPART(second,@TestTime))) AS 
DATETIME)

IF @NewDate > @MainDate
 BEGIN
  --SELECT 'Using WaterStack'
  SET @MainDate = @NewDate
 END

SELECT Top 1 @TestTime = EquipmentReadings.LogDate
FROM EquipmentReadings
WHERE EDISID = @EDISID
AND LogDate <= @Today
ORDER BY LogDate DESC

SET @NewDate = @TestTime

IF @NewDate > @MainDate
 BEGIN
  --SELECT 'Using EquipmentReadings'
  SET @MainDate = @NewDate
 END

SELECT Top 1 @TestTime = [Time], @TestDate = MasterDates.[Date]
FROM FaultStack WITH (INDEX (IX_FaultStack_FaultID))
JOIN MasterDates ON MasterDates.ID = FaultStack.FaultID
WHERE EDISID = @EDISID
AND [Date] < @Today
ORDER BY [Date] DESC, [Time] DESC

SET @NewDate = CAST(STR(DATEPART(year,@TestDate),4) + '-' + STR(DATEPART(month,@TestDate),LEN(DATEPART(month,@TestDate))) + '-' + 
STR(DATEPART(day,@TestDate),LEN(DATEPART(day,@TestDate))) + ' ' + STR(DATEPART(hour,@TestTime),LEN(DATEPART(hour,@TestTime))) + ':' + 
STR(DATEPART(minute,@TestTime),LEN(DATEPART(minute,@TestTime))) + ':' + STR(DATEPART(second,@TestTime),LEN(DATEPART(second,@TestTime))) AS 
DATETIME)

IF @NewDate > @MainDate
 BEGIN
  --SELECT 'Using FaultStack'
  SET @MainDate = @NewDate
 END

SELECT @MainDate AS LatestDownloadedDate

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLatestDownloadedDate] TO PUBLIC
    AS [dbo];

