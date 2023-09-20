CREATE PROCEDURE [dbo].[UpdatePubcoPeriod]
(
	@DatabaseID				INT,
	@CurrentPeriodName		VARCHAR(10),
	@NewPeriodName			VARCHAR(10),
	@FromWC					DATE,
	@ToWC					DATE,
	@PeriodYear				VARCHAR(10),
	@PeriodNumber			INT
)
AS

SET NOCOUNT ON

DECLARE @PeriodWeeks INT

SET @PeriodWeeks = DATEDIFF(week, @FromWC, @ToWC) + 1

UPDATE dbo.PubcoCalendars
SET Period = @NewPeriodName,
	FromWC = @FromWC,
	ToWC = @ToWC,
	PeriodWeeks = @PeriodWeeks,
	PeriodYear = @PeriodYear,
	PeriodNumber = @PeriodNumber
WHERE DatabaseID = @DatabaseID
AND Period = @CurrentPeriodName

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[UpdatePubcoPeriod] @DatabaseID, @CurrentPeriodName, @NewPeriodName ,@FromWC, @ToWC, @PeriodYear, @PeriodNumber

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdatePubcoPeriod] TO PUBLIC
    AS [dbo];

