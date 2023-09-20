CREATE PROCEDURE [dbo].[UpdateJobWatchCall]
(
    @Id				INT = NULL, -- If provided, JobId is updated. otherwise JobID is used as a Reference
    @JobId          INT = NULL,
    @JobReference   NVARCHAR(40) = NULL,
    @JobType        NVARCHAR(100) = NULL,
    @CurrentJobDescription  NVARCHAR(500) = NULL,
    @ResourceName   NVARCHAR(100) = NULL,
    @StatusId       INT = NULL,
    @StatusName     NVARCHAR(100) = NULL,
    @StatusLastChanged      DATETIME = NULL,
    @JobActive      BIT = NULL,
    @Posted         BIT = NULL,
    @PostResults    NVARCHAR(200) = NULL,
    @Invalid        BIT = NULL
)
AS

IF @Id IS NULL
BEGIN
    UPDATE [dbo].[JobWatchCalls] 
    SET 
        [JobReference] = ISNULL(@JobReference, [JobReference]),
        [JobType] = ISNULL(@JobType, [JobType]),
        [CurrentJobDescription] = ISNULL(@CurrentJobDescription, [CurrentJobDescription]),
        [ResourceName] = ISNULL(@ResourceName, [ResourceName]),
        [StatusId] = ISNULL(@StatusId, [StatusId]),
        [StatusName] = ISNULL(@StatusName, [StatusName]),
        [StatusLastChanged] = ISNULL(@StatusLastChanged, [StatusLastChanged]),
        [JobActive] = ISNULL(@JobActive, [JobActive]),
        [Posted] = ISNULL(@Posted, [Posted]),
        [PostResults] = ISNULL(@PostResults, [PostResults]),
        [Invalid] = ISNULL(@Invalid, [Invalid])
    WHERE 
        [JobId] = @JobId

    IF @StatusId IN (12,13) -- Completed, Completed (with Issues)
    BEGIN
        /* Check if we need to touch the Installation Date */
        IF EXISTS (SELECT TOP 1 1 FROM [dbo].[JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] IN (1,19,80)) -- Installation (new system), Replace panel only, Tech Refresh GW3
        BEGIN
            -- Installation (new system) or Replace panel only
            DECLARE @EdisID INT
            DECLARE @Completed DATE
            SELECT
                @EdisID = [EdisID],
                @Completed = [StatusLastChanged]
            FROM [dbo].[JobWatchCalls]
            WHERE 
                [JobId] = @JobId

            IF @EdisID IS NOT NULL
            BEGIN
                EXEC [dbo].[UpdateSiteInstallationDate] @EdisID, @Completed
            END
        END
    END

END
ELSE
BEGIN
    UPDATE [dbo].[JobWatchCalls] 
    SET 
        [JobId] = ISNULL(@JobId, [JobId]),
        [JobReference] = ISNULL(@JobReference, [JobReference]),
        [JobType] = ISNULL(@JobType, [JobType]),
        [CurrentJobDescription] = ISNULL(@CurrentJobDescription, [CurrentJobDescription]),
        [ResourceName] = ISNULL(@ResourceName, [ResourceName]),
        [StatusId] = ISNULL(@StatusId, [StatusId]),
        [StatusName] = ISNULL(@StatusName, [StatusName]),
        [StatusLastChanged] = ISNULL(@StatusLastChanged, [StatusLastChanged]),
        [JobActive] = ISNULL(@JobActive, [JobActive]),
        [Posted] = ISNULL(@Posted, [Posted]),
        [PostResults] = ISNULL(@PostResults, [PostResults]),
        [Invalid] = ISNULL(@Invalid, [Invalid])
    WHERE 
        [ID] = @Id
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateJobWatchCall] TO PUBLIC
    AS [dbo];

