--/*
CREATE PROCEDURE [dbo].[AddOrUpdateSiteComment]
(
    @EDISID		    INT,
    @Type		    INT,
    @Date		    DATETIME,
    @HeadingType	INT,
    @Text		    VARCHAR(1024),
    @NewID		    INT OUTPUT,
    @User		    VARCHAR(255) = NULL,
    @Status		    VARCHAR(50) = NULL
)
AS
--*/

/* Only intended for use with Trend/Stock 
    Would need modifying before it could be safely used for other purposes.
*/

/* Debugging */
--DECLARE   @EDISID		INT = 5548
--DECLARE   @Type		    INT = 1 -- Auditor
--DECLARE   @Date		    DATETIME = '2017-04-25 16:23:33'
--DECLARE   @HeadingType	INT = 5002
--DECLARE   @Text		    VARCHAR(1024) = 'Test Comment Content'
--DECLARE   @NewID		INT = NULL
--DECLARE   @User		    VARCHAR(255) = NULL
--DECLARE   @Status		VARCHAR(50) = NULL

SET NOCOUNT ON
SET DATEFIRST 1

/* Debugging */
DECLARE @ReadOnly BIT = 0 -- Set to 0 for Release. 0 = normal operation, 1 = print actions only, no data updates are made
DECLARE @AttemptCleanup BIT = 1 -- Set to 1 for Release. 0 = don't try to remove duplicate comments (no risk of deadlocks), 1 = try to remove duplicate comments and attempt to avoid deadlocking while doing it

DECLARE @CallID INT
DECLARE @ExistingCount INT = 0

DECLARE @WeekStart DATE
DECLARE @WeekEnd DATE
SELECT 
    @WeekStart = [Calendar].[FirstDateOfWeek], 
    @WeekEnd = [Calendar].[LastDateOfWeek] 
FROM [dbo].[Calendar]
WHERE [Calendar].[CalendarDate] = CAST(@Date AS DATE)

IF @Status IS NULL AND @HeadingType = 3004 SET @Status = 'Green';

/* When Updating a comment, only those within the same week are considered. */
BEGIN TRY
    SET DEADLOCK_PRIORITY HIGH -- (5)
    SELECT @ExistingCount = COUNT(*) 
    FROM [dbo].[SiteComments] 
    WHERE 
        [EDISID] = @EDISID 
    AND [Type] = @Type 
    AND [HeadingType] IN (5000,5001,5002,5003,5004) 
    AND [Deleted] = 0
    AND [Date] BETWEEN @WeekStart AND @WeekEnd
    SET DEADLOCK_PRIORITY NORMAL -- (0)
END TRY
BEGIN CATCH
    PRINT 'Find Existing Comment failed'
END CATCH;

IF @ExistingCount > 0
BEGIN
    /* The below delete is probably not needed once the existing corruption has been cleared */
    IF @ExistingCount > 1 AND @AttemptCleanup = 1
    BEGIN TRY
        -- Attempt cleanup to prevent duplicate comments
        -- This is a best-efforts attempt to do so, if it fails we continue anyway.
        DECLARE @ExistingID INT 
        SELECT @ExistingID = MIN([ID]) FROM [dbo].[SiteComments] WHERE [EDISID] = @EDISID AND [Type] = @Type AND [HeadingType] IN (5000,5001,5002,5003,5004) AND [Deleted] = 0

        IF @ExistingID IS NOT NULL
        BEGIN
            DECLARE @LOWEST INT = -10 -- LOW (5), NORMAL (0), HIGH (5), Custom = -10 to 10

            IF @ReadOnly = 0
            BEGIN
               -- Leverage the clustered index to try and avoid deadlocking (very easy to trigger when used in a tight loop generating exceptions).
               -- Also lower the deadlock priority of this session to try and ensure the following DELETE is what fails instead of anything else that may be running.   
               SET DEADLOCK_PRIORITY @LOWEST -- (-10)
               DELETE FROM [dbo].[SiteComments] WHERE [ID] = @ExistingID
               SET DEADLOCK_PRIORITY NORMAL -- (0)
            END
            ELSE
            BEGIN
               PRINT 'SET DEADLOCK_PRIORITY ' + CAST(@LOWEST AS VARCHAR(10)) + '
               DELETE FROM [dbo].[SiteComments] WHERE [ID] = ' + CAST(@ExistingID AS VARCHAR(10)) + '
               SET DEADLOCK_PRIORITY NORMAL' 
            END
        END
    END TRY
    BEGIN CATCH
        PRINT 'Duplicate Comment Cleanup failed'
    END CATCH;

    IF @ReadOnly = 0
    BEGIN
        UPDATE dbo.SiteComments
        SET [Text] = @Text,
            [Date] = @Date,
            [HeadingType] = @HeadingType,
            [RAGStatus] = @Status,
            [EditedBy] = ISNULL(@User, SUSER_SNAME()),
            [EditedOn] = GETDATE()
        WHERE
            [EDISID] = @EDISID 
        AND [Type] = @Type 
        AND [HeadingType] IN (5000,5001,5002,5003,5004)
        AND [Date] BETWEEN @WeekStart AND @WeekEnd 
        AND [Deleted] = 0
    END
    ELSE
    BEGIN
        PRINT 'UPDATE dbo.SiteComments
        SET [Text] = ''' + @Text + ''',
            [Date] = ''' + CAST(@Date AS VARCHAR(32)) + ''',
            [HeadingType] = ' + CAST(@HeadingType AS VARCHAR(10)) + ',
            [RAGStatus] = ''' + @Status + ''',
            [EditedBy] = ''' + ISNULL(@User, SUSER_SNAME()) + ''',
            [EditedOn] = ''' + CAST(GETDATE() AS VARCHAR(32)) + '''
        WHERE
            [EDISID] = ' + CAST(@EDISID AS VARCHAR(10)) + '
        AND [Type] = ' + CAST(@Type AS VARCHAR(10)) + '
        AND [HeadingType] IN (5000,5001,5002,5003,5004) 
        AND [Deleted] = 0'
    END
END
ELSE
BEGIN
    IF @ReadOnly = 0
    BEGIN
        INSERT INTO dbo.SiteComments
        (EDISID, [Type], [Date], HeadingType, [Text], Deleted, AddedBy, EditedBy, RAGStatus)
        VALUES
        (@EDISID, @Type, @Date, @HeadingType, @Text, 0, ISNULL(@User, SUSER_SNAME()), ISNULL(@User, SUSER_SNAME()), @Status)
    END
    ELSE
    BEGIN
        PRINT 'INSERT INTO dbo.SiteComments
        (EDISID, [Type], [Date], HeadingType, [Text], Deleted, AddedBy, EditedBy, RAGStatus)
        VALUES
        (' + CAST(@EDISID AS VARCHAR(10)) + ', ' + CAST(@Type AS VARCHAR(10)) + ', ''' + CAST(@Date AS VARCHAR(32)) + ''', ' + CAST(@HeadingType AS VARCHAR(10)) + ', ''' + @Text + ''', 0, ''' + ISNULL(@User, SUSER_SNAME()) + ''', ''' + ISNULL(@User, SUSER_SNAME()) + ''', ''' + @Status + ''')'
    END
END

SET @NewID = @@IDENTITY

IF @Type = 5
BEGIN
    IF @ReadOnly = 0
    BEGIN
	    SELECT @CallID = MAX(ID) FROM Calls WHERE EDISID = @EDISID
	    EXEC dbo.RefreshHandheldCall @CallID, 0, 0, 1
    END
    ELSE
    BEGIN
        PRINT 'SELECT @CallID = MAX(ID) FROM Calls WHERE EDISID = ' + CAST(@EDISID AS VARCHAR(10)) + '
	    EXEC dbo.RefreshHandheldCall ' + CAST(@CallID AS VARCHAR(10)) + ', 0, 0, 1'
    END
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddOrUpdateSiteComment] TO PUBLIC
    AS [dbo];

