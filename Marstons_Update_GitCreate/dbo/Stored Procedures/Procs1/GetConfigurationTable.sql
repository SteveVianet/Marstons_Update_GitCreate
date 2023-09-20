-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetConfigurationTable]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @DBID INT

	SELECT @DBID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

	SELECT [PropertyName] ,[PropertyValue]
	FROM [Configuration]
	UNION ALL
	SELECT  'Restrict Sites By User' AS PropertyName,
	CASE WHEN MultipleAuditors = 1 THEN '1' ELSE '0' END AS PropertyValue
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS EDISDatabases
	WHERE EDISDatabases.ID = @DBID

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetConfigurationTable] TO PUBLIC
    AS [dbo];

