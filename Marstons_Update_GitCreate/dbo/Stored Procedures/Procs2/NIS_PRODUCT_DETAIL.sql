CREATE PROCEDURE dbo.NIS_PRODUCT_DETAIL
(	
	@PRODUCTID	AS	INT
)
AS
SELECT     BrulinesProductID, Code AS NucleusPCode, Description
FROM         dbo.NucleusProducts
WHERE     (BrulinesProductID = @PRODUCTID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_PRODUCT_DETAIL] TO PUBLIC
    AS [dbo];

