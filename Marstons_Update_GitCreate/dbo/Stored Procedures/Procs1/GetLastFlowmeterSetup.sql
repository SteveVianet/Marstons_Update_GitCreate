CREATE PROCEDURE [dbo].[GetLastFlowmeterSetup]
(
	@EDISID	INT
)
AS

SET NOCOUNT ON

DECLARE @AddressSetups		TABLE (FontNumber INT NOT NULL, SetupID INT NOT NULL, [Address] INT)
DECLARE @OldScalarSetups	TABLE (FontNumber INT NOT NULL, SetupID INT NOT NULL, Scalar INT)
DECLARE @NewScalarSetups	TABLE (FontNumber INT NOT NULL, SetupID INT NOT NULL, Scalar INT)
DECLARE @LatestSetup		INT

SELECT @LatestSetup = MAX(ID)
FROM ProposedFontSetups
WHERE EDISID = @EDISID

INSERT INTO @AddressSetups (FontNumber, SetupID)
SELECT FontNumber, MAX(ProposedFontSetupID)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetups.EDISID = @EDISID 
AND ProposedFontSetupItems.PhysicalAddress IS NOT NULL
AND ProposedFontSetupItems.PhysicalAddress > 0
AND ProposedFontSetupID < @LatestSetup
GROUP BY FontNumber

INSERT INTO @NewScalarSetups (FontNumber, SetupID)
SELECT FontNumber, MAX(ProposedFontSetupID)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetups.EDISID = @EDISID 
AND ProposedFontSetupItems.NewCalibrationValue IS NOT NULL
AND ProposedFontSetupItems.NewCalibrationValue > 0
AND ProposedFontSetupID < @LatestSetup
GROUP BY FontNumber

INSERT INTO @OldScalarSetups (FontNumber, SetupID)
SELECT FontNumber, MAX(ProposedFontSetupID)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE ProposedFontSetups.EDISID = @EDISID 
AND ProposedFontSetupItems.OriginalCalibrationValue IS NOT NULL
AND ProposedFontSetupItems.OriginalCalibrationValue > 0
AND ProposedFontSetupID < @LatestSetup
GROUP BY FontNumber

UPDATE @AddressSetups
SET [Address] = PhysicalAddress
FROM ProposedFontSetupItems
JOIN @AddressSetups AS AddressSetups
	ON AddressSetups.SetupID = ProposedFontSetupItems.ProposedFontSetupID
	AND ProposedFontSetupItems.FontNumber = AddressSetups.FontNumber
WHERE ProposedFontSetupItems.PhysicalAddress IS NOT NULL

UPDATE @NewScalarSetups
SET Scalar = NewCalibrationValue
FROM ProposedFontSetupItems
JOIN @NewScalarSetups AS NewScalarSetups
	ON NewScalarSetups.SetupID = ProposedFontSetupItems.ProposedFontSetupID
	AND ProposedFontSetupItems.FontNumber = NewScalarSetups.FontNumber
WHERE ProposedFontSetupItems.NewCalibrationValue IS NOT NULL

UPDATE @OldScalarSetups
SET Scalar = OriginalCalibrationValue
FROM ProposedFontSetupItems
JOIN @OldScalarSetups AS OldScalarSetups
	ON OldScalarSetups.SetupID = ProposedFontSetupItems.ProposedFontSetupID
	AND ProposedFontSetupItems.FontNumber = OldScalarSetups.FontNumber
WHERE ProposedFontSetupItems.OriginalCalibrationValue IS NOT NULL

SELECT COALESCE(AddressSetups.SetupID, OldScalarSetups.SetupID, NewScalarSetups.SetupID) AS SetupID,
	COALESCE(AddressSetups.FontNumber, OldScalarSetups.FontNumber, NewScalarSetups.FontNumber) AS FontNumber,
	AddressSetups.Address,
	COALESCE(NewScalarSetups.Scalar, OldScalarSetups.Scalar, 400) AS LastPrescaler,
	ProposedFontSetups.CreateDate AS LastPrescalerDate
FROM @AddressSetups AS AddressSetups
FULL JOIN @OldScalarSetups AS OldScalarSetups ON OldScalarSetups.FontNumber = AddressSetups.FontNumber
FULL JOIN @NewScalarSetups AS NewScalarSetups ON NewScalarSetups.FontNumber = AddressSetups.FontNumber
JOIN ProposedFontSetups ON ProposedFontSetups.ID = COALESCE(NewScalarSetups.SetupID, OldScalarSetups.SetupID)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLastFlowmeterSetup] TO PUBLIC
    AS [dbo];

