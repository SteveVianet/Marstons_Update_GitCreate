CREATE PROCEDURE [dbo].[GetCallUsedStock]
(
	@CallID	INT
)

AS


DECLARE @DatabaseID INTEGER
DECLARE @CallRef VARCHAR(20)

SELECT @DatabaseID = ID FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases WHERE Name = db_name()
 
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

SET @CallRef = CAST(@DatabaseID AS VARCHAR) + '-' + CAST(@CallID AS VARCHAR)+'/'+UPPER(RIGHT(REPLACE(LTRIM(REPLACE(STUFF(master.dbo.fn_varbintohexstr(@Total), 1, 2, ''), '0', ' ')), ' ', '0'), 2))

SELECT Category, Item, Type, Quantity FROM [SQL1\SQL1].ServiceLogger.dbo.ENG_StockUsed 
WHERE CallReference = @CallRef
AND Quantity > 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallUsedStock] TO PUBLIC
    AS [dbo];

