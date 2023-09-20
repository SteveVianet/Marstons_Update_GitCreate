

CREATE PROCEDURE [dbo].[UpdateServiceIssueEquipmentDates]
(
	@ID			INT,
	@DateFrom	DATETIME,
	@DateTo		DATETIME = NULL
)
AS

UPDATE dbo.ServiceIssuesEquipment
SET DateFrom = @DateFrom,
	DateTo = @DateTo
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateServiceIssueEquipmentDates] TO PUBLIC
    AS [dbo];

