
/****** Object:  StoredProcedure [dbo].[GetIssues]          Script Date: 07/14/2010 16:25:18 ******/
CREATE PROCEDURE [dbo].[GetIssues]
(
	@EDISID INT = NULL,
	@ShowDeleted BIT = 0
)
AS

SELECT [ID],
	EDISID,
	IssueText,
	CategoryID,
	SubmittedOn,
	SubmittedBy,
	Viewed,
	ViewedOn,
	ViewedBy,
	Deleted,
	DeletedOn,
	DeletedBy
FROM dbo.Issues
WHERE ( (Deleted = 0) OR (@ShowDeleted = 1) )
  AND ( (EDISID = @EDISID) OR (@EDISID IS NULL) )
ORDER BY SubmittedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetIssues] TO PUBLIC
    AS [dbo];

