CREATE PROCEDURE [dbo].[GetRequiredVRSUsers]
(
	@EDISID	INT
)

AS

SET NOCOUNT ON

CREATE TABLE #Users ([ID] INT NOT NULL)

SELECT * FROM Users

INSERT INTO #Users ([ID])
SELECT DISTINCT UserID
FROM dbo.SiteNotes AS SiteNotes
WHERE EDISID = @EDISID
AND UserID IS NOT NULL
UNION
SELECT DISTINCT BDMUserID
FROM dbo.SiteNotes AS SiteNotes
WHERE EDISID = @EDISID
AND BDMUserID IS NOT NULL
UNION
SELECT DISTINCT CAMID
FROM dbo.VisitRecords AS VisitRecords
WHERE EDISID = @EDISID
AND CAMID IS NOT NULL
UNION
SELECT DISTINCT BDMID
FROM dbo.VisitRecords AS VisitRecords
WHERE EDISID = @EDISID
AND BDMID IS NOT NULL

SELECT	Users.ID,
		Users.UserName,
		Users.[Login],
		Users.[Password],
		Users.UserType,
		Users.EMail,
		Users.PhoneNumber,
		Users.CreatedBy,
		Users.CreatedOn,
		Users.Deleted,
		Users.WebActive,
		Users.LastWebsiteLoginDate,
		Users.LastWebsiteLoginIPAddress,
		Users.NeverExpire,
		Users.VRSUserID,
		Users.Anonymise,
		Users.SendEMailAlert,
		Users.SMSAlert,
		Users.LanguageOverride
FROM dbo.Users AS Users
JOIN #Users ON #Users.ID = Users.ID

DROP TABLE #Users

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetRequiredVRSUsers] TO PUBLIC
    AS [dbo];

