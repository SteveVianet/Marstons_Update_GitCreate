CREATE PROCEDURE [dbo].[GetPATs]


AS

SELECT ApplianceID, CallID, 
CAST(CONVERT(VARCHAR(10), PanelInstalled, 12) AS DATETIME) AS PanelInstalled,
CAST(CONVERT(VARCHAR(10), TestDate, 12) AS DATETIME) AS TestDate,
CAST(CONVERT(VARCHAR(10), ReTestDue, 12) AS DATETIME) AS ReTestDue,
Visual, Polarity, EarthCont, EarthContOperator, EarthContReading, Insulation, InsulationOperator, InsulationReading, 
[Load], LoadOperator, LoadReading, Leakage, LeakageOperator, LeakageReading, TouchLeak, SubLeak, Flash, TouchLeakReading, TouchLeakOperator
FROM PATTracking
JOIN Calls ON Calls.ID = CallID
ORDER BY TestDate DESC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPATs] TO PUBLIC
    AS [dbo];

