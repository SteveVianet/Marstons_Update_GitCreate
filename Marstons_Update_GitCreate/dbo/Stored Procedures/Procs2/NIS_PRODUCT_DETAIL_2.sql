CREATE PROCEDURE dbo.NIS_PRODUCT_DETAIL_2
(	
	@PCODE	AS	VARCHAR(50)
)
AS
SELECT     BrulinesProductID, Code AS NucleusPCode, Description
FROM         dbo.NucleusProducts
WHERE     (Code = @PCODE)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_PRODUCT_DETAIL_2] TO PUBLIC
    AS [dbo];

