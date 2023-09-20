CREATE PROCEDURE [dbo].[GetDuplicateVisitRecordCheck]
(
	@EDISID		INT,
	@VisitDate		DATETIME,
	@VisitTime		DATETIME,
	@Records		INT OUTPUT
)

AS


SELECT @Records = COUNT(*)
	FROM dbo.VisitRecords
	WHERE EDISID = @EDISID 
	AND VisitDate = @VisitDate 
	AND VisitTime = @VisitTime
	AND Deleted = 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDuplicateVisitRecordCheck] TO PUBLIC
    AS [dbo];

