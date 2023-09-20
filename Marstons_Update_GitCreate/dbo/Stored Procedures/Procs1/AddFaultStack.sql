CREATE PROCEDURE [dbo].[AddFaultStack]
(
	@EDISID		INT,
	@Date		DATETIME,
	@Description	VARCHAR(255),
	@Time		DATETIME
)

AS

SET NOCOUNT ON

DECLARE @FaultID	INT
DECLARE @Existing	INT

SELECT @FaultID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

IF @FaultID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @FaultID = @@IDENTITY
END

SELECT @Existing = COUNT(*)
FROM dbo.FaultStack
WHERE [FaultID] = @FaultID AND [Description] = @Description AND [Time] = @Time

IF @Existing = 0
BEGIN
	SET NOCOUNT OFF

	INSERT INTO dbo.FaultStack
	(FaultID, [Description], [Time])
	VALUES
	(@FaultID, @Description, @Time)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddFaultStack] TO PUBLIC
    AS [dbo];

