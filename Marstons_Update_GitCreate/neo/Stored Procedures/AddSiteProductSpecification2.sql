CREATE PROCEDURE [neo].[AddSiteProductSpecification2]
(
	@EDISID 		INT,
	@ProductID		INT,
	@TempSpec		REAL = NULL,
	@TempTolerance	REAL = NULL,
	@FlowSpec		REAL = NULL,
	@FlowTolerance	REAL = NULL,
	@CleanDaysBeforeAmber	INT = NULL,
	@CleanDaysBeforeRed		INT = NULL
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

	EXEC [SQL2\SQL2].[Global].dbo.AddSiteProductSpecification @GlobalEDISID, @GlobalProductID, @TempSpec, @TempTolerance, @FlowSpec, @FlowTolerance
END
*/

INSERT INTO dbo.SiteProductSpecifications
  (EDISID, ProductID, TempSpec, TempTolerance, FlowSpec, FlowTolerance, CleanDaysBeforeAmber, CleanDaysBeforeRed)
VALUES
  (@EDISID, @ProductID, @TempSpec, @TempTolerance, @FlowSpec, @FlowTolerance, @CleanDaysBeforeAmber, @CleanDaysBeforeRed)

END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[AddSiteProductSpecification2] TO PUBLIC
    AS [dbo];

