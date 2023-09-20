CREATE PROCEDURE [dbo].[ValidSiteVisitRecordCombination]
(
	@EDISID		INT,
	@VisitID	INT,
	@Match		BIT OUTPUT,
	@Date		DATE OUTPUT
)
AS

SELECT @Match = COUNT(VisitRecords.ID), @Date = MAX(VisitRecords.VisitDate)
FROM Sites
JOIN VisitRecords ON VisitRecords.EDISID = Sites.EDISID
WHERE Sites.EDISID = @EDISID
  AND VisitRecords.ID = @VisitID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ValidSiteVisitRecordCombination] TO PUBLIC
    AS [dbo];

