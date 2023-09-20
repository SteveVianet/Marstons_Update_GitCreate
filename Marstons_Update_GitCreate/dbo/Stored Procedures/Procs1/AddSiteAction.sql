CREATE PROCEDURE [dbo].[AddSiteAction]
(
	@EDISID		INT,
	@ActionID	INT,
	@User		VARCHAR(255) = NULL,
	@Date		DATETIME = NULL
)

AS

SET NOCOUNT ON

IF (@User IS NOT NULL) OR (@Date IS NOT NULL)
BEGIN
	INSERT INTO SiteActions
		(EDISID, UserName, [TimeStamp], ActionID)
	VALUES
		(@EDISID, @User, @Date, @ActionID)	
END
ELSE
BEGIN
	INSERT INTO SiteActions
		(EDISID, UserName, [TimeStamp], ActionID)
	VALUES
		(@EDISID, SUSER_SNAME(), GETDATE(), @ActionID)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteAction] TO PUBLIC
    AS [dbo];

