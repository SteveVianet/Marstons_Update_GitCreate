
CREATE PROCEDURE [dbo].[GetTamperCaseEventTypeIDs]
(
	@CaseID	INTEGER,
	@RefID		INTEGER
)
AS
BEGIN

	SELECT
		TamperCaseEventTypeList.RefID AS 'RefID',
		TamperCaseEventTypeList.TypeID AS 'TypeID'
	FROM	
		dbo.TamperCaseEvents
	  JOIN	dbo.TamperCaseEventTypeList ON dbo.TamperCaseEvents.TypeListID = dbo.TamperCaseEventTypeList.RefID
	WHERE
		dbo.TamperCaseEvents.CaseID=@CaseID
	  AND	dbo.TamperCaseEventTypeList.RefID=@RefID
	ORDER BY
		dbo.TamperCaseEventTypeList.RefID
	
	END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventTypeIDs] TO PUBLIC
    AS [dbo];

