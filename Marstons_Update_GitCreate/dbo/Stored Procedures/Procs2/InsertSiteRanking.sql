CREATE PROCEDURE [dbo].[InsertSiteRanking]
(
	@EDISID		INT,
	@RankingTypeID	INT,
	@ManualText		VARCHAR(1024),
	@ValidTo		DATETIME	= NULL,
	@CategoryID		INT = 1,		-- default to dispense monitoring
	@ValidFrom		DATETIME	 = NULL,
	@AssignedBy		VARCHAR(255)	= NULL
)

AS

INSERT INTO dbo.SiteRankings   
	(EDISID, ValidFrom, ValidTo, ManualText, RankingTypeID, RankingCategoryID, AssignedBy)   
VALUES   
	(@EDISID, @ValidFrom, @ValidTo, @ManualText, @RankingTypeID, @CategoryID, @AssignedBy)

-- Create a new current ranking entry (if it doesn't already exist)
DECLARE @RankingEDISID INT

SELECT @RankingEDISID = EDISID
FROM SiteRankingCurrent
WHERE EDISID = @EDISID

IF ISNULL(@RankingEDISID,0) <> @EDISID
BEGIN
	INSERT INTO SiteRankingCurrent
		(EDISID, PouringYield, TillYield, Cleaning, Audit)
	VALUES
		(@EDISID, 6, 6, 6, 6)
END

--Update the current ranking
UPDATE SiteRankingCurrent
SET PouringYield = @RankingTypeID
WHERE EDISID = @EDISID AND @CategoryID = 9

UPDATE SiteRankingCurrent
SET TillYield = @RankingTypeID
WHERE EDISID = @EDISID AND @CategoryID = 10

UPDATE SiteRankingCurrent				
SET Cleaning = @RankingTypeID
WHERE EDISID = @EDISID AND @CategoryID = 8

UPDATE SiteRankingCurrent
SET Audit = @RankingTypeID
WHERE EDISID = @EDISID AND @CategoryID = 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertSiteRanking] TO PUBLIC
    AS [dbo];

