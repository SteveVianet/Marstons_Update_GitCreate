CREATE PROCEDURE [dbo].[GetTamperAuditDetails]
(
	@dtFrom	datetime,
	@dtTo		datetime
)
AS

-- BUILD A TABLE FOR THE USERS
DECLARE @Users TABLE (
	CDA		varchar(60)
)

-- BUILD A TABLE FOR THE SITES
DECLARE @TamperedSites TABLE (
	BriefID		int,
	CDA		varchar(60),
	SiteID		varchar(12),
	SiteName	varchar(60),
	Customer	varchar(60),
	Method		varchar(484),
	VRS		varchar(60),
	Result		varchar(10),
	Reason		varchar(484)
)


-- POPULATE USERS WITH THE SPECIFIC AUDITORS
INSERT INTO @Users (CDA)
	SELECT UPPER(SiteUser)
	FROM Sites
	WHERE 1=1
	AND SiteUser <> '' 
	AND Hidden = 0
	GROUP BY UPPER(SiteUser)


-- NOW ADD THE TRANSIENTS TO THE USERS TABLE
INSERT INTO @Users (CDA)
	SELECT UPPER(InternalUsers.UserName) FROM TamperCaseEvents
	  JOIN InternalUsers ON InternalUsers.[ID] = TamperCaseEvents.UserID
	WHERE UPPER(InternalUsers.UserName) NOT IN (SELECT CDA FROM @Users)
	  AND (StateID = 1 AND SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo
	GROUP BY InternalUsers.[ID], InternalUsers.UserName


-- POPULATE THE USERS INDIVIDUAL SITES
INSERT INTO @TamperedSites (BriefID, CDA, SiteName, SiteID, Reason)
	SELECT TamperCaseEvents.CaseID, InternalUsers.UserName, [Name], SiteID, [Text]
	FROM TamperCaseEvents
	  JOIN TamperCases ON TamperCases.CaseID = TamperCaseEvents.CaseID
	  JOIN Sites ON Sites.EDISID = TamperCases.EDISID
	  JOIN InternalUsers ON InternalUsers.ID = TamperCaseEvents.UserID
	  JOIN @Users As Users ON UPPER(Users.CDA) LIKE UPPER(InternalUsers.UserName)
	WHERE 1 = 1
	  AND UPPER(InternalUsers.UserName) LIKE UPPER(Users.CDA)
	  AND (StateID = 1 AND SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo



-- NOW UPDATE WHETHER THEY WERE ACCEPTED
UPDATE @TamperedSites SET Result = 'Accept', Reason = AcceptedEvents.[Text] 
	FROM TamperCaseEvents
	  JOIN TamperCaseEvents AS AcceptedEvents ON AcceptedEvents.CaseID = TamperCaseEvents.CaseID 
    	    AND AcceptedEvents.StateID = 2
	  JOIN TamperCases ON TamperCases.CaseID = AcceptedEvents.CaseID
	  JOIN Sites ON Sites.EDISID = TamperCases.EDISID
  	  JOIN InternalUsers AS AEIU ON AEIU.ID = AcceptedEvents.UserID
	WHERE BriefID = TamperCaseEvents.CaseID
	  AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo


-- OR REJECTED
UPDATE @TamperedSites SET Result = 'Reject', Reason =  RejectedEvents.[Text]
	FROM TamperCaseEvents
	  JOIN TamperCaseEvents AS RejectedEvents ON RejectedEvents.CaseID = TamperCaseEvents.CaseID 
   	    AND RejectedEvents.StateID = 3
	  JOIN TamperCases ON TamperCases.CaseID = RejectedEvents.CaseID
	  JOIN Sites ON Sites.EDISID = TamperCases.EDISID
 	  JOIN InternalUsers AS AEIU ON AEIU.ID = RejectedEvents.UserID
	WHERE BriefID = TamperCaseEvents.CaseID
	  AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo


-- NOW UPDATE WHO DECIDED THEIR FATE
UPDATE @TamperedSites SET VRS = (
	SELECT AEIU.UserName
	FROM TamperCaseEvents
	  JOIN TamperCaseEvents AS AcceptedEvents ON AcceptedEvents.CaseID = TamperCaseEvents.CaseID 
    	    AND (AcceptedEvents.StateID = 2 OR AcceptedEvents.StateID = 3)
	  JOIN TamperCases ON TamperCases.CaseID = AcceptedEvents.CaseID
	  JOIN Sites ON Sites.EDISID = TamperCases.EDISID
  	  JOIN InternalUsers AS AEIU ON AEIU.ID = AcceptedEvents.UserID
	WHERE BriefID = TamperCaseEvents.CaseID -- 1 = 1 --SiteName = Sites.[Name]
	  AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo
)


-- NOW WRITE THE METHODS
UPDATE @TamperedSites SET Method = 
	dbo.udfConcatTamperTypes(TCE.CaseID)
	FROM TamperCaseEvents TCE
	  JOIN TamperCaseEventTypeList AS TCETL ON TCETL.RefID = TCE.TypeListID
	WHERE BriefID = TCE.CaseID


UPDATE @TamperedSites SET Customer = (
	SELECT PropertyValue
	FROM Configuration
	WHERE PropertyName = 'Company Name'
)

-- Fix null values
UPDATE @TamperedSites SET VRS='' WHERE VRS IS NULL
UPDATE @TamperedSites SET Result='' WHERE Result IS NULL
UPDATE @TamperedSites SET Reason='' WHERE Reason IS NULL

-- show the table
SELECT * FROM @TamperedSites ORDER BY CDA

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperAuditDetails] TO PUBLIC
    AS [dbo];

