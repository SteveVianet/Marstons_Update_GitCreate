
CREATE FUNCTION dbo.[dbo.xxxfnGetLatestDownloadedDate]
(
	@EDISID	INT,
	@Today	DATETIME
)

RETURNS DATETIME

AS

BEGIN

	DECLARE @TestDate DATETIME
	DECLARE @TestTime DATETIME
	DECLARE @NewDate  DATETIME
	DECLARE @MainDate DATETIME
	
	SELECT @MainDate = SiteOnline FROM Sites WHERE EDISID = @EDISID
	
	SELECT Top 1 @TestTime = StartTime, @TestDate = MasterDates.[Date] FROM DispenseConditions
	JOIN MasterDates ON MasterDates.ID = DispenseConditions.MasterDateID
	WHERE EDISID = @EDISID
	AND [Date] <= @Today
	ORDER BY [Date] DESC, StartTime DESC
	
	SET @NewDate = CAST(STR(DATEPART(year,@TestDate),4) + '-' + STR(DATEPART(month,@TestDate),LEN(DATEPART(month,@TestDate))) + '-' + 
STR(DATEPART(day,@TestDate),LEN(DATEPART(day,@TestDate))) + ' ' + STR(DATEPART(hour,@TestTime),LEN(DATEPART(hour,@TestTime))) + ':' + 
STR(DATEPART(minute,@TestTime),LEN(DATEPART(minute,@TestTime))) + ':' + STR(DATEPART(second,@TestTime),LEN(DATEPART(second,@TestTime))) AS 
DATETIME)
	
	IF @NewDate > @MainDate
	 BEGIN
	  --SELECT 'Using DispenseConditions'
	  SET @MainDate = @NewDate
	 END
	
	SELECT Top 1 @TestTime = CAST('1899-12-30 ' + STR(CAST(STR([Shift]) AS INT)-1) + ':00:00' AS DATETIME), @TestDate = 
MasterDates.[Date] FROM DLData
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
	
	SELECT Top 1 @TestDate = LogDate FROM EquipmentReadings
	WHERE EDISID = @EDISID
	AND LogDate <= @Today
	ORDER BY LogDate
	
	SET @NewDate = @TestDate
	
	IF @NewDate > @MainDate
	 BEGIN
	  --SELECT 'Using EquipmentLogs'
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
	
	RETURN @MainDate

END
