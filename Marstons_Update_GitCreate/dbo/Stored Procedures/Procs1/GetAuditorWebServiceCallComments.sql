CREATE PROCEDURE [dbo].[GetAuditorWebServiceCallComments] 
	-- Add the parameters for the stored procedure here
	@CallID INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    CREATE TABLE #ServiceCallComments([Date] DATE,
								  CommentBy VARCHAR(255),
								  Comment VARCHAR(1000),
								  CommentTypeDescription VARCHAR(50))

	--Get date the service call was raised
	DECLARE @RaisedDate as DATE
	SELECT @RaisedDate = RaisedOn
	FROM Calls
	WHERE ID = @CallID

	--Get EDISID for the site the call is assigned to
	DECLARE @EDISID INT
	SELECT @EDISID = Sites.EDISID
	FROM Calls
	JOIN dbo.Sites ON dbo.Sites.EDISID = dbo.Calls.EDISID
	WHERE Calls.ID = @CallID


	---- Get Site Audit Comments 
	--INSERT INTO #ServiceCallComments([Date], CommentBy, Comment, CommentTypeDescription)
	--SELECT [Date],
	--	   AddedBy,
	--	   SiteCommentHeadingTypes.Description + ': ' + [Text],
	--	   SiteCommentTypes.[Description]	
	--FROM SiteComments
	--JOIN SiteCommentTypes ON SiteCommentTypes.ID = SiteComments.Type
	--JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.ID = SiteComments.HeadingType
	--WHERE EDISID = @EDISID AND [Date] >= @RaisedDate AND Type = 1


	--Get Work Detail Comments
	INSERT INTO #ServiceCallComments([Date], CommentBy, Comment, CommentTypeDescription)
	SELECT  SubmittedOn,
			WorkDetailCommentBy,
			WorkDetailComment,
			'Engineer Visit'
	FROM CallWorkDetailComments
	WHERE CallID = @CallID

	--Get Call Comments
	INSERT INTO #ServiceCallComments([Date], CommentBy, Comment, CommentTypeDescription)
	SELECT SubmittedOn,
		   CommentBy,
		   Comment,
		   'Planning'
	FROM CallComments
	WHERE CallID = @CallID

	SELECT [Date],
		   CommentBy,
		   Comment,
		   CommentTypeDescription
	FROM #ServiceCallComments ORDER BY [Date] DESC
		
	DROP Table #ServiceCallComments
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorWebServiceCallComments] TO PUBLIC
    AS [dbo];

