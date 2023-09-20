
CREATE PROCEDURE [dbo].[GetTamperCaseIDs]
(
	@EDISID	INT
)
AS 

SELECT TamperCases.CaseID
FROM TamperCases
WHERE @EDISID = dbo.TamperCases.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseIDs] TO PUBLIC
    AS [dbo];

