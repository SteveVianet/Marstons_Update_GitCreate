CREATE PROCEDURE [dbo].[AddDownloadRequests]
(
	@Priority	INT
)
AS

-- This adds the entire customer sites into the queue (only used during manual admin - not by SiteLib/Auditor etc.)

SET NOCOUNT ON

DECLARE @DatabaseID INT
DECLARE @SubmittedOn DATETIME

SELECT @DatabaseID = CAST((SELECT PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID') AS INT)

SELECT @SubmittedOn = GETDATE()

INSERT INTO [EDISSQL1\SQL1].DownloadService.dbo.DownloadRequests
(SubmittedBy,SubmittedOn,DatabaseID,EDISID,Priority,StartAt,Attempts,IsBeingProcessed) (
	SELECT SUSER_SNAME(), GETDATE(), @DatabaseID , EDISID, @Priority, @SubmittedOn,0,0
	FROM Sites
	WHERE LastDownload < CAST(CONVERT(VARCHAR(10), DATEADD(d, -1, GETDATE()), 120) AS DATETIME)
		AND Hidden = 0
		AND SystemTypeID IN (1,2,3,5)
		
)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDownloadRequests] TO PUBLIC
    AS [dbo];

