CREATE PROCEDURE [dbo].DeleteDistributor
(
	@ID	INT
)

AS

DELETE FROM ProductDistributors 
where ID = @ID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDistributor] TO PUBLIC
    AS [dbo];

