CREATE PROCEDURE [dbo].[ImportJobWatchCall]
(
	@EdisID INT,
	@CallID INT,
	@JobId INT,
	@JobReference NVARCHAR(40),
	@JobType NVARCHAR(100),
	@JobActive BIT,
	@PreRelease BIT,
	@AwaitPO BIT,
	@Invalid BIT,
	@Posted BIT,
	@PostResults NVARCHAR(200)
)
AS

INSERT INTO [dbo].[JobWatchCalls]
           ([EdisID]
           ,[CallID]
           ,[JobId]
           ,[JobReference]
           ,[JobType]
           ,[OriginalJobDescription]
           ,[CurrentJobDescription]
           ,[EngineerName]
           ,[ResourceName]
           ,[JobActive]
           ,[PreRelease]
           ,[AwaitPO]
           ,[Invalid]
           ,[Posted]
           ,[PostResults])
     VALUES
           (@EdisID
           ,@CallID
           ,@JobId
           ,@JobReference
           ,@JobType
           ,''
           ,NULL
           ,''
           ,NULL
           ,@JobActive
           ,@PreRelease
           ,@AwaitPO
           ,@Invalid
           ,@Posted
           ,@PostResults)


IF @JobType = 'Tech Refresh GW3'
BEGIN
    INSERT INTO [dbo].[JobWatchCallsData] ([CallReasonTypeID], [JobId])
    VALUEs (80, @JobId)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ImportJobWatchCall] TO PUBLIC
    AS [dbo];

