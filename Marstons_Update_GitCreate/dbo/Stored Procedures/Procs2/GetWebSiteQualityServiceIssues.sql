
CREATE PROCEDURE [dbo].[GetWebSiteQualityServiceIssues]
	@EDISID			INT,
	@DateFrom		DATETIME,
	@DateTo			DATETIME
AS

SET NOCOUNT ON;

SELECT siq.CallID, 
	DateFrom, 
	CAST(DateTo AS DATE) AS DateTo, 
	Products.[Description], 
	PumpID,
	siq.PrimaryProductID AS ID, 
	Calls.VisitedOn AS VisitedOn, 
	CallReasonTypes.[Description] AS CallReason,
	dbo.udfConcatCallBillingItemsWorkCompleted(siq.CallID) AS WorkCompleted,
	CallCategories.[Description] AS CallCategory,
	CallTypes.[Description] AS CallType
FROM ServiceIssuesQuality AS siq
INNER JOIN Products ON Products.ID = siq.ProductID
INNER JOIN Calls ON Calls.ID = siq.CallID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes ON CallReasonTypes.ID = siq.CallReasonTypeID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallTypes AS CallTypes ON CallTypes.ID = Calls.CallTypeID
WHERE siq.EDISID = @EDISID
AND (siq.DateTo IS NULL OR CAST(siq.DateTo AS DATE) >= @DateFrom)
AND siq.DateFrom <= @DateTo


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteQualityServiceIssues] TO PUBLIC
    AS [dbo];

