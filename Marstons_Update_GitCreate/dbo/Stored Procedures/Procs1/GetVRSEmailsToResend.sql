CREATE PROCEDURE [dbo].[GetVRSEmailsToResend] 
AS

SET NOCOUNT ON

DECLARE @VisitsToAction TABLE(VisitID INT NOT NULL)
DECLARE @EscalateToUserType INT


INSERT INTO @VisitsToAction
SELECT [ID]
FROM VisitRecords
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
WHERE CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, ResendEmailOn))) =  CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, GETDATE())))
AND CompletedDate IS NULL
AND CustomerID = 0
AND Deleted = 0
AND SiteClosed = 0

INSERT INTO @VisitsToAction
SELECT [ID]
FROM VisitRecords
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
WHERE CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, ResendEmailOn))) =  CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, GETDATE())))
AND BDMCommentDate IS NULL
AND CustomerID > 0
AND Deleted = 0
AND SiteClosed = 0

DECLARE curVisitsToAction CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT VisitID
FROM @VisitsToAction


DECLARE @VisitID INT
OPEN curVisitsToAction
FETCH NEXT FROM curVisitsToAction INTO @VisitID

WHILE @@FETCH_STATUS = 0
BEGIN
	--Check to see if the note needs to be escalated and to which user type: BDM or RM.
	SET @EscalateToUserType = dbo.fnGetEscalationRecipientType(@VisitID)
	IF @EscalateToUserType > 0
	BEGIN
		EXEC dbo.GenerateAndSendVRSEmail @VisitID, 1
		
	END

	FETCH NEXT FROM curVisitsToAction INTO @VisitID
	
END

CLOSE curVisitsToAction
DEALLOCATE curVisitsToAction

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVRSEmailsToResend] TO PUBLIC
    AS [dbo];

