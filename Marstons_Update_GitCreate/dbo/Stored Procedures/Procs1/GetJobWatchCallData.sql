CREATE PROCEDURE [dbo].[GetJobWatchCallData]
(
	@EdisID INT,
	@OnlyActive BIT = 1
)
AS

SELECT 
	[JobWatchCalls].[CallID],
	[JobWatchCalls].[JobReference],
	[JobWatchCalls].[JobActive],
	[JobWatchCalls].[CurrentJobDescription],
	[JobWatchCalls].[StatusName],
	[JobWatchCalls].[StatusLastChanged],
	[JobWatchCalls].[PreRelease],
	[JobWatchCalls].[AwaitPO],
	[JobWatchCallsData].[CallReasonTypeID],
	[JobWatchCallsData].[EquipmentAddress],
	[JobWatchCallsData].[IFMAddress],
	[JobWatchCallsData].[Pump],
	[JobWatchCallsData].[ProductID]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
WHERE
	[JobWatchCalls].[JobActive] = @OnlyActive
AND [JobWatchCalls].[EdisID] = @EdisID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetJobWatchCallData] TO PUBLIC
    AS [dbo];

