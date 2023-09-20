CREATE PROCEDURE neo.GetProductCategoryPouringYieldTarget
	@ProductCategoryID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Doesn't take into account users that have sites which span owners...
	SELECT TargetPouringYield AS PouringYieldTarget
	FROM ProductCategories AS pc
	WHERE pc.ID = @ProductCategoryID
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetProductCategoryPouringYieldTarget] TO PUBLIC
    AS [dbo];

