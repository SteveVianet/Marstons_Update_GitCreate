CREATE PROCEDURE [dbo].[GetSitesOverYearThresholdReport]
(
	@YearThreshold	INT
)
AS

SELECT SiteID, 
	 [Name], 
	 PostCode, 
	 InstallationDate, 
	 Contracts.[Description] AS Contract,
	 Sites.EDISID,
	 Contracts.ID AS ContractID,
	 ISNULL(CallSummary.ClosedOn, CAST('1900-01-01' AS DATETIME)) AS ClosedOn,
	 Sites.SiteClosed
FROM Sites
LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
LEFT JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
LEFT JOIN (
		SELECT EDISID, MAX(ClosedOn) AS ClosedOn
		FROM Calls
		WHERE ClosedOn IS NOT NULL
		AND AbortReasonID = 0
		GROUP BY EDISID
) AS CallSummary ON CallSummary.EDISID = Sites.EDISID
WHERE InstallationDate < DATEADD(year, @YearThreshold*-1, GETDATE())
AND Hidden = 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesOverYearThresholdReport] TO PUBLIC
    AS [dbo];

