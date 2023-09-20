CREATE PROCEDURE [dbo].[AssignSiteRanking]
(
	@EDISID		INT,
	@RankingTypeID	INT,
	@ManualText		VARCHAR(1024),
	@ValidTo		DATETIME	= NULL,
	@CategoryID		INT = 1		-- default to dispense monitoring
)

AS

DECLARE @ValidFrom		DATETIME
DECLARE @PreviousValidFrom	DATETIME
DECLARE @PreviousValidTo	DATETIME
DECLARE @GlobalEDISID	INTEGER

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.AssignSiteRanking @GlobalEDISID, @RankingTypeID, @ManualText, @ValidTo, @CategoryID
END
*/

SET DATEFORMAT ymd

-- Calculate todays date
SET @ValidFrom = CAST(CONVERT(VARCHAR(10), GETDATE(), 20) AS SMALLDATETIME)
SET @ValidTo = CAST(CONVERT(VARCHAR(10), @ValidTo, 20) AS SMALLDATETIME)

IF @ValidFrom > @ValidTo
BEGIN
	SET @ValidFrom = @ValidTo
END

-- Check for existing ranking
SELECT	@PreviousValidFrom = CAST(CONVERT(VARCHAR(10), ValidFrom, 20) AS SMALLDATETIME),
	@PreviousValidTo = CAST(CONVERT(VARCHAR(10), ValidTo, 20) AS SMALLDATETIME)
FROM dbo.SiteRankings
WHERE EDISID = @EDISID AND RankingCategoryID = @CategoryID AND ValidTo IS NULL

IF @PreviousValidFrom IS NULL
BEGIN
	SELECT TOP 1 	@PreviousValidFrom = CAST(CONVERT(VARCHAR(10), ValidFrom, 20) AS SMALLDATETIME),
			@PreviousValidTo = CAST(CONVERT(VARCHAR(10), ValidTo, 20) AS SMALLDATETIME)
	FROM dbo.SiteRankings
	WHERE EDISID = @EDISID  AND RankingCategoryID = @CategoryID
	ORDER BY ValidTo DESC
END

--Ensure we have a valid to date
IF @ValidTo IS NULL
BEGIN
	SET @ValidTo = @ValidFrom
END

-- We are making up to four separate updates
BEGIN TRAN
	-- If we have a previous entry...
	IF @PreviousValidFrom IS NOT NULL
	BEGIN
		-- If previous entry is for today, just delete it, otherwise close it off
		IF @PreviousValidFrom >= @ValidFrom
		BEGIN
			DELETE FROM dbo.SiteRankings
			WHERE EDISID = @EDISID
			AND ValidFrom = @PreviousValidFrom
			AND ValidTo = @PreviousValidTo
			AND RankingCategoryID = @CategoryID
		END
		ELSE
		BEGIN
			UPDATE dbo.SiteRankings
			SET ValidTo = DATEADD(Day, -1, @ValidFrom)
			WHERE EDISID = @EDISID
			AND ValidFrom = @PreviousValidFrom
			AND (ValidTo = @PreviousValidTo OR ValidTo IS NULL)
			AND RankingCategoryID = @CategoryID
		END
		
	END
	
	INSERT INTO dbo.SiteRankings   
		(EDISID, ValidFrom, ValidTo, ManualText, RankingTypeID, RankingCategoryID)   
	VALUES   
		(@EDISID, @ValidFrom, @ValidTo, @ManualText, @RankingTypeID, @CategoryID)      	

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
	
COMMIT


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AssignSiteRanking] TO PUBLIC
    AS [dbo];

