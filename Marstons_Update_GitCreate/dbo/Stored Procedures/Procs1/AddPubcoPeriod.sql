CREATE PROCEDURE [dbo].[AddPubcoPeriod]
(
	@PeriodName		VARCHAR(10),
	@FromWC			DATE,
	@ToWC			DATE,
	@PeriodYear		VARCHAR(10),
	@PeriodNumber	INT = NULL
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

DECLARE @PeriodWeeks INT

SET @PeriodWeeks = DATEDIFF(week, @FromWC, @ToWC) + 1

INSERT INTO dbo.PubcoCalendars
(DatabaseID, Period, FromWC, ToWC, PeriodYear, PeriodWeeks, PeriodNumber)
VALUES
(@DatabaseID, @PeriodName, @FromWC, @ToWC, @PeriodYear, @PeriodWeeks, @PeriodNumber)

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.AddPubcoPeriod @DatabaseID, @PeriodName, @FromWC, @ToWC, @PeriodYear, @PeriodNumber

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPubcoPeriod] TO PUBLIC
    AS [dbo];

