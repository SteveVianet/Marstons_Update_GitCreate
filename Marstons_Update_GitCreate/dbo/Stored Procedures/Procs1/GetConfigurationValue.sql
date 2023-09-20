CREATE PROCEDURE [dbo].[GetConfigurationValue]
(
	@PropertyName		VARCHAR(255),
	@PropertyValue		VARCHAR(255)	OUTPUT
)

AS


DECLARE @NumRows	INT
DECLARE @DBID INT

IF @PropertyName <> 'Restrict Sites By User'
BEGIN
  SELECT @NumRows = COUNT(*)
  FROM dbo.Configuration
  WHERE PropertyName = @PropertyName
    IF @NumRows = 1
    BEGIN
	  SELECT @PropertyValue = PropertyValue
	  FROM dbo.Configuration
	  WHERE PropertyName = @PropertyName
    END
    ELSE
    BEGIN
	  SET @PropertyValue = ''
    END
END
ELSE
BEGIN
  SELECT @DBID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'
  SELECT @PropertyValue = MultipleAuditors
  FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
  WHERE ID = @DBID
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetConfigurationValue] TO PUBLIC
    AS [dbo];

