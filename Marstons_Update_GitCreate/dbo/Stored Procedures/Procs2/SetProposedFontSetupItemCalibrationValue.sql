CREATE PROCEDURE [dbo].[SetProposedFontSetupItemCalibrationValue]
(
	@ProposedFontSetupID	INT,
	@FontNumber			INT,
	@Reading			INT,
	@Value			FLOAT = NULL,		-- this is no longer used (for compatibility only)
	@Pulses			INT = 1,
	@Volume			FLOAT = 0,
	@Selected			BIT = 0
)

AS

DECLARE @ReadingCount	INT

SET NOCOUNT ON

/* See if we already have an existing reading */
SELECT @ReadingCount = COUNT(*)
FROM ProposedFontSetupCalibrationValues
WHERE ProposedFontSetupID = @ProposedFontSetupID
AND FontNumber = @FontNumber
AND Reading = @Reading

/* Don't allow zero volumes, as they can cause divide by zero errors!  */
IF @Volume = 0
BEGIN
	SET @Volume = 1
END

IF @ReadingCount > 0
BEGIN
	/* Existing reading, so update it */
	UPDATE ProposedFontSetupCalibrationValues
	SET Pulses    = @Pulses, 
		Volume    =  @Volume,
		Selected  = @Selected
	WHERE ProposedFontSetupID = @ProposedFontSetupID
	AND	FontNumber = @FontNumber
	AND	Reading = @Reading

END
ELSE
BEGIN
	 /* We have no existing entry, so add a new one */
	INSERT INTO dbo.ProposedFontSetupCalibrationValues
	(ProposedFontSetupID, FontNumber, Reading, Pulses, Volume, Selected)
	VALUES
	(@ProposedFontSetupID, @FontNumber, @Reading, @Pulses, @Volume, @Selected)
		
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetProposedFontSetupItemCalibrationValue] TO PUBLIC
    AS [dbo];

