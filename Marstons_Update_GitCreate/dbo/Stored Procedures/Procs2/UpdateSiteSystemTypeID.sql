
CREATE PROCEDURE [dbo].[UpdateSiteSystemTypeID]
(
	@EDISID		INT,
	@SystemTypeID	INT,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS

SET NOCOUNT ON

UPDATE dbo.Sites
SET SystemTypeID = @SystemTypeID
WHERE EDISID = @EDISID

/* Update AuditSites */
DECLARE @DatabaseID INT

SELECT @DatabaseID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

EXEC [SQL1\SQL1].[Auditing].dbo.UpdateSiteSystemType @DatabaseID, @EDISID, @SystemTypeID

/* -END- */

SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)

RETURN 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteSystemTypeID] TO PUBLIC
    AS [dbo];

