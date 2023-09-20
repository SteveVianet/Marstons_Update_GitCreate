CREATE PROCEDURE GetSiteExceptionEmailsByDateRange
(
 @From DATETIME,
 @To DATETIME
)

AS

SET NOCOUNT ON;

SELECT
  Sites.SiteID
  , Sites.Name
  , Sites.PostCode  
  , SiteExceptionEmailAddresses.Email
  , SiteExceptionEmails.EmailSentTo
  , SiteExceptionEmails.EmailDate
  , SiteExceptionEmails.EmailSubject
  , SiteExceptionEmails.EmailContent
  , SiteExceptionEmails.Acknowledged
  , SiteExceptions.[Type]
  , SiteExceptions.TradingDate
  , SiteExceptions.[Value]
  , SiteExceptions.LowThreshold
  , SiteExceptions.HighThreshold
  , SiteExceptions.ShiftStart
  , SiteExceptions.ShiftEnd
  , SiteExceptions.AdditionalInformation
  , SiteExceptions.ExceptionHTML
  , SiteExceptions.SiteDescription
  , SiteExceptions.EmailReplyTo
FROM SiteExceptionEmails
  INNER JOIN SiteExceptions
    ON SiteExceptionEmails.ID = SiteExceptions.ExceptionEmailID
  INNER JOIN SiteExceptionEmailAddresses
    ON SiteExceptionEmailAddresses.EDISID = SiteExceptions.EDISID
  INNER JOIN Sites
    ON SiteExceptions.EDISID = Sites.EDISID
WHERE
  SiteExceptionEmails.EmailDate >= @From
  AND SiteExceptionEmails.EmailDate <= @To
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteExceptionEmailsByDateRange] TO PUBLIC
    AS [dbo];

