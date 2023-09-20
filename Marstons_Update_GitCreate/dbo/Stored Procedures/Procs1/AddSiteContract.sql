CREATE PROCEDURE [dbo].[AddSiteContract]
(
	@ContractID	INT,
	@EDISID	INT
)
AS

SET NOCOUNT ON

DECLARE @StartDate	DATETIME
DECLARE @CurrentContractID INT
DECLARE @ChangeDescription VARCHAR(8000)
DECLARE @SiteID VARCHAR(50)
DECLARE @Name VARCHAR(100)
DECLARE @OldContractDescription VARCHAR(100)
DECLARE @NewContractDescription VARCHAR(100)

DELETE FROM dbo.SiteContracts
WHERE EDISID = @EDISID

INSERT INTO dbo.SiteContracts
(ContractID, EDISID)
VALUES
(@ContractID, @EDISID)

SELECT @CurrentContractID = ContractID
FROM dbo.SiteContractHistory
WHERE EDISID = @EDISID
AND ValidTo IS NULL

SET @StartDate = GETDATE()

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
    ON OBJECT::[dbo].[AddSiteContract] TO PUBLIC
    AS [dbo];

