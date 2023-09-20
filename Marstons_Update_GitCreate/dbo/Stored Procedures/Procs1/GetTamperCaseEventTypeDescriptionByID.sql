CREATE PROCEDURE GetTamperCaseEventTypeDescriptionByID
	@MethodID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Description
	FROM [dbo].TamperCaseEventTypeDescriptions
	WHERE ID = @MethodID

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventTypeDescriptionByID] TO PUBLIC
    AS [dbo];

