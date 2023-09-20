CREATE PROCEDURE dbo.ImportSystemData AS

DECLARE @DBID INT

SELECT @DBID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

-- Starway IFM
