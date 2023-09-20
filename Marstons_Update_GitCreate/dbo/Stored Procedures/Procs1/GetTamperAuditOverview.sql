CREATE PROCEDURE [dbo].[GetTamperAuditOverview]
(
	@dtFrom	datetime,
	@dtTo		datetime
) 
AS

-- BUILD A TABLE FOR THE USERS
DECLARE @Results TABLE (
	CDA		varchar(60),
	Found		int default 0,
	Accepted	int default 0,
	Rejected	int default 0,
	Percentage	decimal(3,0) default 0.0,
	Missed		int default 0
)


-- POPULATE WITH THE SPECIFIC AUDITORS
INSERT INTO @Results (CDA)
	SELECT UPPER(SiteUser)
	FROM Sites
	WHERE 1=1
	AND SiteUser <> '' 
	AND Hidden = 0
	GROUP BY UPPER(SiteUser)


-- NOW ADD THE TRANSIENT USERS TO THE TABLE
INSERT INTO @Results (CDA)
	SELECT UPPER(InternalUsers.UserName) FROM TamperCaseEvents
	  JOIN InternalUsers ON InternalUsers.[ID] = TamperCaseEvents.UserID
	WHERE UPPER(InternalUsers.UserName) NOT IN (SELECT CDA FROM @Results)
	  AND (StateID = 1 AND SeverityID = 1)
	GROUP BY InternalUsers.[ID], InternalUsers.UserName
	ORDER BY UPPER(InternalUsers.UserName)


-- NOW FIND OUT HOW MANY EACH HAS ACTUALLY FOUND
UPDATE @Results SET Found = (
	SELECT COUNT(*) 
	FROM TamperCaseEvents
	  JOIN InternalUsers ON InternalUsers.ID = TamperCaseEvents.UserID
	WHERE CDA = UPPER(InternalUsers.UserName)
	  AND (StateID = 1 AND SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo
	GROUP BY TamperCaseEvents.UserID
	HAVING COUNT(*) > 0
)


-- NOW FIND OUT HOW MANY EACH WAS ACCEPTED
UPDATE @Results SET Accepted = (
	SELECT COUNT(*) FROM TamperCaseEvents
	  JOIN TamperCaseEvents AS AcceptedEvents ON AcceptedEvents.CaseID = TamperCaseEvents.CaseID 
    	    AND AcceptedEvents.StateID = 2
  	  JOIN InternalUsers ON InternalUsers.ID = TamperCaseEvents.UserID
	WHERE CDA = UPPER(InternalUsers.UserName)
	  AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo
	GROUP BY TamperCaseEvents.UserID
)


-- AND HOW MANY WERE REJECTED
UPDATE @Results SET Rejected = (
	SELECT COUNT(*) FROM TamperCaseEvents
	  JOIN TamperCaseEvents AS RejectedEvents ON RejectedEvents.CaseID = TamperCaseEvents.CaseID 
    	    AND RejectedEvents.StateID = 3
	  JOIN InternalUsers ON InternalUsers.ID = TamperCaseEvents.UserID
	WHERE CDA = UPPER(InternalUsers.UserName)
	  AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID = 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo
	GROUP BY TamperCaseEvents.UserID
)


-- NOW WE CAN WORK OUT THE PERCENTAGE
UPDATE @Results SET Percentage =
	(Accepted * 100) / Found


-- AND FINALLY HOW MANY OF THEM WERE MISSED
UPDATE @Results SET Missed = (
	SELECT COUNT(*) FROM Sites
	  JOIN TamperCases ON TamperCases.EDISID = Sites.EDISID
	  JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
	  JOIN InternalUsers ON InternalUsers.[ID] = TamperCaseEvents.UserID
	WHERE CDA = UPPER(Sites.SiteUser)
	  AND (TamperCaseEvents.StateID = 1 AND TamperCaseEvents.SeverityID > 1)
	  AND TamperCaseEvents.EventDate BETWEEN @dtFrom AND @dtTo
	GROUP BY UPPER(Sites.SiteUser)
)

-- Fix null values
UPDATE @Results SET Found=0	 WHERE Found	  	IS NULL
UPDATE @Results SET Accepted=0	 WHERE Accepted	IS NULL
UPDATE @Results SET Rejected=0	 WHERE Rejected	IS NULL
UPDATE @Results SET Percentage=0.0	 WHERE Percentage	IS NULL
UPDATE @Results SET Missed=0 	 WHERE Missed	IS NULL

-- show the table
SELECT * FROM @Results ORDER BY CDA

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperAuditOverview] TO PUBLIC
    AS [dbo];

