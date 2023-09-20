CREATE FUNCTION dbo.GetCallReference (@CallID as int)
RETURNS varchar(100)
AS
BEGIN
DECLARE @DatabaseID INTEGER
--DECLARE @CallID INTEGER
 
--SET @DatabaseID = 4
SELECT @DatabaseID = PropertyValue
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

--PRINT @DatabaseID
--SET @CallID = 57895
 
DECLARE @CallReference VARCHAR(20)
DECLARE @Total INTEGER
DECLARE @Pos INT
 
SET @CallReference = CAST(@DatabaseID AS VARCHAR) + '-' + CAST(@CallID AS VARCHAR)
SET @Total = 0
 
SET @Pos = 1
WHILE LEN(@CallReference) > 0
BEGIN
 SET @Total = @Total + (ASCII(LEFT(@CallReference, 1)))* @Pos
 SET @CallReference = SUBSTRING(@CallReference, 2, LEN(@CallReference)-1)
 SET @Pos = @Pos + 1
END
 

RETURN CAST(@DatabaseID AS VARCHAR) + '-' + CAST(@CallID AS VARCHAR)+'/'+UPPER(RIGHT(REPLACE(LTRIM(REPLACE(STUFF(master.dbo.fn_varbintohexstr(@Total), 1, 2, ''), '0', ' ')), ' ', '0'), 2))
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallReference] TO PUBLIC
    AS [dbo];

