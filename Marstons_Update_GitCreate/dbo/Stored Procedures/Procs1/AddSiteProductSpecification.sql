CREATE PROCEDURE [dbo].[AddSiteProductSpecification]
(
	@EDISID 		INT,
	@ProductID		INT,
	@TempSpec		REAL,
	@TempTolerance	REAL,
	@FlowSpec		REAL,
	@FlowTolerance	REAL,
	@CleanDaysBeforeAmber	INT = NULL,
	@CleanDaysBeforeRed		INT = NULL
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

	EXEC [SQL2\SQL2].[Global].dbo.AddSiteProductSpecification @GlobalEDISID, @GlobalProductID, @TempSpec, @TempTolerance, @FlowSpec, @FlowTolerance
END
*/

INSERT INTO dbo.SiteProductSpecifications
  (EDISID, ProductID, TempSpec, TempTolerance, FlowSpec, FlowTolerance, CleanDaysBeforeAmber, CleanDaysBeforeRed)
VALUES
  (@EDISID, @ProductID, @TempSpec, @TempTolerance, @FlowSpec, @FlowTolerance, @CleanDaysBeforeAmber, @CleanDaysBeforeRed)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteProductSpecification] TO PUBLIC
    AS [dbo];

