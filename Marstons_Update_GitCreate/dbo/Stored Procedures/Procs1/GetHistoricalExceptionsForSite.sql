CREATE PROCEDURE [dbo].[GetHistoricalExceptionsForSite]
       @EDISID              INT,
       @TradingDate DATETIME
AS

SET NOCOUNT ON;

SELECT se.EDISID, se.ID, se.[Type], se.TypeID, se.TradingDate, 
       se.Value, CAST(se.LowThreshold AS VARCHAR) AS 'LowThreshold', CAST(se.HighThreshold AS VARCHAR) AS 'HighThreshold', 
       se.ShiftStart, se.ShiftEnd, se.AdditionalInformation
FROM SiteExceptions se
       JOIN SiteExceptionTypes AS setypes ON setypes.[Description] = se.[Type]
WHERE EDISID = @EDISID
       AND se.TradingDate >= CONVERT(date, @TradingDate)
ORDER BY se.TradingDate ASC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHistoricalExceptionsForSite] TO PUBLIC
    AS [dbo];

