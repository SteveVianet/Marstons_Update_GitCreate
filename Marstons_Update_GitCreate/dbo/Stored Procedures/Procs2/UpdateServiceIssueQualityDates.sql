CREATE PROCEDURE [dbo].[UpdateServiceIssueQualityDates]
(
	@ID			INT,
	@DateFrom	DATETIME,
	@DateTo		DATETIME = NULL
)
AS

SET NOCOUNT ON

UPDATE dbo.ServiceIssuesQuality
SET DateFrom = @DateFrom,
	DateTo = @DateTo
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateServiceIssueQualityDates] TO PUBLIC
    AS [dbo];

