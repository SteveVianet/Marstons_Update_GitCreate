CREATE PROCEDURE [dbo].[GetTamperCaseEventTypes]
(
	@CaseID	INTEGER,
	@RefID		INTEGER
)
AS
BEGIN

	SELECT
		tcevent.RefID AS 'RefID',
		tcevent.TypeID AS 'TypeID',
		tcdesc.Description
	FROM	
		dbo.TamperCaseEvents AS tce
	  JOIN	dbo.TamperCaseEventTypeList AS tcevent ON tce.TypeListID = tcevent.RefID
	  JOIN dbo.TamperCaseEventTypeDescriptions AS tcdesc ON tcdesc.ID = tcevent.TypeID
	WHERE
		tce.CaseID=@CaseID
	  AND	tcevent.RefID=@RefID
	ORDER BY
		tcevent.RefID	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventTypes] TO PUBLIC
    AS [dbo];

