
CREATE PROCEDURE [dbo].[GetSiteOutstandingDayExceptions]
(
	@EDISID			INT,
	@ExceptionDate	DATE
)
AS

SET NOCOUNT ON

DECLARE @SiteGroupID INT

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

IF @SiteGroupID IS NOT NULL
BEGIN
	SELECT @EDISID = EDISID
	FROM SiteGroupSites
	WHERE SiteGroupSites.IsPrimary = 1
	AND SiteGroupID = @SiteGroupID
END

SELECT SiteExceptions.ID,
	   SiteExceptions.ExceptionHTML, 
	   SiteExceptions.TradingDate, 
	   SiteExceptions.SiteDescription, 
	   SiteExceptions.[DateFormat], 
	   SiteExceptions.EmailReplyTo 
FROM SiteExceptions
JOIN SiteExceptionTypes AS SiteExceptionTypes ON SiteExceptionTypes.[Description] = SiteExceptions.[Type]
WHERE SiteExceptions.EDISID = @EDISID
AND SiteExceptions.TradingDate = @ExceptionDate
AND SiteExceptions.ExceptionEmailID IS NULL
AND SiteExceptions.[Type] <> 'Equipment Alarm'
ORDER BY SiteExceptions.TradingDate ASC, SiteExceptionTypes.[Rank] ASC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteOutstandingDayExceptions] TO PUBLIC
    AS [dbo];

