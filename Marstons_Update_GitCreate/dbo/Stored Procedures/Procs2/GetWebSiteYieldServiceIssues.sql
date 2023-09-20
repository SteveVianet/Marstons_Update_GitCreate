CREATE PROCEDURE [dbo].[GetWebSiteYieldServiceIssues]
	@EDISID			INT,
	@DateFrom		DATETIME,
	@DateTo			DATETIME
AS

SET NOCOUNT ON;

SELECT sie.CallID, 
	DateFrom, 
	CAST(DateTo AS DATE) AS DateTo, 
	Products.[Description], 
	sie.PrimaryProductID AS ID, 
	Calls.VisitedOn AS VisitedOn, 
	CallReasonTypes.[Description] AS CallReason,
	dbo.udfConcatCallBillingItemsWorkCompleted(sie.CallID) AS WorkCompleted,
	CallCategories.[Description] AS CallCategory,
	CallTypes.[Description] AS CallType
FROM ServiceIssuesYield AS sie
INNER JOIN Products ON Products.ID = sie.ProductID
INNER JOIN Calls ON Calls.ID = sie.CallID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallTypes AS CallTypes ON CallTypes.ID = Calls.CallTypeID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes ON CallReasonTypes.ID = sie.CallReasonTypeID
WHERE sie.EDISID = @EDISID
AND (sie.DateTo IS NULL OR CAST(sie.DateTo AS DATE) >= @DateFrom)
AND sie.DateFrom <= @DateTo


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteYieldServiceIssues] TO PUBLIC
    AS [dbo];

