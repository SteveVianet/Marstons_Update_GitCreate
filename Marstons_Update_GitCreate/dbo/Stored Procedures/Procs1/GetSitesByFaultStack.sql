CREATE PROCEDURE [dbo].[GetSitesByFaultStack]
(
	@Filter			VARCHAR(255),
	@From			DATETIME,
	@To			DATETIME
)

AS

SET NOCOUNT ON

DECLARE @DBID INT

SELECT @DBID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetSitesByFaultStack @Filter, @From, @To, @DBID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesByFaultStack] TO PUBLIC
    AS [dbo];

