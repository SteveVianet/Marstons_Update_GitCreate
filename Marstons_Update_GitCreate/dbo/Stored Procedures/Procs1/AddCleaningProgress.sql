CREATE PROCEDURE [dbo].[AddCleaningProgress] 
(
	@EDISID	INTEGER,
	@Pump		INTEGER,
	@Date		DATETIME,
	@AuditorName VARCHAR(100) = NULL
)
AS


DECLARE @Auditor VARCHAR(100)

IF @AuditorName IS NULL
	BEGIN 
		SET @Auditor = SUSER_SNAME()
	END
ELSE
	BEGIN	
		SET @Auditor = @AuditorName
	END

INSERT INTO dbo.CleaningProgress
(EDISID, Pump, [Date], CleanedBy, CleanedOn)
VALUES
(@EDISID, @Pump, @Date, @Auditor, GETDATE())

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCleaningProgress] TO PUBLIC
    AS [dbo];

