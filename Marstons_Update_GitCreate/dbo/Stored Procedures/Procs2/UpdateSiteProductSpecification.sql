CREATE PROCEDURE [dbo].[UpdateSiteProductSpecification] 
(
        @EDISID			INT,
        @ProductID		INT,
        @TempSpec		REAL,
        @TempTolerance		REAL,
        @FlowSpec		REAL,
        @FlowTolerance		REAL,
        @CleanDaysBeforeAmber	INT = NULL,
        @CleanDaysBeforeRed	INT = NULL
)

AS

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


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteProductSpecification] TO PUBLIC
    AS [dbo];

