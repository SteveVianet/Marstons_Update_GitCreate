CREATE PROCEDURE [dbo].[GetWebSiteConsolidatedComments]
(
	@EDISID	INT,
	@From	DATETIME
)

AS

CREATE TABLE #ConsolidatedComments([Date] Date, CommentType VARCHAR(255), CommentHeading VARCHAR(255), CommentText VARCHAR(MAX))

INSERT INTO #ConsolidatedComments([Date], CommentType, CommentHeading, CommentText)
SELECT	[Date],  
		CASE  [Type]
		WHEN 1 THEN 'Auditor'
		WHEN 2 THEN 'BDM' END AS CommentType,
		SiteCommentHeadingTypes.[Description] AS [Heading], 
		[Text] AS Comment		
FROM SiteComments 
JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
WHERE ([Type] = 1	--Auditor]
	OR [Type] = 2) --BDM 
	AND EDISID = @EDISID
	AND [Date] BETWEEN @From AND GETDATE()
ORDER BY [Type] DESC

--VRS BDM Comments
INSERT INTO #ConsolidatedComments([Date], CommentType, CommentHeading, CommentText)
SELECT	VisitRecords.VisitDate, 
		'VRS', 
		'BDM Comment',
		BDMComment 
FROM VisitRecords 
WHERE EDISID = @EDISID
AND VisitDate BETWEEN @From AND GETDATE()
AND BDMComment IS NOT NULL

--VRS Final Outcome Comments
INSERT INTO #ConsolidatedComments([Date], CommentType, CommentHeading, CommentText)
SELECT	VisitRecords.VisitDate, 
		'VRS', 
		'Visit Outcome', 
		OutcomeDescription.Description AS CommentText 
FROM VisitRecords
JOIN VRSVisitOutcome ON VRSVisitOutcome.VisitOutcomeID = VisitRecords.VisitOutcomeID
JOIN [EDISSQL1\SQL1].[ServiceLogger].dbo.VRSVisitOutcome AS OutcomeDescription ON OutcomeDescription.ID = VRSVisitOutcome.VisitOutcomeID
WHERE VisitRecords.EDISID = @EDISID
AND VisitRecords.VisitDate BETWEEN @From AND GETDATE()

--Tampering Comments
INSERT INTO #ConsolidatedComments([Date], CommentType, CommentHeading, CommentText)
SELECT	EventDate AS Date,
		'Tampering' AS CommentType,
		CASE SeverityID
			WHEN 0 THEN 'Resolved'
			WHEN 1 THEN 'Suspected'
			WHEN 2 THEN 'Low Level'
			WHEN 3 THEN 'High Level'
			WHEN 4 THEN 'Confirmation'
		END + ': ' + TamperCaseEventTypeDescriptions.Description AS CommentTitle,
		[Text] AS CommentText
FROM dbo.TamperCaseEvents
JOIN TamperCases ON TamperCases.CaseID = TamperCaseEvents.CaseID
JOIN TamperCaseEventTypeList ON TamperCaseEventTypeList.RefID = TamperCaseEvents.TypeListID
JOIN TamperCaseEventTypeDescriptions ON TamperCaseEventTypeDescriptions.ID = TamperCaseEventTypeList.TypeID 
WHERE TamperCases.EDISID = @EDISID
AND TamperCaseEvents.EventDate BETWEEN @From AND GETDATE()

SELECT [Date],
	   CommentType, 
	   CommentHeading, 
	   ISNULL(CommentText, '') AS CommentText
FROM #ConsolidatedComments
ORDER BY [Date] DESC
DROP TABLE #ConsolidatedComments

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteConsolidatedComments] TO PUBLIC
    AS [dbo];

