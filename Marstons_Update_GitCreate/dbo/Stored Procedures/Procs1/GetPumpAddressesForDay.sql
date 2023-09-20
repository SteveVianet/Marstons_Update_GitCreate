CREATE PROCEDURE [dbo].[GetPumpAddressesForDay]
    @EDISID		INTEGER,
    @Date		DATE,
    @Pump       INT = NULL
AS

--DECLARE   @EDISID		INTEGER = 60
--DECLARE   @Date		DATE = '2013-04-19'
--DECLARE   @Pump       INT = NULL

DECLARE @PreviousPFS INT -- Used to store the relevant PFS

-- Get the last Proposed Font Setup prior to the date range we are looking at
SELECT @PreviousPFS = MAX(PFS.ID)
FROM ProposedFontSetups AS PFS
WHERE PFS.EDISID = @EDISID
AND CAST(CreateDate AS DATE) <= @Date

-- Return the Device Addresses in use for the Day specified
SELECT
    PFS.EDISID,
    CAST(PFS.CreateDate AS DATE) AS CreateDate,
    CAST(@Date AS DATE) AS CurrentDate,
    PFSI.FontNumber,
    PFSI.PhysicalAddress
FROM ProposedFontSetups AS PFS
LEFT JOIN ProposedFontSetupItems AS PFSI ON PFS.ID = PFSI.ProposedFontSetupID
WHERE PFS.EDISID = @EDISID
AND PFS.ID = @PreviousPFS
AND PFSI.PhysicalAddress IS NOT NULL
AND (@Pump Is NULL OR PFSI.FontNumber = @Pump)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPumpAddressesForDay] TO PUBLIC
    AS [dbo];

