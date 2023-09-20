CREATE PROCEDURE [dbo].[GetCalibrationMonthSchedule]
AS

SET NOCOUNT ON

DECLARE @LastCompletedFontSetups TABLE(EDISID INT NOT NULL, SiteInstallDate DATETIME NULL, MonthsOld INT NOT NULL, MonthsBetweenVisitsTarget INT NOT NULL, InstallationDate DATETIME NULL)

INSERT INTO @LastCompletedFontSetups
(EDISID, MonthsOld, MonthsBetweenVisitsTarget, InstallationDate)
SELECT Sites.EDISID,
	   ISNULL(DATEDIFF(MONTH, CreateDate, GETDATE()), 0),
	   CASE WHEN DATEDIFF(YEAR, InstallationDate, GETDATE()) < 5 THEN 24 ELSE 12 END,
	   ISNULL(InstallationDate, '1899-12-30')
FROM Sites
LEFT JOIN
(
	SELECT EDISID, MAX([ID]) AS [ID]
	FROM ProposedFontSetups
	WHERE ProposedFontSetups.Completed = 1 
	AND ProposedFontSetups.Available = 1
	AND GlasswareStateID = 1
	GROUP BY EDISID
) 
AS LastCompleteFontSetups ON LastCompleteFontSetups.EDISID = Sites.EDISID
LEFT JOIN ProposedFontSetups ON ProposedFontSetups.[ID] = LastCompleteFontSetups.[ID]
WHERE Hidden = 0
--AND YEAR(InstallationDate) > 1950

SELECT  Configuration.PropertyValue AS CompanyName,
		SUM(CASE WHEN YEAR(InstallationDate) <= 1900 THEN 1 ELSE 0 END) AS NoInstallDates,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget >= 0 AND YEAR(InstallationDate) > 1900 THEN 1 ELSE 0 END) AS ThisMonth,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -1 THEN 1 ELSE 0 END) AS OneMonth,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -2 THEN 1 ELSE 0 END) AS TwoMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -3 THEN 1 ELSE 0 END) AS ThreeMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -4 THEN 1 ELSE 0 END) AS FourMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -5 THEN 1 ELSE 0 END) AS FiveMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -6 THEN 1 ELSE 0 END) AS SixMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -7 THEN 1 ELSE 0 END) AS SevenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -8 THEN 1 ELSE 0 END) AS EightMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -9 THEN 1 ELSE 0 END) AS NineMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -10 THEN 1 ELSE 0 END) AS TenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -11 THEN 1 ELSE 0 END) AS ElevenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -12 THEN 1 ELSE 0 END) AS TwelveMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -13 THEN 1 ELSE 0 END) AS ThirteenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -14 THEN 1 ELSE 0 END) AS FourteenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -15 THEN 1 ELSE 0 END) AS FifteenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -16 THEN 1 ELSE 0 END) AS SixteenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -17 THEN 1 ELSE 0 END) AS SeventeenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -18 THEN 1 ELSE 0 END) AS EighteenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -19 THEN 1 ELSE 0 END) AS NineteenMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -20 THEN 1 ELSE 0 END) AS TwentyMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -21 THEN 1 ELSE 0 END) AS TwentyOneMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -22 THEN 1 ELSE 0 END) AS TwentyTwoMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -23 THEN 1 ELSE 0 END) AS TwentyThreeMonths,
		SUM(CASE WHEN MonthsOld - MonthsBetweenVisitsTarget = -24 THEN 1 ELSE 0 END) AS TwentyFourMonths
FROM @LastCompletedFontSetups
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
GROUP BY Configuration.PropertyValue

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalibrationMonthSchedule] TO PUBLIC
    AS [dbo];

