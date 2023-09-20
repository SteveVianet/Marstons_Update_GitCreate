CREATE PROCEDURE [dbo].[GetUsersVRSSitesSummary]
(
	@UserID		INT
)

AS


DECLARE @AllSitesVisible BIT
SET @AllSitesVisible = (SELECT UserTypes.AllSitesVisible
			FROM Users
			JOIN UserTypes ON Users.UserType = UserTypes.ID
			WHERE Users.ID = @UserID)


SELECT 	UsersSites.EDISID,
		CurrentNote.[ID] As OutstandingVisitID,
		UsersSites.SiteID,
		UsersSites.[Name],
		UsersSites.PostCode,
		NoteCount.NumberOfVisitNotes,
		(SELECT '1' WHERE CurrentNote.VisitDate IS NOT NULL) As OutstandingAction
FROM
	(SELECT Sites.EDISID,
		Sites.SiteID,
		Sites.[Name],
		Sites.PostCode FROM Sites
	WHERE EDISID 
	IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR (@AllSitesVisible = 1)
) AS UsersSites
LEFT JOIN VisitRecords ON VisitRecords.EDISID = UsersSites.EDISID AND Deleted = 0
LEFT JOIN (SELECT [ID], EDISID, VisitDate FROM VisitRecords WHERE VerifiedByVRS = 1 AND Deleted = 0 AND (CompletedByCustomer = 0 OR CompletedByCustomer IS NULL)) As CurrentNote ON CurrentNote.EDISID = UsersSites.EDISID
LEFT JOIN (SELECT EDISID, COUNT(VisitRecords.[ID]) As NumberOfVisitNotes FROM VisitRecords WHERE Deleted = 0 GROUP BY EDISID) As NoteCount ON NoteCount.EDISID = UsersSites.EDISID

GROUP BY 	UsersSites.EDISID,
		UsersSites.SiteID,
		UsersSites.[Name],
		UsersSites.PostCode,
		NoteCount.NumberOfVisitNotes,
		CurrentNote.VisitDate,
		CurrentNote.[ID]

ORDER BY 	OutstandingAction DESC, 
		CurrentNote.VisitDate ASC, 
		UsersSites.Name ASC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUsersVRSSitesSummary] TO PUBLIC
    AS [dbo];

