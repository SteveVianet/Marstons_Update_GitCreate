CREATE PROCEDURE GetTamperCaseEventsSeverityDescriptions	
AS
BEGIN
    SELECT ID, Description
    FROM [dbo].TamperCaseEventsSeverityDescriptions

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventsSeverityDescriptions] TO PUBLIC
    AS [dbo];

