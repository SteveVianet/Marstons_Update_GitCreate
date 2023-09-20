CREATE PROCEDURE [dbo].[BackdateEstimatedDrinks]
(
	@EDISID	INT = NULL,
	@StartDate	DATETIME = NULL,
	@EndDate	DATETIME = NULL,
	@ProductID	INT = NULL
)

AS

SET NOCOUNT ON

DECLARE @GlobalEDISID		INTEGER
DECLARE @GlobalProductID		INTEGER

-- Nasty debug thingy
DECLARE @Debug VARCHAR(1024)
SET @Debug = 'EDISID = ' + CAST(ISNULL(@EDISID, -1) AS VARCHAR)  + ', StartDate = ' + CONVERT(VARCHAR, ISNULL(@StartDate, '1900-01-01'), 103) + ', EndDate = ' + CONVERT(VARCHAR, ISNULL(@EndDate, '1900-01-01'), 103) + ', ProductID = ' + CAST(ISNULL(@ProductID, -1) AS VARCHAR)
EXEC dbo.LogError 248, @Debug, 'dbo.BackdateDrinkVolumes', 'Begin'


UPDATE dbo.DispenseActions
SET dbo.DispenseActions.EstimatedDrinks = dbo.fnGetSiteDrinkVolume(EDISID, Pints*100, Product) 
FROM dbo.DispenseActions
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
AND (Product = @ProductID OR @ProductID IS NULL)
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @StartDate OR @StartDate IS NULL)
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) <= @EndDate OR @EndDate IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[BackdateEstimatedDrinks] TO PUBLIC
    AS [dbo];

