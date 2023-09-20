CREATE PROCEDURE VRS_GetDailyTotals
(
	@ScheduleName VARCHAR(255),
	@WeekCommencingMonday DATETIME
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT)
DECLARE @Field VARCHAR(255)
DECLARE @Value VARCHAR(255)

IF LEFT(@ScheduleName, 1) = '$'
BEGIN
	--Dynamic Schedule
	SET @Field = SUBSTRING(@ScheduleName, 2, CHARINDEX('=', @ScheduleName)-2)
	SET @Value = SUBSTRING(@ScheduleName, CHARINDEX('=', @ScheduleName)+1, CHARINDEX(':', @ScheduleName)-CHARINDEX('=', @ScheduleName)-1)

	IF @Field = 'SystemType'
		INSERT INTO @Sites(EDISID)
		SELECT EDISID
		FROM Sites
		JOIN SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
		WHERE SystemTypes.[Description] = @Value
		ORDER BY Sites.SiteID
	
	ELSE IF @Field = 'Region'
		INSERT INTO @Sites(EDISID)
		SELECT EDISID
		FROM Sites
		JOIN Regions ON Regions.[ID] = Sites.Region
		WHERE Regions.[Description] = @Value
		ORDER BY Sites.SiteID
	
	ELSE IF @Field = 'Area'
		INSERT INTO @Sites(EDISID)
		SELECT EDISID
		FROM Sites
		JOIN Areas ON Areas.[ID] = Sites.AreaID
		WHERE Areas.[Description] = @Value
		ORDER BY Sites.SiteID
	
	ELSE IF @Field = 'SiteClosed'
	BEGIN
		IF @Value = 'True' OR @Value = '1'
			INSERT INTO @Sites(EDISID)
			SELECT EDISID
			FROM Sites
			WHERE SiteClosed = 1
			ORDER BY Sites.SiteID
		ELSE
			INSERT INTO @Sites(EDISID)
			SELECT EDISID
			FROM Sites
			WHERE SiteClosed = 0
			ORDER BY Sites.SiteID
	END
	
	ELSE IF @Field = 'InVRS'
	BEGIN
		IF @Value = 'True' OR @Value = '1'
			INSERT INTO @Sites(EDISID)
			SELECT EDISID
			FROM Sites
			WHERE IsVRSMember = 1
			ORDER BY Sites.SiteID
	
		ELSE
			INSERT INTO @Sites(EDISID)
			SELECT EDISID
			FROM Sites
			WHERE IsVRSMember = 0
			ORDER BY Sites.SiteID
	
	END
	
	ELSE IF @Field = 'HasProperty'
		INSERT INTO @Sites(EDISID)
		SELECT SiteProperties.EDISID
		FROM SiteProperties
		JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
		JOIN Sites ON Sites.EDISID = SiteProperties.EDISID
		WHERE Properties.[Name] = @Value
		ORDER BY Sites.SiteID
	
	ELSE IF @Field = 'PropertyValue'
	BEGIN
		DECLARE @PropertyName	VARCHAR(255)
		DECLARE @PropertyValue	VARCHAR(255)
		
		SET @PropertyName = LEFT(@Value, CHARINDEX('=', @Value) - 1)
		SET @PropertyValue = SUBSTRING(@Value, CHARINDEX('=', @Value) + 1, 1000)
			
		INSERT INTO @Sites(EDISID)
		SELECT SiteProperties.EDISID
		FROM SiteProperties
		JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
		JOIN Sites ON Sites.EDISID = SiteProperties.EDISID
		WHERE Properties.[Name] = @PropertyName
		AND SiteProperties.Value = @PropertyValue
		ORDER BY Sites.SiteID
	
	END
	
	ELSE IF @Field = 'User'
	BEGIN
		DECLARE @AllSitesVisible	INT
		
		SELECT @AllSitesVisible = AllSitesVisible
		FROM UserTypes
		JOIN Users ON Users.UserType = UserTypes.[ID]
		WHERE Users.UserName = @Value
		
		IF @AllSitesVisible IS NULL
			RETURN 0
	
		ELSE IF @AllSitesVisible = 1
			INSERT INTO @Sites(EDISID)
			SELECT EDISID
			FROM Sites
			ORDER BY Sites.SiteID
	
		ELSE
			INSERT INTO @Sites(EDISID)
			SELECT Sites.EDISID
			FROM UserSites
			JOIN Users ON Users.[ID] = UserSites.UserID
			JOIN Sites ON Sites.EDISID = UserSites.EDISID
			WHERE Users.UserName = @Value
			ORDER BY Sites.SiteID
	
	END
	
	ELSE IF @Field = 'NotDownloadedFor'
		INSERT INTO @Sites(EDISID)
		SELECT EDISID
		FROM Sites
		WHERE DATEDIFF(dd, LastDownload, CAST(CAST(GETDATE() AS VARCHAR(12)) AS DATETIME)) > CAST(@Value AS INTEGER)
		OR LastDownload IS NULL
		ORDER BY LastDownload


END
ELSE
BEGIN
	--Normal Schedule
	INSERT INTO @Sites(EDISID)
	SELECT ScheduleSites.EDISID
	FROM ScheduleSites
	JOIN Schedules ON Schedules.[ID] = ScheduleSites.ScheduleID
	WHERE Schedules.[Description] = @ScheduleName

END

SET DATEFIRST 1 --Set Monday to be the first day of the week

SELECT	AggregateData.SiteID,
	AggregateData.Pump,
	AggregateData.Product,
	SUM(Day1) AS Day1,
	SUM(Day2) AS Day2,
	SUM(Day3) AS Day3,
	SUM(Day4) AS Day4,
	SUM(Day5) AS Day5,
	SUM(Day6) AS Day6,
	SUM(Day7) AS Day7,
	SUM(Day1)+SUM(Day2)+SUM(Day3)+SUM(Day4)+SUM(Day5)+SUM(Day6)+SUM(Day7) AS Total,
	(SUM(Day1)+SUM(Day2)+SUM(Day3)+SUM(Day4))/4 AS AvgMonToThu,
	(SUM(Day5)+SUM(Day6)+SUM(Day7))/3 AS AvgFriToSat,
	CASE WHEN ((SUM(Day5)+SUM(Day6)+SUM(Day7))/3)-((SUM(Day1)+SUM(Day2)+SUM(Day3)+SUM(Day4))/4) < 0 THEN 'Yes' ELSE 'No' END AS PotentialTamper	
FROM	(SELECT	ReportData.SiteID,
		ReportData.Pump,
		ReportData.Product,
		CASE DATEPART(dw, ReportData.[Date]) WHEN 1 THEN Quantity ELSE 0 END AS [Day1],
		CASE DATEPART(dw, ReportData.[Date]) WHEN 2 THEN Quantity ELSE 0 END AS [Day2],
		CASE DATEPART(dw, ReportData.[Date]) WHEN 3 THEN Quantity ELSE 0 END AS [Day3],
		CASE DATEPART(dw, ReportData.[Date]) WHEN 4 THEN Quantity ELSE 0 END AS [Day4],
		CASE DATEPART(dw, ReportData.[Date]) WHEN 5 THEN Quantity ELSE 0 END AS [Day5],
		CASE DATEPART(dw, ReportData.[Date]) WHEN 6 THEN Quantity ELSE 0 END AS [Day6],
		CASE DATEPART(dw, ReportData.[Date]) WHEN 7 THEN Quantity ELSE 0 END AS [Day7]
	FROM
		(SELECT	Sites.SiteID,
			DLData.Pump,
			Products.[Description] AS Product,
			MasterDates.[Date],
			SUM(DLData.Quantity) AS Quantity
		FROM @Sites AS SSites
		JOIN MasterDates ON MasterDates.EDISID = SSites.EDISID
		JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
		JOIN Products ON Products.[ID] = DLData.Product
		JOIN Sites ON Sites.EDISID = SSites.EDISID
		WHERE MasterDates.[Date] BETWEEN @WeekCommencingMonday AND DATEADD(d, 6, @WeekCommencingMonday)
		GROUP BY Sites.SiteID, DLData.Pump, Products.[Description], MasterDates.[Date]) AS ReportData) AS AggregateData
GROUP BY AggregateData.SiteID, AggregateData.Pump, AggregateData.Product
ORDER BY AggregateData.SiteID, AggregateData.Pump
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[VRS_GetDailyTotals] TO PUBLIC
    AS [dbo];

