CREATE PROCEDURE [dbo].[GetAuditorWebServiceCallHistory]

	@CallID INT
	
AS
BEGIN

	SET NOCOUNT ON;
	
	CREATE TABLE #ServiceHistory	(DateCompleted DATE,
									CallReference VARCHAR(20),
									CallOutReason VARCHAR(8000),
									DaysToComplete INT,
									EngineerComments VARCHAR(1000))
									
	DECLARE @EDISID INT
	SELECT @EDISID = Sites.EDISID
	FROM Calls
	JOIN dbo.Sites ON dbo.Sites.EDISID = dbo.Calls.EDISID
	WHERE Calls.ID = @CallID

	--CREATE TABLE #FaultDescriptions ([ID] INT,  FaultDescription VARCHAR(255))
	--INSERT INTO #FaultDescriptions([ID], FaultDescription)
	--EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetCallFaults]
	

	INSERT INTO #ServiceHistory (DateCompleted, CallReference, CallOutReason, DaysToComplete, EngineerComments)
	SELECT	ClosedOn,
			dbo.GetCallReference(Calls.ID),
			ISNULL(dbo.udfConcatCallFaults(Calls.ID), 'No Comment Recorded') AS CallOutReason,
			--#FaultDescriptions.FaultDescription,
			DATEDIFF(day, RaisedOn, ClosedOn),
			ISNULL(WorkDetailComment, '')
			FROM Calls
			--JOIN CallFaults ON CallFaults.CallID = Calls.ID
			--JOIN #FaultDescriptions ON #FaultDescriptions.ID = CallFaults.FaultTypeID
	WHERE EDISID = @EDISID AND ClosedOn <> '' AND ClosedOn > '2001-01-01'

	SELECT	DateCompleted,
			CallReference,
			CallOutReason,
			DaysToComplete,
			EngineerComments
	FROM #ServiceHistory 
	ORDER BY DateCompleted DESC

	DROP TABLE #ServiceHistory
	--DROP TABLE #FaultDescriptions
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorWebServiceCallHistory] TO PUBLIC
    AS [dbo];

