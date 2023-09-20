Create PROCEDURE [dbo].[LineCleaningEffciencySchedule]
		@From		DATETIME,
		@To			DATETIME,
		@ScheduleID INT,
		@ShowHidden BIT = 0,
		@ShowClosedSites BIT = 0
		

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @BRM TABLE (ID INT,
						UserName VARCHAR(50))

	DECLARE @PeriodCleaningPercentage TABLE (EDISID INT,
											 TotalDispense FLOAT,
											 OverdueDispense FLOAT,
											 [Date] DateTime)

											 

	INSERT INTO @BRM (ID,UserName)
	SELECT u.ID,
		   u.UserName
	FROM Users As u
	WHERE u.UserType = 2

	INSERT INTO @PeriodCleaningPercentage (EDISID,TotalDispense,OverdueDispense,[Date])
	SELECT	EDISID,
			SUM(pccd.TotalDispense) AS TotalDispense,
			SUM(pccd.OverdueCleanDispense) AS OverdueDispense,
			pccd.[Date]
	FROM PeriodCacheCleaningDispense AS pccd
			INNER JOIN ProductCategories ON ProductCategories.ID = pccd.CategoryID AND ProductCategories.IncludeInLineCleaning = 1
	WHERE pccd.[Date] BETWEEN @From AND DATEADD("d",7,@To)
	GROUP BY EDISID, [Date]

SELECT s.EDISID,
	s.SiteID,
	s.Name,
	CASE 
			WHEN s.Address3 = '' AND s.Address2 = '' THEN s.Address1
			WHEN s.Address3 = '' THEN s.Address2
			ELSE s.Address3
		END AS Town,
	area.[Description] AS Area,
	BRM.UserName AS BRM,
	s.SiteClosed AS siteClosed,
	s.Hidden AS Hidden,
	ISNULL(TotalDispense, 0) AS TotalDispense,
	ISNULL(OverdueDispense, 0) AS OverdueDispense,
	OverdueDispense / NULLIF(TotalDispense,0) AS OverduePercentage, --Calculates the Overdue Percetage, NULLIF prevents a divide by zero error
	[Date] AS [Date],
	o.CleaningAmberPercentTarget,
	o.CleaningRedPercentTarget
FROM Sites AS s
	INNER JOIN Owners AS o ON s.OwnerID = o.ID
	INNER JOIN UserSites AS us ON s.EDISID = us.EDISID
	INNER JOIN Areas as area ON area.ID = s.AreaID
	INNER JOIN ScheduleSites AS ss ON s.EDISID = ss.EDISID
	INNER JOIN @BRM AS BRM ON BRM.ID = us.UserID 
	LEFT OUTER JOIN @PeriodCleaningPercentage AS PeriodCleaningPercentage ON PeriodCleaningPercentage.EDISID = s.EDISID

WHERE ScheduleID = @ScheduleID and (s.Hidden = 0 or @ShowHidden = 1) and (s.SiteClosed = 0 or @ShowClosedSites = 1)
										 		
GROUP BY s.EDISID,
		s.SiteID, 
		s.Name,
		s.Address1,
		s.Address2,
		s.Address3,
		area.[Description],
		BRM.UserName,
		s.SiteClosed,
		s.Hidden,
		TotalDispense,
		OverdueDispense,
		[Date],
		CleaningAmberPercentTarget,
		CleaningRedPercentTarget

ORDER By SiteID, [Date]
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[LineCleaningEffciencySchedule] TO PUBLIC
    AS [dbo];

