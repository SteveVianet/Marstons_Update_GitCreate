CREATE PROCEDURE [dbo].[RefreshFlowmeterConfiguration]
AS

SET NOCOUNT ON

TRUNCATE TABLE FlowmeterConfiguration

INSERT INTO FlowmeterConfiguration
(EDISID,
FontNumber,
ProductID,
PhysicalAddress,
GlobalProductID,
Memory,
Version,
IsCask)

SELECT		LatestIFMAddressMap.EDISID,
			LatestIFMAddressMap.FontNumber,
			PumpSetup.ProductID,
			Items.PhysicalAddress,
			CASE WHEN Products.GlobalID = 0 THEN NULL ELSE Products.GlobalID END,
			PumpSetup.IFMConfiguration,
			Items.Version,
			Products.IsCask
FROM (
	SELECT  IFMAddressMaps.EDISID,
			IFMAddressMaps.FontNumber,
			MAX(IFMAddressMaps.ProposedFontSetupID) AS ProposedFontSetupID
	FROM (
		SELECT  ProposedFontSetupItems.PhysicalAddress,
				ProposedFontSetups.EDISID,
				ProposedFontSetupItems.FontNumber,
				ProposedFontSetups.ID AS ProposedFontSetupID,
				ProposedFontSetupItems.Version
		FROM ProposedFontSetupItems
		JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
		JOIN (
			SELECT PhysicalAddress, MAX(ProposedFontSetupID) AS ProposedFontSetupID
			FROM ProposedFontSetupItems
			WHERE PhysicalAddress BETWEEN 0xC8 AND 0xFFFFFF AND Version IS NOT NULL
			GROUP BY PhysicalAddress
		) AS LatestFontSetup ON (LatestFontSetup.ProposedFontSetupID = ProposedFontSetupItems.ProposedFontSetupID AND LatestFontSetup.PhysicalAddress = ProposedFontSetupItems.PhysicalAddress)
		WHERE ProposedFontSetupItems.PhysicalAddress BETWEEN 0xC8 AND 0xFFFFFF
	) AS IFMAddressMaps
	GROUP BY IFMAddressMaps.EDISID, IFMAddressMaps.FontNumber
) AS LatestIFMAddressMap
JOIN ProposedFontSetupItems AS Items ON Items.ProposedFontSetupID = LatestIFMAddressMap.ProposedFontSetupID AND Items.FontNumber = LatestIFMAddressMap.FontNumber
JOIN PumpSetup ON (PumpSetup.EDISID = LatestIFMAddressMap.EDISID AND PumpSetup.Pump = LatestIFMAddressMap.FontNumber AND PumpSetup.ValidTo IS NULL)
JOIN Products ON Products.ID = PumpSetup.ProductID
JOIN Sites ON Sites.EDISID = LatestIFMAddressMap.EDISID
WHERE Sites.SystemTypeID = 8

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshFlowmeterConfiguration] TO PUBLIC
    AS [dbo];

