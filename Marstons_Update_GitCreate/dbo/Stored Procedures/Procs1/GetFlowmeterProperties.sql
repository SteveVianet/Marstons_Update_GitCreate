CREATE PROCEDURE [dbo].[GetFlowmeterProperties]

	@EDISID	AS INT,
	@From	AS DATETIME

AS

SET NOCOUNT ON

--@From is actually a To date, but unfortunately we'd need to muck around with SiteLib now to correct that mistake.

IF @From IS NULL OR YEAR(@From) < 1990
SET @From = GETDATE()

DECLARE @AddressSetups		TABLE (FontNumber INT NOT NULL, SetupID INT NOT NULL, [Address] INT)
DECLARE @OldScalarSetups	TABLE (FontNumber INT NOT NULL, SetupID INT NOT NULL, Scalar INT)
DECLARE @NewScalarSetups	TABLE (FontNumber INT NOT NULL, SetupID INT NOT NULL, Scalar INT)

INSERT INTO @AddressSetups (FontNumber, SetupID)
SELECT FontNumber, MAX(ProposedFontSetupID)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
JOIN (
	SELECT PhysicalAddress AS [Address], MAX(ProposedFontSetupID) AS SetupID
	FROM ProposedFontSetupItems
	JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
	WHERE ProposedFontSetups.EDISID = @EDISID 
	AND PhysicalAddress IS NOT NULL
	AND CreateDate <= @From	
	GROUP BY PhysicalAddress
) AS UniqueAddresses ON UniqueAddresses.[Address] = ProposedFontSetupItems.PhysicalAddress AND ProposedFontSetupID = UniqueAddresses.SetupID
WHERE ProposedFontSetups.EDISID = @EDISID 
AND PhysicalAddress IS NOT NULL AND PhysicalAddress > 0
AND CreateDate <= @From
GROUP BY FontNumber

INSERT INTO @NewScalarSetups (FontNumber, SetupID)
SELECT FontNumber, MAX(ProposedFontSetupID)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetups.EDISID = @EDISID 
AND NewCalibrationValue IS NOT NULL AND NewCalibrationValue > 0
AND CreateDate <= @From
GROUP BY FontNumber
ORDER BY FontNumber

INSERT INTO @OldScalarSetups (FontNumber, SetupID)
SELECT FontNumber, MAX(ProposedFontSetupID)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetups.EDISID = @EDISID 
AND OriginalCalibrationValue IS NOT NULL AND OriginalCalibrationValue > 0
AND CreateDate <= @From
GROUP BY FontNumber
ORDER BY FontNumber

UPDATE @AddressSetups
SET [Address] = PhysicalAddress
FROM ProposedFontSetupItems
JOIN @AddressSetups AS AddressSetups ON AddressSetups.SetupID = ProposedFontSetupItems.ProposedFontSetupID
 AND AddressSetups.FontNumber = ProposedFontSetupItems.FontNumber
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetupItems.PhysicalAddress IS NOT NULL
AND CreateDate <= @From

UPDATE @NewScalarSetups
SET Scalar = NewCalibrationValue
FROM ProposedFontSetupItems
JOIN @NewScalarSetups AS NewScalarSetups ON NewScalarSetups.SetupID = ProposedFontSetupItems.ProposedFontSetupID
 AND NewScalarSetups.FontNumber = ProposedFontSetupItems.FontNumber
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetupItems.NewCalibrationValue IS NOT NULL
AND CreateDate <= @From

UPDATE @OldScalarSetups
SET Scalar = OriginalCalibrationValue
FROM ProposedFontSetupItems
JOIN @OldScalarSetups AS OldScalarSetups ON OldScalarSetups.SetupID = ProposedFontSetupItems.ProposedFontSetupID
 AND OldScalarSetups.FontNumber = ProposedFontSetupItems.FontNumber
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetupItems.OriginalCalibrationValue IS NOT NULL
AND CreateDate <= @From

SELECT AddressSetups.FontNumber, AddressSetups.[Address], ISNULL(ISNULL(NewScalarSetups.Scalar, OldScalarSetups.Scalar), 400) AS Prescaler
FROM @AddressSetups AS AddressSetups
FULL JOIN @OldScalarSetups AS OldScalarSetups ON OldScalarSetups.FontNumber = AddressSetups.FontNumber
FULL JOIN @NewScalarSetups AS NewScalarSetups ON NewScalarSetups.FontNumber = AddressSetups.FontNumber
WHERE AddressSetups.Address IS NOT NULL




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetFlowmeterProperties] TO PUBLIC
    AS [dbo];

