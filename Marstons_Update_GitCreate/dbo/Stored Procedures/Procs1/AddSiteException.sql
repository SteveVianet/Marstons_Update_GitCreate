CREATE PROCEDURE [dbo].[AddSiteException]
(
                @EDISID                                                                                              INT,
                @Type                                                                                  VARCHAR(100),
                @TradingDate                                                   DATE,
                @Value                                                                                                FLOAT,
                @LowThreshold                                                               FLOAT = NULL,
                @HighThreshold                                                              FLOAT = NULL,
                @ShiftStart                                                                         DATETIME = NULL,
                @ShiftEnd                                                                           DATETIME = NULL,
                @ExceptionEmailID                                         INT = NULL,
                @AdditionalInformation                               VARCHAR(MAX) = NULL,
                @ExceptionHTML                                                            VARCHAR(MAX) = NULL,
                @SiteDescription                                             VARCHAR(1000) = NULL,
                @DateFormat                                                                   VARCHAR(25) = NULL,
                @EmailReplyTo                                                 VARCHAR(50) = NULL
)
AS

SET NOCOUNT ON

DECLARE @SiteGroupID INT
DECLARE @ExceptionAlreadySent BIT
DECLARE @SiteExceptionTypeID SMALLINT = NULL

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

IF @SiteGroupID IS NOT NULL
BEGIN
                SELECT @EDISID = EDISID
                FROM SiteGroupSites
                WHERE SiteGroupID = @SiteGroupID AND IsPrimary = 1

END

SELECT 
                @ExceptionAlreadySent = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
FROM SiteExceptions
WHERE EDISID = @EDISID
                AND TradingDate = @TradingDate
                AND ExceptionEmailID > 0
                AND [Type] = @Type
                AND @Type <> 'Weekly Site Report'

IF @ExceptionAlreadySent IS NULL
BEGIN
                SET @ExceptionAlreadySent = 0
END

IF @ExceptionAlreadySent = 0
BEGIN

                SELECT @SiteExceptionTypeID = [ID]
                FROM SiteExceptionTypes 
                WHERE [Description] = @Type

                INSERT INTO SiteExceptions
                (EDISID, [Type], TradingDate, Value, LowThreshold, HighThreshold, ShiftStart, ShiftEnd, ExceptionEmailID, AdditionalInformation, ExceptionHTML, SiteDescription, [DateFormat], EmailReplyTo, TypeID)
                VALUES
                (@EDISID, @Type, @TradingDate, @Value, @LowThreshold, @HighThreshold, @ShiftStart, @ShiftEnd, @ExceptionEmailID, @AdditionalInformation, @ExceptionHTML, @SiteDescription, @DateFormat, @EmailReplyTo, @SiteExceptionTypeID)
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteException] TO PUBLIC
    AS [dbo];

