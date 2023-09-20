CREATE PROCEDURE SiteDetailsVRSCAMReport
	@ScheduleID INT = NULL,
	@EDISID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	--Get BDM for each site
	DECLARE @BDM TABLE	( 
		ID INT,
		UserName VARCHAR(30),
		EDISID INT
		)

	INSERT INTO @BDM
	SELECT	u.ID,
		u.UserName,
		s.EDISID
	FROM Users As u
		INNER JOIN UserSites as us ON us.UserID = u.ID
		INNER JOIN Sites AS s ON s.EDISID = us.EDISID
	WHERE u.UserType = 2

	--SiteDetails
	DECLARE @SiteDetails TABLE(
	    EDISID INT, 
		BDM VARCHAR(50),
		SiteID VARCHAR(100),
		SiteName VARCHAR(100),
		Address1 VARCHAR(100),
		Address2 VARCHAR(100),
		Address3 VARCHAR(100),
		Address4 VARCHAR(100),
		PostCode VARCHAR(20),
		TenantName VARCHAR(100),
		SiteTelNumber VARCHAR(100),
		AltSiteTelNumber VARCHAR(100)
		)

	INSERT INTO @SiteDetails
	SELECT 
		s.EDISID,
		BDM.UserName,
		s.SiteID,
		s.Name,
		s.Address1,
		s.Address2,
		s.Address3,
		s.Address4,
		s.PostCode,
		s.TenantName,
		s.SiteTelNo,
		s.AltSiteTelNo
	FROM Sites AS s
		INNER JOIN @BDM AS BDM ON BDM.EDISID = s.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID

	--Get Pub Co Tie Type

	DECLARE @TieType TABLE(
		EDISID INT,
		PubCoTieType VARCHAR(100)
		)

	INSERT INTO @TieType
	SELECT s.EDISID,
		   sp.Value
	FROM Properties AS p
		INNER JOIN SiteProperties AS sp ON p.ID = sp.PropertyID
		INNER JOIN Sites AS s ON s.EDISID = sp.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE p.Name = 'Pub Co Tie Type'

    --Main Select Statement

	SELECT 
		sd.BDM,
		sd.SiteID,
		sd.SiteName,
		sd.Address1,
		sd.Address2,
		sd.Address3,
		sd.Address4,
		sd.PostCode,
		sd.TenantName,
		sd.SiteTelNumber,
		sd.AltSiteTelNumber,
		ISNULL(tt.PubCoTieType,'') AS PubCoTieType
	FROM @SiteDetails AS sd
		LEFT JOIN @TieType AS tt ON tt.EDISID = sd.EDISID
	ORDER BY sd.SiteName ASC

	
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SiteDetailsVRSCAMReport] TO PUBLIC
    AS [dbo];

