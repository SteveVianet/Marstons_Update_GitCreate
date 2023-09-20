CREATE PROCEDURE [dbo].[AddSystemStock]
(
	@DateIn		DATETIME,
	@OldInstallDate		DATETIME,
	@EDISID		INTEGER,
	@SystemTypeID	INTEGER,
	@CallID			INTEGER,
	@PreviousEDISID	INTEGER,
	@PreviousName	VARCHAR(100),
	@PreviousPostcode	VARCHAR(25),
	@PreviousFMCount	INTEGER,
	@WrittenOff		BIT = 0,
	@Comment		VARCHAR(8000) = NULL,
	@NewID		INTEGER OUTPUT
)

AS

SET NOCOUNT ON

DECLARE @Duplicate INT
SET @NewID = 0

SELECT @Duplicate = COUNT(*)
FROM dbo.SystemStock
WHERE PreviousEDISID = @PreviousEDISID
AND DateOut IS NULL
AND DateIn >= CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, @DateIn)))

IF @Duplicate = 0
BEGIN
	INSERT INTO dbo.SystemStock
	(DateIn, OldInstallDate, EDISID, SystemTypeID, CallID, PreviousEDISID, PreviousName, PreviousPostcode, PreviousFMCount, WrittenOff, Comment)
	VALUES
	(@DateIn, @OldInstallDate, @EDISID, @SystemTypeID, @CallID, @PreviousEDISID, @PreviousName, @PreviousPostcode, @PreviousFMCount, @WrittenOff, @Comment)

	SET @NewID = @@IDENTITY
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSystemStock] TO PUBLIC
    AS [dbo];

