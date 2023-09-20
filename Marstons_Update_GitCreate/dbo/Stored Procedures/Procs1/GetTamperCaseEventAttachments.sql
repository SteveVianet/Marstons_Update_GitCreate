
CREATE PROCEDURE [dbo].[GetTamperCaseEventAttachments]
(
	@AttachmentID	INTEGER
)
AS
BEGIN

	SELECT
		TamperCaseAttachments.AttachmentID AS 'AttachmentID',
		TamperCaseAttachments.AttachmentName AS 'FileName'
	FROM	
		dbo.TamperCaseAttachments
	WHERE
	  	dbo.TamperCaseAttachments.AttachmentID=@AttachmentID
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEventAttachments] TO PUBLIC
    AS [dbo];

