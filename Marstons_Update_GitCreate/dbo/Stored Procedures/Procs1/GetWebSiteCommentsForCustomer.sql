--/*
CREATE PROCEDURE [dbo].[GetWebSiteCommentsForCustomer]
(
	@EDISID	INT,
	@From	DATETIME,
	@Type	INT = 1
)
AS
--*/

/* Based on: GetWebSiteComments
    Modified to restrict the Comments displayed to the customer.
*/

--DECLARE	@EDISID	INT = 5494
--DECLARE	@From	DATETIME = '2017-01-02'
--DECLARE	@Type	INT = 1

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

SELECT TOP 5 [Date], SiteCommentHeadingTypes.[Description] AS [Heading], [Text] AS Comment
FROM [dbo].SiteComments 
JOIN [dbo].SiteCommentHeadingTypes 
  ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
WHERE [Type] = @Type
  AND EDISID = @EDISID
  AND [Date] BETWEEN @From AND @WebAuditDate
  AND [HeadingType] NOT BETWEEN 5000 AND 5004
UNION
SELECT TOP 1 [Date], SiteCommentHeadingTypes.[Description] AS [Heading], [Text] AS Comment
FROM [dbo].SiteComments 
JOIN [dbo].SiteCommentHeadingTypes 
  ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
WHERE [Type] = @Type
  AND EDISID = @EDISID
  AND [Date] BETWEEN @VisibleStart AND @VisibleEnd
  AND [HeadingType] BETWEEN 5000 AND 5004
ORDER BY [Date] DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteCommentsForCustomer] TO PUBLIC
    AS [dbo];

