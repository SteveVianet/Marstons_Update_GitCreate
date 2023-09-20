CREATE PROCEDURE dbo.GetSiteLoggerStatus
(
	@EDISID		INTEGER,
	@Description		VARCHAR(100) OUTPUT
)
AS

SET NOCOUNT ON

DECLARE @InstallationDescription 	VARCHAR(100)
DECLARE @CallType 			VARCHAR(100)
DECLARE @CallDescription 		VARCHAR(100)
DECLARE @Hidden			BIT
DECLARE @CallTypeID			INT

CREATE TABLE #CallStatuses ([ID] INT NOT NULL, [Description] VARCHAR(255) NOT NULL, Colour INT NOT NULL, BypassPreRelease BIT NOT NULL, Hidden BIT NOT NULL)

INSERT INTO #CallStatuses
EXEC GetCallStatuses

SELECT @Hidden = Hidden
FROM Sites
WHERE EDISID = @EDISID

SET @CallDescription = ''

IF @Hidden = 0
BEGIN
	SET @CallTypeID = 1
	SET @InstallationDescription = 'Installed'
	SET @CallType = 'Call'

END
ELSE
BEGIN
	SET @CallTypeID = 2
	SET @InstallationDescription = 'Non-Installed'
	SET @CallType = 'Install'

END

SELECT @CallDescription = CallStatuses.[Description]
FROM Calls
JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]
JOIN #CallStatuses AS CallStatuses ON CallStatuses.[ID] = CallStatusHistory.StatusID
WHERE Calls.EDISID = @EDISID
AND ClosedOn IS NULL
AND InvoicedOn IS NULL
AND AbortReasonID = 0
AND CallTypeID = @CallTypeID
ORDER BY RaisedOn DESC

IF LEN(@CallDescription) = 0
BEGIN
	SET @Description = @InstallationDescription
END
ELSE
BEGIN
	SET @Description = @InstallationDescription + ' (' + @CallType + ' Status: ' + @CallDescription + ')'
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLoggerStatus] TO PUBLIC
    AS [dbo];

