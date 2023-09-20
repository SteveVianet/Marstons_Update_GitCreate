


CREATE PROCEDURE  [dbo].[GetKeyProducts] 
	-- Add the parameters for the stored procedure here
	(
		@EDISID	INT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [ProductID]
	FROM [dbo].[SiteKeyProducts]
	WHERE EDISID = @EDISID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetKeyProducts] TO PUBLIC
    AS [dbo];

