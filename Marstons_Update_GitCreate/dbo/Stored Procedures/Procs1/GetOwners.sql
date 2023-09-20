
CREATE PROCEDURE [dbo].[GetOwners]

AS

SELECT	[ID],
	[Name],
	ContactName,
	Address1,
	Address2,
	Address3,
	Address4,
	Postcode,
	SendScorecardEmail,
	POSYieldCashValue,
	CleaningCashValue,
	PouringYieldCashValue,
	TargetPouringYieldPercent,
	TargetTillYieldPercent,
	ScorecardFromEmailAddress,
	UseExceptionReporting,
	AutoSendExceptions
FROM dbo.Owners
ORDER BY [Name]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOwners] TO PUBLIC
    AS [dbo];

