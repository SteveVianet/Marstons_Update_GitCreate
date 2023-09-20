CREATE PROCEDURE [dbo].[UpdateSiteLastPATDate]
(
	@EDISID	INT,
	@LastPATDate	DATETIME
)

AS

UPDATE Sites
SET LastPATDate = @LastPATDate
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastPATDate] TO PUBLIC
    AS [dbo];

