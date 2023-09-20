CREATE PROCEDURE [dbo].[DeletePubcoPeriod]
(
	@DatabaseID		INT,
	@PeriodName		VARCHAR(10)
)
AS

SET NOCOUNT ON


delete from 
dbo.PubcoCalendars
where DatabaseID = @DatabaseID and Period = @PeriodName

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.DeletePubcoPeriod @DatabaseID, @PeriodName


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeletePubcoPeriod] TO PUBLIC
    AS [dbo];

