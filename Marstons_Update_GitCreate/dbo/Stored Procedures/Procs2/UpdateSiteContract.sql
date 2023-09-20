CREATE PROCEDURE [dbo].[UpdateSiteContract]
(
	@EDISID	INT,
	@ContractID	INT,
	@StartDate	DATETIME = NULL
)

AS

SET NOCOUNT ON

DECLARE @ContractCount INT
DECLARE @CurrentContractID INT
DECLARE @ChangeDescription VARCHAR(8000)
DECLARE @SiteID VARCHAR(50)
DECLARE @Name VARCHAR(100)
DECLARE @OldContractDescription VARCHAR(100)
DECLARE @NewContractDescription VARCHAR(100)

IF @ContractID <= 0
BEGIN
	DELETE FROM dbo.SiteContracts
	WHERE EDISID = @EDISID
	
	RETURN
END

SELECT @ContractCount = COUNT(*)
FROM dbo.SiteContracts
WHERE EDISID = @EDISID

IF @ContractCount > 0
	UPDATE dbo.SiteContracts
	SET ContractID = @ContractID
	WHERE EDISID = @EDISID
ELSE
	INSERT INTO dbo.SiteContracts
	(EDISID, ContractID)
	VALUES
	(@EDISID, @ContractID)

SELECT @CurrentContractID = ContractID
FROM dbo.SiteContractHistory
WHERE EDISID = @EDISID
AND ValidTo IS NULL

IF @StartDate IS NULL
BEGIN
	SET @StartDate = GETDATE()
END

IF @ContractID <> @CurrentContractID
BEGIN
	UPDATE dbo.SiteContractHistory
	SET ValidTo = DATEADD(SECOND, -1, @StartDate)
	WHERE EDISID = @EDISID
	AND ValidTo IS NULL

	INSERT INTO dbo.SiteContractHistory
	(EDISID, ContractID, ValidFrom, ValidTo)
	VALUES
	(@EDISID, @ContractID, @StartDate, NULL)
	
	SELECT @SiteID = SiteID,
		   @Name = Name
	FROM dbo.Sites
	WHERE EDISID = @EDISID
	
	SELECT @OldContractDescription = [Description]
	FROM dbo.Contracts
	WHERE [ID] = @CurrentContractID
	
	SELECT @NewContractDescription = [Description]
	FROM dbo.Contracts
	WHERE [ID] = @ContractID
	
	SET @ChangeDescription = 'Site ' + @SiteID + ': ' + @Name + ' changed from contract ' + @OldContractDescription + ' to ' + @NewContractDescription
	EXEC dbo.AddContractChangeLog 'Site Contract', @ContractID, @ChangeDescription

END
ELSE
BEGIN
	UPDATE dbo.SiteContractHistory
	SET ValidFrom = @StartDate
	WHERE EDISID = @EDISID
	AND ValidTo IS NULL
	
	SELECT @NewContractDescription = [Description]
	FROM dbo.Contracts
	WHERE [ID] = @ContractID
	
	SET @ChangeDescription = 'Site ' + @SiteID + ': ' + @Name + ' start date changed to ' + CAST(@StartDate AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Site Contract', @ContractID, @ChangeDescription

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteContract] TO PUBLIC
    AS [dbo];

