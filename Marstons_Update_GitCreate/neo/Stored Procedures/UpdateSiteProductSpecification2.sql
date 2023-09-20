CREATE PROCEDURE [neo].[UpdateSiteProductSpecification2] 
(
        @EDISID			INT,
        @ProductID		INT,
        @TempSpec		REAL = NULL,
        @TempTolerance		REAL = NULL,
        @FlowSpec		REAL = NULL,
        @FlowTolerance		REAL = NULL,
        @CleanDaysBeforeAmber	INT = NULL,
        @CleanDaysBeforeRed	INT = NULL
)

AS
BEGIN
SET NOCOUNT ON

/*
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @ProductID 
	
	EXEC [SQL2\SQL2].[Global].dbo.UpdateSiteProductSpecification @GlobalEDISID, @GlobalProductID, @TempSpec, @TempTolerance, @FlowSpec, @FlowTolerance, @CleanDaysBeforeAmber, @CleanDaysBeforeRed
END
*/

UPDATE dbo.SiteProductSpecifications
SET	EDISID = @EDISID,
	ProductID = @ProductID,
	TempSpec = @TempSpec,
	TempTolerance = @TempTolerance,
	FlowSpec = @FlowSpec,
	FlowTolerance = @FlowTolerance,
	CleanDaysBeforeAmber = @CleanDaysBeforeAmber,
	CleanDaysBeforeRed = @CleanDaysBeforeRed	
WHERE [EDISID] = @EDISID AND [ProductID] = @ProductID
END