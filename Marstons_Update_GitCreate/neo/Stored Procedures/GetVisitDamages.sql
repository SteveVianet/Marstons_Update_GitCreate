CREATE PROCEDURE [neo].[GetVisitDamages] 

	@VisitID 		INT,
	@DamagesType	INT = NULL

AS

CREATE TABLE #CalChecks ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO #CalChecks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCalChecksCompleted

SELECT	DamagesID,
		VisitRecordID,
		DamagesType,
		Damages,
		Product,
		ReportedDraughtVolume,
		DraughtVolume,
		Cases,
		Bottles,
		DraughtStock,
		Comment,
		ISNULL(CalCheck, 0) As CalCheck,
		c.Description AS CalCheckDescription,
		ISNULL(Agreed, 0) As Agreed

FROM VisitDamages
	JOIN #CalChecks AS c ON c.ID = CalCheck
WHERE VisitRecordID = @VisitID
AND (DamagesType = @DamagesType OR @DamagesType IS NULL)

DROP TABLE #CalChecks
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetVisitDamages] TO PUBLIC
    AS [dbo];

