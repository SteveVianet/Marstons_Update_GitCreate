CREATE PROCEDURE DeleteSiteComment
(
	@ID		INT,
	@Undelete	BIT = 0
)

AS

/*
UPDATE dbo.SiteComments
SET Deleted = ~ @Undelete
WHERE [ID] = @ID
*/

DECLARE @EDISID		INTEGER
DECLARE @Type		INTEGER
DECLARE @Text		VARCHAR(1024)
DECLARE @HeadingType	INTEGER
DECLARE @Date		DATETIME
DECLARE @GlobalEDISID	INTEGER
DECLARE @AddedOn		DATETIME

SELECT @EDISID = @EDISID,
	 @Type = Type,
	 @Date = [Date],
	 @HeadingType = HeadingType,
	 @Text = [Text],
	 @AddedOn = AddedOn
FROM SiteComments
WHERE [ID] = @ID

/*
SELECT @GlobalEDISID = Sites.GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.DeleteGlobalSiteComment @GlobalEDISID, @Type, @Date, @HeadingType, @Text, @AddedOn
END
*/

DELETE
FROM SiteComments
WHERE [ID] = @ID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteComment] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteComment] TO [TeamLeader]
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteComment] TO [VRS]
    AS [dbo];

