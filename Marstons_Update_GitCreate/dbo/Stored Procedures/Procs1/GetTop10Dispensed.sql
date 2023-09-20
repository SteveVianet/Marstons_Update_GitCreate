CREATE PROCEDURE GetTop10Dispensed	
	@EDISID INT = NULL,
	@UserID INT = NULL,
	@From DATE,
	@To DATE,
	@IncludeClosedSites BIT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET DATEFIRST 1

	-- Get Multi-Cellar Sites for the user
	DECLARE @Sites TABLE (
    EDISID INT,
    PrimarySiteID VARCHAR(50),
    PrimarySiteName VARCHAR(50),
    Town  VARCHAR(50)
)
	INSERT INTO @Sites
    SELECT DISTINCT us.EDISID, s.SiteID, s.Name,
        CASE
            WHEN Address3 = '' AND Address2 = '' THEN Address1
            WHEN Address3 = '' THEN Address2
            ELSE Address3
        END AS Town
    FROM UserSites AS us
    LEFT JOIN (
        SELECT SiteGroupID,EDISID
        FROM SiteGroupSites AS s    
        LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
        WHERE sg.TypeID = 1
    ) AS sgs
        ON sgs.EDISID = us.EDISID
    LEFT JOIN SiteGroupSites AS sgs2 
		ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
    JOIN Sites AS s 
		ON s.EDISID = COALESCE(sgs2.EDISID, us.EDISID)
    WHERE (us.UserID = @UserID OR @UserID IS NULL)
		AND (us.EDISID = @EDISID OR @EDISID IS NULL)
		AND (s.SiteClosed = 0 OR @IncludeClosedSites = 1 OR @IncludeClosedSites IS NULL)


	SELECT TOP 10 dld.Product, p.Description, SUM(dld.Quantity) AS Quantity
	FROM @Sites AS s
	JOIN MasterDates AS md
		ON md.EDISID = s.EDISID
	JOIN DLData AS dld
		ON dld.DownloadID = md.ID
	JOIN Products AS p
		ON p.ID = dld.Product
	WHERE md.Date BETWEEN @From AND @To
	GROUP BY dld.Product, p.Description
	ORDER BY Quantity DESC
    
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTop10Dispensed] TO PUBLIC
    AS [dbo];

