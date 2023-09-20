
CREATE PROCEDURE [dbo].[GetCleaningSystems] 
AS

SELECT	ID,
		[Description],
		CleanDaysBeforeAmber,
		CleanDaysBeforeRed
FROM dbo.CleaningSystems

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCleaningSystems] TO PUBLIC
    AS [dbo];

