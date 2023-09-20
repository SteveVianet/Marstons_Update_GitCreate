CREATE PROCEDURE [dbo].[zRS_ServiceHistory]

(
@Site	VARCHAR(60) = NULL,   
@From	DATETIME	= NULL,
@To		DATETIME	= NULL
)

AS

SELECT SiteID
		,Calls.ID
		,CallTypes.Description			AS CallType
		,CallCategories.Description		AS CallCategory
		,VisitedOn
 		,CASE WHEN CallTypeID = 2 THEN 'Installation' ELSE CASE WHEN Calls.UseBillingItems = 1 
         THEN dbo.udfConcatCallReasonsSingleLine(Calls.[ID]) 
         ELSE dbo.udfConcatCallFaults(Calls.[ID])END  END										AS CallOutReason
                        
        ,CASE WHEN Calls.UseBillingItems = 1 
         THEN REPLACE(dbo.udfConcatCallBillingItems(Calls.ID), '<br>', '') 
         ELSE dbo.GetWorkItemDescriptionFunction(Calls.[ID]) END								AS WorkCompleted		
		
FROM Calls
JOIN Sites ON Sites.EDISID = Calls.EDISID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallTypes AS CallTypes	ON	CallTypes.ID = Calls.CallTypeID
--LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallFaultTypes AS FaultTypes ON FaultTypes.ID = CallFaults.FaultTypeID
LEFT JOIN  [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID 



WHERE SiteID = @Site

AND Calls.VisitedOn BETWEEN @From AND @To

ORDER By VisitedOn   

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_ServiceHistory] TO PUBLIC
    AS [dbo];

