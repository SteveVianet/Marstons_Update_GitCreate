--/*
CREATE PROCEDURE [dbo].[GetWebSiteConsolidatedCommentsForCustomer]
(
	@EDISID	INT,
	@From	DATETIME
)

AS
--*/

/* Based on: GetWebSiteConsolidatedComments
    Modified to restrict the Comments displayed to the customer.
*/

/* Debug Parameters */
--DECLARE	@EDISID	INT = 5494
--DECLARE	@From			DATETIME = '2017-01-02'

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @VisibleStart DATE
DECLARE @VisibleEnd DATE

EXEC [dbo].[GetCustomerVisibleDates] @VisibleStart OUTPUT, @VisibleEnd OUTPUT

--SELECT @VisibleStart AS [VisibleStart], @VisibleEnd AS [VisibleEnd]

DECLARE @WebAuditDate DATE
SELECT @WebAuditDate = DATEADD(Day, 6, CAST([PropertyValue] AS DATE)) 
FROM [dbo].[Configuration]
WHERE [PropertyName] = 'AuditDate'

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
	AND [Date] BETWEEN @From AND @WebAuditDate
    AND [HeadingType] NOT BETWEEN 5000 AND 5004
ORDER BY [Type] DESC

INSERT INTO #ConsolidatedComments([Date], CommentType, CommentHeading, CommentText)
SELECT	[Date],  
		CASE  [Type]
		WHEN 1 THEN 'Auditor'
		WHEN 2 THEN 'BDM' END AS CommentType,
		SiteCommentHeadingTypes.[Description] AS [Heading], 
		[Text] AS Comment		
FROM SiteComments 
JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
WHERE [Type] = 1	--Auditor
	AND EDISID = @EDISID
	AND [Date] BETWEEN @VisibleStart AND @VisibleEnd
    AND [HeadingType] BETWEEN 5000 AND 5004
ORDER BY [Type] DESC

--VRS BDM Comments
INSERT INTO #ConsolidatedComments([Date], CommentType, CommentHeading, CommentText)
SELECT	VisitRecords.VisitDate, 
		'VRS', 
		'BDM Comment',
		BDMComment 
FROM VisitRecords 
WHERE EDISID = @EDISID
AND VisitDate BETWEEN @From AND @WebAuditDate
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
AND VisitRecords.VisitDate BETWEEN @From AND @WebAuditDate

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
AND TamperCaseEvents.EventDate BETWEEN @From AND @WebAuditDate

SELECT [Date],
	   CommentType, 
	   CommentHeading, 
	   ISNULL(CommentText, '') AS CommentText
FROM #ConsolidatedComments
ORDER BY [Date] DESC
DROP TABLE #ConsolidatedComments

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteConsolidatedCommentsForCustomer] TO PUBLIC
    AS [dbo];

