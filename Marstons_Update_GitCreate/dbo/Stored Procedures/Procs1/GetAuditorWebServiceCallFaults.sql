CREATE PROCEDURE [dbo].[GetAuditorWebServiceCallFaults]

	@CallID INT
	
AS
BEGIN

	SET NOCOUNT ON;
	
	CREATE TABLE #FaultDescriptions ([ID] INT,  FaultDescription VARCHAR(255))

	CREATE TABLE  #CallFaults (FaultTypeID INT,
							   AdditionalInfo VARCHAR(255),
							   FaultDescription VARCHAR(255) NULL)

	DECLARE @UseBillingItems BIT
	SELECT @UseBillingItems = UseBillingItems
	FROM Calls
	WHERE ID = @CallID

	IF @UseBillingItems = 0
	BEGIN

		INSERT INTO #FaultDescriptions([ID], FaultDescription)
		EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetCallFaults]
								   
		INSERT INTO #CallFaults(FaultTypeID, AdditionalInfo, FaultDescription)						    
		SELECT	CallFaults.FaultTypeID, 
				AdditionalInfo,
				Descriptions.FaultDescription AS FaultDescription
		FROM CallFaults
		JOIN #FaultDescriptions AS Descriptions ON Descriptions.[ID] = FaultTypeID
		WHERE CallID = @CallID 

	END
	ELSE
	BEGIN

		INSERT INTO #CallFaults(FaultTypeID, AdditionalInfo, FaultDescription)						    
		SELECT	CallReasons.ReasonTypeID, 
				AdditionalInfo,
				CallReasonTypes.Description AS FaultDescription
		FROM CallReasons
		JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes ON CallReasonTypes.ID = CallReasons.ReasonTypeID
		WHERE CallID = @CallID 

	END

	SELECT FaultTypeID,
		   AdditionalInfo,
		   FaultDescription 
	 FROM #CallFaults

	DROP TABLE #CallFaults
	DROP TABLE #FaultDescriptions
END
