CREATE PROCEDURE [dbo].[AddCleaningStack]
(
	@EDISID		INT,
	@Date		DATETIME,
	@Time		DATETIME,
	@Line		INT,
	@Volume		FLOAT
)

AS

DECLARE @CleaningID		INT
DECLARE @GlobalEDISID	INT

SET NOCOUNT ON

-- Find MasterDate, adding it if we need to
SELECT @CleaningID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

IF @CleaningID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @CleaningID = @@IDENTITY
END

INSERT INTO dbo.CleaningStack
(CleaningID, [Time], Line, Volume)
VALUES
(@CleaningID, @Time, @Line, @Volume)

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.AddCleaningStack @GlobalEDISID, @Date, @Time, @Line, @Volume
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCleaningStack] TO PUBLIC
    AS [dbo];

