CREATE PROCEDURE [dbo].[IsKeyProduct] 
(
	@EDISID	INT,
	@ProductID	INT
)
AS

IF EXISTS (SELECT 1 FROM SiteKeyProducts WHERE EDISID=@EDISID AND ProductID=@ProductID) select 1 else select 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[IsKeyProduct] TO PUBLIC
    AS [dbo];

