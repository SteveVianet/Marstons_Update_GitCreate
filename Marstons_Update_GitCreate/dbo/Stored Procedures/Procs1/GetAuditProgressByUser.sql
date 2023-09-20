CREATE PROCEDURE dbo.GetAuditProgressByUser
(
	@UserTypeID		INTEGER,
	@From			DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON

DECLARE @BDMSites TABLE(UserID INTEGER, Total INTEGER)
DECLARE @AuditedBDMSites TABLE(EDISID INTEGER, [TimeStamp] DATETIME)

--Auditor, BDM Grouped List
INSERT INTO @BDMSites
SELECT Users.ID, COUNT(*)
FROM Sites
LEFT JOIN UserSites ON UserSites.EDISID = Sites.EDISID
JOIN Users ON UserSites.UserID = Users.[ID]
WHERE Hidden = 0 
AND (Users.UserType = @UserTypeID OR Users.ID IS NULL)
GROUP BY Users.ID

INSERT INTO @AuditedBDMSites
SELECT EDISID, MAX(TimeStamp)
FROM SiteAudits
WHERE TimeStamp BETWEEN @From AND @To
GROUP BY EDISID

SELECT BDMSites.UserID, BDMSites.Total, COUNT(TimeStamp) AS Audited
FROM @BDMSites AS BDMSites
JOIN UserSites ON UserSites.UserID = BDMSites.UserID
LEFT JOIN @AuditedBDMSites AS AuditedBDMSites ON AuditedBDMSites.EDISID = UserSites.EDISID
GROUP BY BDMSites.UserID, BDMSites.Total


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditProgressByUser] TO PUBLIC
    AS [dbo];

