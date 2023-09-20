CREATE PROCEDURE [dbo].[AddTamperCaseID]
(
	@EDISID	INT,
	@CaseID INT OUTPUT
)
AS 

INSERT INTO	TamperCases
	(EDISID)
VALUES 
	(@EDISID)

Set @CaseID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddTamperCaseID] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddTamperCaseID] TO [fusion]
    AS [dbo];

