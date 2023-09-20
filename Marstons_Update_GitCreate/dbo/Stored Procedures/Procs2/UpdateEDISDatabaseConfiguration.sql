

CREATE PROCEDURE [dbo].[UpdateEDISDatabaseConfiguration]
(
	@RetailCashValue		FLOAT = NULL,
	@OperationalCashValue	FLOAT = NULL
)
AS

SELECT 1


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateEDISDatabaseConfiguration] TO PUBLIC
    AS [dbo];

