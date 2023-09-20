CREATE PROCEDURE GetNewInstallations
(
	@IgnoreAssigned	BIT,
	@OwnedSitesOnly	BIT
)

AS

SELECT	Sites.EDISID,
	Sites.SiteID,
	Sites.[Name] AS SiteName,
	Owners.Name As SiteOwner,
	Sites.Address1, Sites.Address2, Sites.Address3, Sites.Address4,
	Sites.PostCode,
	ProposedFontSetups.[ID] AS ProposedFontSetupID,
	ProposedFontSetups.CreateDate,
	Calls.ClosedOn AS CompletedOn,
	CallStatusHistory.StatusID,
	CallStatusHistory.SubStatusID,
	SupplementaryCallStatusItems.SupplementaryCallStatusID,
	SupplementaryCallStatusItems.SupplementaryDate,
	SupplementaryCallStatusItems.SupplementaryText
FROM dbo.Sites
JOIN dbo.ProposedFontSetups ON ProposedFontSetups.EDISID = Sites.EDISID
JOIN dbo.Owners ON Owners.[ID] = Sites.OwnerID
LEFT JOIN dbo.Calls ON Calls.[ID] = ProposedFontSetups.CallID
LEFT JOIN dbo.CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]
LEFT JOIN dbo.SupplementaryCallStatusItems ON SupplementaryCallStatusItems.CallID = Calls.[ID]
WHERE ProposedFontSetups.Available = 1
AND ProposedFontSetups.Completed = 0
AND (UPPER(Sites.SiteUser) = UPPER(SUSER_SNAME()) OR @OwnedSitesOnly = 0)
AND (Sites.SiteUser = '' OR Sites.SiteUser = 'NOBODY' OR @IgnoreAssigned = 0)
AND Sites.Hidden = 1
AND (CallStatusHistory.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
				FROM dbo.CallStatusHistory
				WHERE CallID = Calls.[ID])
	OR Calls.[ID] IS NULL)
AND (SupplementaryCallStatusItems.[ID] =	(SELECT MAX(SupplementaryCallStatusItems.[ID])
						FROM dbo.SupplementaryCallStatusItems
						WHERE CallID = Calls.[ID])
	OR SupplementaryCallStatusItems.[ID] IS NULL)
AND Calls.AbortReasonID = 0
AND Calls.CallTypeID = 2

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNewInstallations] TO PUBLIC
    AS [dbo];

