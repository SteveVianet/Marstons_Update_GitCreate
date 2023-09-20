
CREATE PROCEDURE [dbo].[UpdateSiteExceptionEmailAddress]
(
	@EDISID			INT,
	@EmailAddress	VARCHAR(255)
)
AS

SET NOCOUNT ON

DECLARE @ExistingTenantEmailAddress VARCHAR(255)

SELECT @ExistingTenantEmailAddress = EMail
FROM Users
JOIN UserSites ON UserSites.UserID = Users.ID AND UserSites.EDISID = @EDISID
WHERE EMail <> ''
AND UserType IN (5, 6)
AND WebActive = 1
AND Deleted = 0
AND (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR NeverExpire = 1)
AND DetailsReviewedOn IS NOT NULL
GROUP BY EMail

IF LOWER(@ExistingTenantEmailAddress) = LOWER(@EmailAddress)
BEGIN
	RETURN
END

MERGE SiteExceptionEmailAddresses
USING
(
	SELECT  @EDISID AS EDISID,
			@EmailAddress AS Email
) AS ProposedEmail
ON ProposedEmail.EDISID = SiteExceptionEmailAddresses.EDISID
AND LOWER(ProposedEmail.Email) = LOWER(SiteExceptionEmailAddresses.Email)
WHEN NOT MATCHED THEN
INSERT(EDISID, Email)
VALUES(ProposedEmail.EDISID, ProposedEmail.Email);

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteExceptionEmailAddress] TO PUBLIC
    AS [dbo];

