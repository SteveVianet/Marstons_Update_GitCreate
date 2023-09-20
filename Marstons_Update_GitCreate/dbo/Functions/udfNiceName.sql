CREATE FUNCTION [dbo].[udfNiceName] (@name varchar(255))  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @n varchar(255)
DECLARE @i int
DECLARE @reset bit
DECLARE @c char(1)

SET @i = 1
SET @reset = 1
SET @n = ''

SET @name = REPLACE(@name, 'MAINGROUP\', '') -- remove preceding MAINGROUP\
SET @name = REPLACE(@name, '.', ' ') -- replace periods with spaces
-- Capitalize The First Letter Of Each Word
WHILE (@i <= LEN(@name)) 
	SELECT @c = SUBSTRING(@name,@i,1), 
		@n = @n + CASE WHEN @reset=1 THEN UPPER(@c) ELSE LOWER(@c) END,
		@reset = CASE WHEN @c LIKE '[a-zA-Z]' THEN 0 ELSE 1 END,
		@i = @i +1

RETURN @n

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfNiceName] TO PUBLIC
    AS [dbo];

