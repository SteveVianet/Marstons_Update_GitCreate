
CREATE PROCEDURE [dbo].[GetCalibratorQueryTypes] 

AS
BEGIN
	
	SET NOCOUNT ON;
	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCalibratorQueryTypes 

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalibratorQueryTypes] TO PUBLIC
    AS [dbo];

