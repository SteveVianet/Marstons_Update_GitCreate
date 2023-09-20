CREATE PROCEDURE [dbo].[GetLastSystemServiceTime]
(
	@EDISID		INTEGER,
	@TIMESTAMP		DATETIME	OUTPUT
)
AS

BEGIN

	EXEC [SQL1\SQL1].ServiceLogger.dbo.GetLastSystemServiceTime @EDISID, @TIMESTAMP OUTPUT

	SET @TIMESTAMP = (
		ISNULL(
			@TIMESTAMP
		, 
			(SELECT
				SiteOnline
			FROM
				Sites
			WHERE
				EDISID=@EDISID)
		)
	)

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLastSystemServiceTime] TO PUBLIC
    AS [dbo];

