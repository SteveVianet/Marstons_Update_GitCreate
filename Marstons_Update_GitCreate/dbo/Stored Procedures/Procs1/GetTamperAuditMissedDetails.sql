CREATE PROCEDURE dbo.GetTamperAuditMissedDetails
(
	@From		DATETIME,
	@To		DATETIME
)
AS

DECLARE @Customer VARCHAR(60)

SELECT @Customer = PropertyValue
FROM Configuration
WHERE PropertyName = 'Company Name'

SELECT Sites.SiteUser AS CDA, 
	Sites.SiteID, 
	Sites.[Name] AS SiteName, 
	@Customer AS Customer,
	dbo.udfConcatTamperTypes(TamperCaseEvents.CaseID) AS Method, 
	[Text] AS Reason
FROM Sites
JOIN TamperCases ON TamperCases.EDISID = Sites.EDISID
JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID > 1)
AND TamperCaseEvents.EventDate BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperAuditMissedDetails] TO PUBLIC
    AS [dbo];

