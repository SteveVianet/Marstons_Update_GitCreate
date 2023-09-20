CREATE PROCEDURE [dbo].[UpdateCallInvoicing]
(
	@CallID					INT,
	@EngineerID				INT = NULL,
	@OverrideSLA			INT,
	@CallCategoryID			INT,
	@RequestID				INT,
	@ContractID				INT,
	@AuthorisationRequired	BIT,
	@FlagToFinance			BIT,
	@POStatusID				INT,
	@CallTypeID				INT
)
AS

SET NOCOUNT ON

-- Work-around any corrupt/missing Contract data on the Service Call
-- One last ditch attempt to get a valid Contract
IF @ContractID IS NULL OR @ContractID = 0
BEGIN
    SELECT 
        @ContractID = [SiteContracts].[ContractID]
	FROM [dbo].[SiteContracts]
    JOIN [dbo].[Sites] ON [SiteContracts].[EDISID] = [Sites].[EDISID]
    JOIN [dbo].[Calls] ON [Sites].[EDISID] = [Calls].[EDISID]
    JOIN [dbo].[Contracts] ON [Contracts].[ID] = [SiteContracts].[ContractID]
	WHERE [Calls].[ID] = @CallID 
    AND [Contracts].[UseBillingItems] = 1 AND [Calls].[UseBillingItems] = 1
END

UPDATE dbo.Calls
SET	EngineerID = @EngineerID,
	OverrideSLA = @OverrideSLA,
	CallCategoryID = @CallCategoryID,
	RequestID = @RequestID,
	ContractID = @ContractID,
	AuthorisationRequired = @AuthorisationRequired,
	FlagToFinance = @FlagToFinance,
	POStatusID = @POStatusID,
	CallTypeID = @CallTypeID,
	InstallCallID = CASE WHEN @CallCategoryID IN (4, 6, 9) THEN @CallID ELSE NULL END
WHERE ID = @CallID

--EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1
EXEC [dbo].[MoveCallToJobWatch] @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallInvoicing] TO PUBLIC
    AS [dbo];

