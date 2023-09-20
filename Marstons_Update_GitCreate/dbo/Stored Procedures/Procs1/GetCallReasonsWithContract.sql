CREATE PROCEDURE [dbo].[GetCallReasonsWithContract]
(
	@CallID		INT
)

AS

SELECT	[CR].[ID],
		[CR].[ReasonTypeID],
		[CR].[AdditionalInfo],
        [C].[ContractID]
FROM [dbo].[CallReasons] AS [CR]
JOIN [dbo].[Calls] AS [C] ON [CR].[CallID] = [C].[ID]
WHERE [CR].[CallID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallReasonsWithContract] TO PUBLIC
    AS [dbo];

