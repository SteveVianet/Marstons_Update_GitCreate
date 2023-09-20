CREATE PROCEDURE GetSystemType 
	-- Add the parameters for the stored procedure here
	@systemTypeId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT	
		[ID],
		[Description],
		DispenseByMinute
	FROM SystemTypes
	WHERE ID = @systemTypeId
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemType] TO PUBLIC
    AS [dbo];

