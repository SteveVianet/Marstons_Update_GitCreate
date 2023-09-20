CREATE PROCEDURE AverageCellarTemperatureReport
(
      @UserID INT,
      @To DATETIME,
	  @DayWeeks INT,
	  @PrevWeeks INT,
	  @ShowClosedSites BIT = 0,
	  @ShowHidden BIT = 0
	  
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @GetAverageCellarTemperature TABLE (EDISID INT, LogDate DateTime, AvgCellarTemp FLOAT, ValueSpecification INT, Tolerance INT, ValueLowSpecification INT, ValueHighSpecification INT)
									
	INSERT INTO @GetAverageCellarTemperature (EDISID, LogDate, AvgCellarTemp, ValueSpecification, Tolerance, ValueLowSpecification, ValueHighSpecification)
    SELECT er.EDISID,
	CAST(er.LogDate as Date)as LogDate,
	AVG(er.Value) As AvgCellarTemperature,
	ei.ValueSpecification AS ValueSpecification,
	ei.ValueTolerance As Tolerance,
	ei.ValueLowSpecification AS ValueLowSpecification,
	ei.ValueHighSpecification AS ValueHighSpecification
	FROM EquipmentReadings as er
		INNER JOIN EquipmentItems as ei ON ei.InputID = er.InputID AND ei.EDISID = er.EDISID
	WHERE ei.EquipmentTypeID = 12
		AND LogDate BETWEEN DATEADD(wk, -((@PrevWeeks+@DayWeeks) - 1), @To) AND DATEADD(second, -1, DATEADD(day, 7, @To))--Add 1 day to the 2 substracts 1 second to grab every recording for the day itself
		AND ei.InUse = 1
	Group By CAST(er.LogDate as Date), er.EDISID, ei.ValueSpecification, ei.ValueTolerance, ei.ValueLowSpecification, ei.ValueHighSpecification

	DECLARE @GetOD TABLE (ID INT, UserName VARCHAR(50), UserType INT, EDISID INT)
									
	INSERT INTO @GetOD (ID, UserName, UserType, EDISID)
    SELECT u.ID, u.UserName, u.UserType, us.EDISID
	FROM Users As u
		INNER JOIN UserSites As us ON u.ID = us.UserID
	WHERE us.EDISID IN (SELECT EDISID
						FROM Users
							INNER JOIN UserSites on Users.ID = UserSites.UserID
						WHERE Users.ID = @UserID) 
							AND u.UserType = '1'

	--Main Select Query
	SELECT s.SiteID,
	(s.Name+','+ ' ' +Address3) AS Name, 
	gact.EDISID,
	u.UserName AS BDM,
	GetOD.UserName AS OD,
	s.SiteClosed AS siteClosed,
	s.Hidden AS Hidden,
	gact.LogDate,
	gact.AvgCellarTemp,
	gact.ValueSpecification,
	gact.Tolerance,
	gact.ValueLowSpecification,
	gact.ValueHighSpecification
	FROM Users as u 
		INNER JOIN UserSites AS us ON us.UserID = u.ID 
		INNER JOIN Sites AS s ON s.EDISID = us.EDISID
		INNER JOIN @GetAverageCellarTemperature as gact ON gact.EDISID = s.EDISID
		INNER JOIN @GetOD as GetOD ON GetOD.EDISID = s.EDISID
	WHERE UserID = @UserID 
		AND (s.SiteClosed = 0 or @ShowClosedSites = 1) 
		AND (s.Hidden = 0 or @ShowHidden = 1)
	ORDER BY s.Name asc, gact.LogDate
			
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AverageCellarTemperatureReport] TO PUBLIC
    AS [dbo];

