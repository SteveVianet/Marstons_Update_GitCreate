CREATE PROCEDURE [dbo].[GetJobWatchCalls]
(
    @Posted BIT = 0,
    @Invalid BIT = 0,
    @Active BIT = NULL
)
AS

/* Testing */
--DECLARE    @Posted BIT = 1
--DECLARE    @Invalid BIT = 0
--DECLARE    @Active BIT = 1

SELECT 
	[ID],
    [EdisID], 
    [Sites].[SiteID],
    [Sites].[Name],
    [Sites].[PostCode],
    [CallID],  
    [JobId], 
    [JobReference], 
    [JobType], 
    [OriginalJobDescription], 
    [CurrentJobDescription],
    [EngineerName],
    [ResourceName],
    [StatusId],
    [StatusName],
    [StatusLastChanged],
    [JobActive],
    [PreRelease],
    [AwaitPO],
    [Invalid],
    [Posted], 
    [PostResults],
    ISNULL([RequestedBy], 'Audit') AS [RequestedBy],
    [CreatedOn]
FROM [dbo].[JobWatchCalls] 
JOIN [dbo].[Sites] ON [JobWatchCalls].[EdisID] = [Sites].[EDISID]
WHERE 
    [Posted] = @Posted
AND [Invalid] = @Invalid
AND (@Active IS NULL OR [JobActive] = @Active)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetJobWatchCalls] TO PUBLIC
    AS [dbo];

