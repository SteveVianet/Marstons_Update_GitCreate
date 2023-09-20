CREATE PROCEDURE [dbo].[GetTamperAuditVRSIdentified]
(
	@dtFrom	datetime,
	@dtTo		datetime
)
AS

SELECT SiteID, [Name], UserName, EventDate, [Description], SiteUser 
FROM TamperCaseEvents
  JOIN InternalUsers 
    ON InternalUsers.[ID] = TamperCaseEvents.UserID	  
  JOIN TamperCases 
    ON TamperCases.CaseID = TamperCaseEvents.CaseID
  JOIN Sites ON Sites.EDISID = TamperCases.EDISID
  JOIN TamperCaseEventsSeverityDescriptions
    ON TamperCaseEventsSeverityDescriptions.[ID] = TamperCaseEvents.SeverityID
WHERE StateID = 1 AND SeverityID > 1
  AND EventDate BETWEEN @dtFrom AND @dtTo

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperAuditVRSIdentified] TO PUBLIC
    AS [dbo];

