CREATE PROCEDURE [neo].[GetProductCategoryInfo] (
    @Products neo.IDTable READONLY,
	@Verbose BIT = 0
	)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	IF @Verbose = 1
		SELECT *
		FROM ProductCategories AS pc
		JOIN Products AS p
			ON p.CategoryID = pc.ID
		JOIN @Products as prod
			ON prod.ID = p.ID
	ELSE

	SELECT pc.ID, pc.Description
	FROM ProductCategories AS pc
	JOIN Products AS p
		ON p.CategoryID = pc.ID
	JOIN @Products as prod
		ON prod.ID = p.ID
 
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetProductCategoryInfo] TO PUBLIC
    AS [dbo];

