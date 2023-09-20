---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddSchedule
(
	@ScheduleName	VARCHAR(255),
	@Public		BIT,
	@NewID		INTEGER	OUTPUT
)

AS

DECLARE @Count INTEGER

-- Check for duplicate schedules
SELECT @Count = COUNT(*)
FROM Schedules
WHERE UPPER([Description]) = UPPER(@ScheduleName)

IF @Count > 0
BEGIN
	RAISERROR ('Schedule name already exists', 16, 1)
	RETURN
END

-- Check for duplicate dynamic schedules
SELECT @Count = COUNT(*)
FROM Schedules
WHERE UPPER(SUBSTRING([Description], CHARINDEX(':', [Description]) + 1, LEN([Description]))) = UPPER(@ScheduleName)
AND CHARINDEX(':', [Description]) > 0

IF @Count > 0
BEGIN
	RAISERROR ('Schedule name already exists (dynamic)', 16, 1)
	RETURN
END

-- Create the new schedule
INSERT INTO dbo.Schedules
([Description], [Public])
VALUES
(@ScheduleName, @Public)

-- Return the new schedule ID
SET @NewID = @@IDENTITY
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSchedule] TO PUBLIC
    AS [dbo];

