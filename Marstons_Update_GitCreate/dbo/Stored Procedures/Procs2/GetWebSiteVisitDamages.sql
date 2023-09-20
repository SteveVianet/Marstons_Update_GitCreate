CREATE PROCEDURE dbo.GetWebSiteVisitDamages 

	@VisitRecordID 		INT,
	@DamagesType	INT = NULL

AS

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
		ISNULL(Agreed, 0) As Agreed

FROM VisitDamages
WHERE VisitRecordID = @VisitRecordID
AND (DamagesType = @DamagesType OR @DamagesType IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteVisitDamages] TO PUBLIC
    AS [dbo];

