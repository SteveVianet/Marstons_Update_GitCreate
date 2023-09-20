CREATE PROCEDURE [dbo].[GetPATsForSite]

	@EDISID	INT

AS

SELECT ApplianceID, CallID, PanelInstalled, TestDate, ReTestDue, Visual, Polarity, EarthCont, EarthContOperator, EarthContReading, Insulation, InsulationOperator, InsulationReading, 
[Load], LoadOperator, LoadReading, Leakage, LeakageOperator, LeakageReading, TouchLeak, SubLeak, Flash, TouchLeakReading, TouchLeakOperator
FROM PATTracking
JOIN Calls ON Calls.ID = CallID
WHERE EDISID = @EDISID
ORDER BY Calls.VisitedOn DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPATsForSite] TO PUBLIC
    AS [dbo];

