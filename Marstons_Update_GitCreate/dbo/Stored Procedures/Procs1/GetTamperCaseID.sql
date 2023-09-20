
CREATE PROCEDURE [dbo].[GetTamperCaseID]
(
	@EDISID	INT,
	@CaseID	INT OUT
)
AS 
BEGIN
	DECLARE @StateID integer
	SELECT TOP 1 
		@CaseID = TamperCases.CaseID,
		@StateID = TamperCaseEvents.StateID		
	FROM 
		TamperCases
		JOIN dbo.TamperCaseEvents ON dbo.TamperCases.CaseID = dbo.TamperCaseEvents.CaseID
	WHERE 
		@EDISID = dbo.TamperCases.EDISID
	ORDER BY 
		EventDate 
	DESC

	IF 
		@StateID = 3 OR 
		@StateID = 6 OR
		@StateID IS NULL OR
		@CaseID IS NULL
	BEGIN
		INSERT INTO
			TamperCases(EDISID)
		VALUES
			(@EDISID)

		Set @CaseID = @@IDENTITY		
	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseID] TO PUBLIC
    AS [dbo];

