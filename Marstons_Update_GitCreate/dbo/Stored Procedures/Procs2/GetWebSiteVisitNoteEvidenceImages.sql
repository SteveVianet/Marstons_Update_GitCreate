CREATE PROCEDURE [dbo].[GetWebSiteVisitNoteEvidenceImages]
(
	@EDISID		INT,
	@VisitDate		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @SiteCode		VARCHAR(10)
DECLARE @VisitRange		DATETIME
DECLARE @DatabaseName	VARCHAR(256)

SET @SiteCode = CAST(@EDISID AS VARCHAR(10))
SET @VisitRange = DATEADD(day, 1, @VisitDate)
SET @DatabaseName = DB_NAME()

EXEC [EDISSQL1\SQL1].DocumentArchive.dbo.GetDocuments @SiteCode, @DatabaseName, NULL, @VisitDate, @VisitRange, 7, 25, NULL
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteVisitNoteEvidenceImages] TO PUBLIC
    AS [dbo];

