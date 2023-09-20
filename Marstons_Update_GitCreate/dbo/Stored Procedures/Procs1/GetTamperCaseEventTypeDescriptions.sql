CREATE PROCEDURE GetTamperCaseEventTypeDescriptions	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
        [ID], 
        [Description]
	FROM [dbo].TamperCaseEventTypeDescriptions

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventTypeDescriptions] TO PUBLIC
    AS [dbo];

