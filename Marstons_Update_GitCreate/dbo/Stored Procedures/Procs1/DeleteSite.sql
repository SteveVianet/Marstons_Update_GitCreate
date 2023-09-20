CREATE PROCEDURE [dbo].[DeleteSite]
(
	@EDISID		INTEGER
)

AS


DECLARE @EDISTelNo as VARCHAR(512)

SELECT @EDISTelNo = Sites.EDISTelNo
FROM dbo.Sites
WHERE EDISID = @EDISID 
				 

DECLARE @Text AS VARCHAR(255)
SET @Text = 'EDIS telephone number changed from [' + @EDISTelNo + '] to [] as part of site delete'

DECLARE @Date AS DATETIME
SET @Date = GETDATE()

-- add record of deleted edis telephone number
EXEC dbo.AddNumberChangeRecord @EDISID, @Date, @Text, @Date  

-- hide site/clear details
UPDATE Sites
SET EDISTelNo = '',
	SiteUser = ''
WHERE EDISID = @EDISID

-- remove site from any schedules
DELETE FROM ScheduleSites
WHERE EDISID = @EDISID

-- remove site from users
DELETE FROM UserSites
WHERE EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSite] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSite] TO [SiteDestroyer]
    AS [dbo];

