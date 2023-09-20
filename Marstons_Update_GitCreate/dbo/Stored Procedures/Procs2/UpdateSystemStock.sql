CREATE PROCEDURE dbo.UpdateSystemStock
(
	@SystemStockID	INTEGER,
	@DateIn		DATETIME,
	@DateOut		DATETIME,
	@OldInstallDate		DATETIME,
	@EDISID		INTEGER,
	@SystemTypeID	INTEGER,
	@CallID			INTEGER,
	@PreviousEDISID	INTEGER,
	@PreviousName	VARCHAR(100),
	@PreviousPostcode	VARCHAR(25),
	@PreviousFMCount	INTEGER,
	@WrittenOff		BIT = 0,
	@Comment		VARCHAR(8000) = NULL
)
AS

UPDATE dbo.SystemStock
SET DateIn = @DateIn,
        DateOut = @DateOut,
        OldInstallDate = @OldInstallDate,
        EDISID = @EDISID,
        SystemTypeID = @SystemTypeID,
        CallID = @CallID,
        PreviousEDISID = @PreviousEDISID,
        PreviousName = @PreviousName,
        PreviousPostcode = @PreviousPostcode,
        PreviousFMCount = @PreviousFMCount,
        WrittenOff = @WrittenOff,
        Comment = @Comment
WHERE [ID] = @SystemStockID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSystemStock] TO PUBLIC
    AS [dbo];

