CREATE PROCEDURE [dbo].[SiteHasOpenVisitRecord]

	@EDISID		INT,
	@HasOpenRecord	BIT OUTPUT,
	@IgnorePendingComplete BIT = 1,
	@IgnorePendingVerify	BIT = 1

AS

DECLARE @VisitCount	INT

SELECT @VisitCount = COUNT([ID])
FROM VisitRecords
WHERE EDISID = @EDISID
AND VisitRecords.CustomerID = 0
AND VisitRecords.Deleted = 0
AND (
	(@IgnorePendingComplete = 0 AND (CompletedByCustomer = 0 OR CompletedByCustomer IS NULL)) OR
	(@IgnorePendingVerify = 0 AND (VerifiedByVRS = 0 OR VerifiedByVRS IS NULL)) OR
	(ClosedByCAM = 0 OR ClosedByCAM IS NULL)
)


IF @VisitCount > 0
	SET @HasOpenRecord = 1
ELSE
	SET @HasOpenRecord = 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SiteHasOpenVisitRecord] TO PUBLIC
    AS [dbo];

