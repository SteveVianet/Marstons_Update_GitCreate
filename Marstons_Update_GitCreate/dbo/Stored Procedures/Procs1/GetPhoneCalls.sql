CREATE PROCEDURE [dbo].[GetPhoneCalls]

AS

SELECT	[CallID],
	pc.[PhoneNumber],
	pc.PhoneID,
	p.OperatorName,
	[CallDate],
	[Duration],
	[Cost]
FROM dbo.PhoneCalls as pc
join dbo.Phones as p on pc.PhoneID = p.PhoneID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPhoneCalls] TO PUBLIC
    AS [dbo];

