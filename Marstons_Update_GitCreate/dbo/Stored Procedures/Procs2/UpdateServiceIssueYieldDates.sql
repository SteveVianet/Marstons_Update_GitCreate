
CREATE PROCEDURE [dbo].[UpdateServiceIssueYieldDates]
(
	@ID			INT,
	@DateFrom	DATETIME,
	@DateTo		DATETIME = NULL
)
AS

UPDATE dbo.ServiceIssuesYield
SET DateFrom = @DateFrom,
	DateTo = @DateTo
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateServiceIssueYieldDates] TO PUBLIC
    AS [dbo];

