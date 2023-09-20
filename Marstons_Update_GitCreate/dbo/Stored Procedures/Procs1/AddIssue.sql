
/****** Object:  StoredProcedure [dbo].[AddIssue]           Script Date: 07/14/2010 16:25:18 ******/
CREATE PROCEDURE [dbo].[AddIssue]
(
	@EDISID		INT,
	@IssueText	VARCHAR(255),
	@CategoryID	INT	= 1,
	@NewID		INT	OUTPUT,
	@Viewed		BIT = NULL,
	@ViewedOn	SMALLDATETIME = NULL,
	@ViewedBy	VARCHAR(255) = NULL,
	@Deleted		BIT = NULL,
	@DeletedOn	SMALLDATETIME = NULL,
	@DeletedBy	VARCHAR(255) = NULL,
	@SubmittedOn	SMALLDATETIME = NULL,
	@SubmittedBy	VARCHAR(255) = NULL
	
)

AS

IF (@SubmittedBy IS NOT NULL) AND (@SubmittedOn IS NOT NULL) AND (@Viewed IS NOT NULL) AND (@Deleted IS NOT NULL)
BEGIN
	--Full Issue added (from database transfer)
	INSERT INTO Issues(EDISID, IssueText, CategoryID, Viewed, ViewedOn, ViewedBy, Deleted, DeletedOn, DeletedBy, SubmittedOn, SubmittedBy)
	VALUES (@EDISID, @IssueText, @CategoryID, @Viewed, @ViewedOn, @ViewedBy, @Deleted, @DeletedOn, @DeletedBy, @SubmittedOn, @SubmittedBy)

	SET @NewID = @@IDENTITY
END
ELSE
BEGIN
	--Basic Issue added
	INSERT INTO Issues(EDISID, IssueText, CategoryID)
	VALUES (@EDISID, @IssueText, @CategoryID)

	SET @NewID = @@IDENTITY
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddIssue] TO PUBLIC
    AS [dbo];

