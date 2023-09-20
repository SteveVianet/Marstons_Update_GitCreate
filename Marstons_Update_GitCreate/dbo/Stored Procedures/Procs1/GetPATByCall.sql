CREATE PROCEDURE [dbo].[GetPATByCall] 

	@CallID		BIGINT

AS

SELECT ApplianceID, CallID, PanelInstalled, TestDate, ReTestDue, Visual, Polarity, EarthCont, EarthContOperator, EarthContReading, Insulation, InsulationOperator, InsulationReading, 
[Load], LoadOperator, LoadReading, Leakage, LeakageOperator, LeakageReading, TouchLeak, SubLeak, Flash, TouchLeakReading, TouchLeakOperator
FROM PATTracking
WHERE CallID = @CallID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPATByCall] TO PUBLIC
    AS [dbo];

