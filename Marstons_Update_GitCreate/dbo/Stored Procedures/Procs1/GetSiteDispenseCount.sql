-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.GetSiteDispenseCount
    
    @EDISID int = NULL,
    @StartDate datetime = NULL,
    @EndDate datetime = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT([EDISID]) AS DispenseRows
    FROM [dbo].[DispenseActions]
    WHERE EDISID=@EDISID
    AND StartTime BETWEEN @StartDate AND @EndDate

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispenseCount] TO [fusion]
    AS [dbo];

