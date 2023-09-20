CREATE PROCEDURE GetTamperCaseEventsSeverityDescriptionByID
	@ID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Description
	FROM [dbo].TamperCaseEventsSeverityDescriptions
	WHERE ID = @ID

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventsSeverityDescriptionByID] TO PUBLIC
    AS [dbo];

