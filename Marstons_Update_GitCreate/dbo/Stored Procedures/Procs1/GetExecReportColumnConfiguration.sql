
CREATE PROCEDURE [dbo].[GetExecReportColumnConfiguration]
	@UserID			INT
AS

SET NOCOUNT ON;

DECLARE @UserHasAllSites BIT
DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @UserHasAllSites = AllSitesVisible
FROM UserTypes
JOIN Users ON Users.UserType = UserTypes.ID
WHERE Users.ID = @UserID

SELECT TOP 1 ReportingFirstDayOfWeek, 
	ReportingShowWorstYieldFirst, 
	ReportingShowOverallYieldPercent, 
	ReportingShowOverallYieldCashValue, 
	ReportingShowOverallYield, 
	ReportingShowOverallYieldAverage, 
	ReportingShowOverallYieldAverageCashValue, 
	ReportingShowRetailYield, 
	ReportingShowRetailYieldPercent, 
	ReportingShowRetailYieldCashValue, 
	ReportingShowPouringYield, 
	ReportingShowPouringYieldPercent, 
	ReportingShowCleaningLoss, 
	ReportingShowCleaningLinesOverdue, 
	ReportingShowNumberOfAlarms, 
	ReportingShowNumberOfExceptions, 
	ReportingShowNumberOfEmailsSent,
	ReportingShowDispenseViaUncleanLines
FROM Owners
WHERE ID IN
(
	SELECT DISTINCT OwnerID
	FROM Sites
	WHERE
	(
		(@UserHasAllSites = 1) OR 
		Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)
	 
	)
)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetExecReportColumnConfiguration] TO PUBLIC
    AS [dbo];

