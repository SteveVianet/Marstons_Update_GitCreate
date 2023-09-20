CREATE PROCEDURE [dbo].[UpdateSiteSystemType]
(
	@EDISID		    INT,
	@SystemTypeID	INT
)

AS

SET NOCOUNT ON

DECLARE @CurrentSystemTypeID INT
DECLARE @Now DATETIME = GETDATE()

SELECT @CurrentSystemTypeID = SystemTypeID
FROM dbo.Sites
WHERE EDISID = @EDISID

IF @CurrentSystemTypeID <> @SystemTypeID
BEGIN
    DECLARE @CurrentSystemTypeDescription VARCHAR(255)
    DECLARE @NewSystemTypeDescription VARCHAR(255)

    SELECT @CurrentSystemTypeDescription = [Description] 
    FROM dbo.SystemTypes 
    WHERE ID = @CurrentSystemTypeID

    SELECT @NewSystemTypeDescription = [Description] 
    FROM dbo.SystemTypes 
    WHERE ID = @SystemTypeID

    DECLARE @Comment VARCHAR(2000) = 'System type changed from [' + @CurrentSystemTypeDescription + '] to [' + @NewSystemTypeDescription + ']'

    EXEC AddSiteComment @EDISID, 7, @Now, 2022, @Comment, NULL, NULL

    UPDATE dbo.Sites
    SET SystemTypeID = @SystemTypeID
    WHERE EDISID = @EDISID

    /* Update AuditSites */
    DECLARE @DatabaseID INT

    SELECT @DatabaseID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

    EXEC [SQL1\SQL1].[Auditing].dbo.UpdateSiteSystemType @DatabaseID, @EDISID, @SystemTypeID
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteSystemType] TO [fusion]
    AS [dbo];

