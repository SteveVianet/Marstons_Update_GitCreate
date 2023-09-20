CREATE PROCEDURE [dbo].[TestLatestSiteNotificationGeneratedWithinAuditRange]
(
	@CustomerID INT,
	@EDISID INT =NULL
)
AS

DECLARE @AuditDay INT = NULL

IF EXISTS ( select * from Configuration where PropertyName = 'AuditDay' ) 
BEGIN
	SET @AuditDay = (select PropertyValue from Configuration where PropertyName = 'AuditDay')
END

EXEC [EDISSQL1\SQL1].Auditing.dbo.[TestLatestSiteNotificationGeneratedWithinAuditRange] @CustomerID, @EDISID, @AuditDay

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[TestLatestSiteNotificationGeneratedWithinAuditRange] TO PUBLIC
    AS [dbo];

