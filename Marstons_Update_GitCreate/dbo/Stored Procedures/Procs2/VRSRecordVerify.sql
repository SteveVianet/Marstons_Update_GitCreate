CREATE PROCEDURE [dbo].[VRSRecordVerify]
(
	@VisitNoteID	INT,
	@SendMails		BIT = 0
)

AS

SET NOCOUNT ON

DECLARE @Days INT
DECLARE @ResendEmailOn DATETIME
DECLARE @FurtherActionID INT
DECLARE @EDISID INT
DECLARE @EscalateToUserType INT


--Mark as verified
UPDATE VisitRecords
SET	VerifiedByVRS = 1,
	VerifiedDate = GETDATE()
WHERE [ID] = @VisitNoteID
AND Deleted = 0


IF @SendMails = 1
BEGIN
	--Check if not can be closed
	SET @EscalateToUserType = dbo.fnGetEscalationRecipientType(@VisitNoteID)
	IF @EscalateToUserType = 0
	BEGIN
		UPDATE VisitRecords
		SET	CompletedByCustomer = 1,
		CompletedDate = GETDATE(),
		BDMCommentDate = GETDATE(),
		BDMActionTaken = 2,
		BDMComment = 'Visit closed by Brulines.'
		WHERE [ID] = @VisitNoteID
		AND Deleted = 0
	END

	--Send CAM a copy of the note &
	--Email the customer if escalated &
	--Email and internal address specified in Configuration table

    -- commented out to disable VRS emails -tp-50
	-- EXEC GenerateAndSendVRSEmail @VisitNoteID, 1, 1, 0, 1

END
ELSE
BEGIN 
	--Resend date now worked out in GenerateAndSendVRSEmail above.
	--Resend e-mail date worked out here.
	SELECT @FurtherActionID = FurtherActionID
	FROM VisitRecords
	WHERE [ID] = @VisitNoteID
	AND Deleted = 0

	IF @FurtherActionID IN (2, 3)
	BEGIN
		SELECT @EDISID = EDISID
		FROM VisitRecords
		WHERE [ID] = @VisitNoteID
		AND Deleted = 0

		SELECT @Days = CAST(Value AS INTEGER)
		FROM SiteProperties
		JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
		WHERE Properties.[Name] = 'Visit Record Email Days Reminder'
		AND EDISID = @EDISID

		IF @Days IS NULL
		BEGIN
			SELECT @Days = CAST(PropertyValue AS INTEGER)
			FROM Configuration
			WHERE PropertyName = 'Visit Record Email Days Reminder'
		
		END

		IF @Days IS NOT NULL
		BEGIN
			SET @ResendEmailOn = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, DATEADD(day, @Days, GETDATE())))) 
		
			UPDATE VisitRecords
			SET ResendEmailOn = @ResendEmailOn
			WHERE [ID] = @VisitNoteID
			AND Deleted = 0
			
		END
		
	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[VRSRecordVerify] TO PUBLIC
    AS [dbo];

