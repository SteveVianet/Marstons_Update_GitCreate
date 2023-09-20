CREATE PROCEDURE [dbo].[AddContractChangeLog]
(
	@ItemType		VARCHAR(100),
	@ContractID		INT,
	@Description	VARCHAR(8000)
)
AS

INSERT INTO dbo.ContractChangeLog
(ItemType, ChangeDate, [User], ContractID, [Description])
VALUES
(@ItemType, CURRENT_TIMESTAMP, SUSER_NAME(), @ContractID, @Description)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContractChangeLog] TO PUBLIC
    AS [dbo];

