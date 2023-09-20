CREATE PROCEDURE [dbo].[DeleteTLComments]
(
    @EDISID INT = NULL
)
AS

DELETE FROM [dbo].[SiteComments]
WHERE 
    (@EDISID IS NULL OR [EDISID] = @EDISID)
AND [HeadingType] IN (5000,5001,5002,5003,5004) -- Used by: ExceptionNegativeTrend, ExceptionTrafficLightStock
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteTLComments] TO PUBLIC
    AS [dbo];

