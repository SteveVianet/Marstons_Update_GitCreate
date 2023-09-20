
CREATE PROCEDURE [dbo].[UpdateSiteStatus]
(      @EDISID              INTEGER,
       @Status              INTEGER,
       @UpdateID     ROWVERSION = NULL    OUTPUT
)

AS

SET XACT_ABORT ON

BEGIN TRAN

SET NOCOUNT ON

DECLARE @GlobalEDISID      INTEGER
DECLARE @GlobalOwnerID     INTEGER

-- If EDISID exists and UpdateID matches
IF     (SELECT COUNT(*)
       FROM dbo.Sites 
       WHERE EDISID = @EDISID 
       AND UpdateID = @UpdateID) > 0 
     OR @UpdateID IS NULL
BEGIN
       UPDATE dbo.Sites
       SET 
              [Status] = @Status,
              [SiteClosed] = CASE WHEN @Status IN (2, 0) THEN 1 ELSE 0 END,
              [Hidden] = CASE WHEN @Status IN (4, 5, 6, 7, 9, 11, 0) THEN 1 ELSE 0 END,
              SystemTypeID = CASE WHEN @Status = 9 THEN 9 ELSE SystemTypeID END,
              CommunicationProviderID = CASE WHEN @Status = 9 THEN 1 ELSE CommunicationProviderID END,
              InstallationDate = CASE WHEN @Status = 9 THEN NULL ELSE InstallationDate END      
       WHERE EDISID = @EDISID

       SET @UpdateID = @@DBTS
       
       UPDATE dbo.SiteStatusHistory
       SET ValidTo = GETDATE()
       WHERE EDISID = @EDISID
       AND ValidTo IS NULL
       
       INSERT INTO dbo.SiteStatusHistory
       (EDISID, StatusID, ValidFrom, ValidTo, [User])
       VALUES
       (@EDISID, @Status, GETDATE(), NULL, SUSER_NAME())

       COMMIT
       RETURN 0

END
ELSE
BEGIN
       COMMIT
       RETURN -1

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteStatus] TO PUBLIC
    AS [dbo];

