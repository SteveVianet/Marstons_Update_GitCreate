CREATE PROCEDURE [dbo].[GetAccurateDuplicateVisitRecordCheck]
(
	@EDISID		INT,
	@VisitDate		DATE,
	@VisitTime		TIME,
	@Records		INT OUTPUT
)

AS


SELECT @Records = COUNT(*)
	FROM dbo.VisitRecords
	WHERE EDISID = @EDISID 
	AND CAST(VisitDate AS DATE) = @VisitDate 
	AND CAST(VisitTime AS TIME) = @VisitTime
	AND Deleted = 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAccurateDuplicateVisitRecordCheck] TO PUBLIC
    AS [dbo];

