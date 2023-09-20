CREATE PROCEDURE [dbo].[GetHistoricalProposedLineDetails]
(
	@MaxID		INT,
	@FontNumber	INT
)

AS

DECLARE @CalibrationDate DATETIME
DECLARE @JobType INT
DECLARE @ChecksForYear INT

DECLARE @EDISID INT
DECLARE @StartDate DATETIME
DECLARE @EndDate DATETIME
DECLARE @NewMeterDate DATETIME

SET NOCOUNT ON

SELECT @EndDate = CreateDate FROM ProposedFontSetups WHERE ID = @MaxID
SET @StartDate = DATEADD(yy, -1, @EndDate)
SELECT @EDISID = EDISID FROM ProposedFontSetups WHERE ID = @MaxID

SELECT @NewMeterDate = MAX(CreateDate) FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = 
ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetups.EDISID = @EDISID
AND ProposedFontSetupItems.FontNumber = @FontNumber
AND ProposedFontSetupItems.JobType = 1


SELECT @CalibrationDate = CreateDate, @JobType = JobType
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupID
WHERE ProposedFontSetupID < @MaxID
AND JobType IN (1,2,6)
AND FontNumber = @FontNumber
AND EDISID = @EDISID

--Count of Cal. Checks for the last year
SELECT @ChecksForYear = COUNT(*)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupID
WHERE ProposedFontSetupID < @MaxID
AND ProposedFontSetups.CreateDate >= '2009-09-01'
AND (ProposedFontSetups.CreateDate >= @NewMeterDate OR @NewMeterDate IS NULL)
AND JobType IN (1,2)
AND FontNumber = @FontNumber
AND EDISID = @EDISID
AND GlasswareID IS NOT NULL

SELECT @CalibrationDate AS CalDate, @JobType AS JobType, @ChecksForYear AS 
ChecksForYear
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHistoricalProposedLineDetails] TO PUBLIC
    AS [dbo];

