---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ENG_PushEngineerJob2
(
	@CallReference VARCHAR(20),
	@Client VARCHAR(50),
	@SiteID VARCHAR(50),
	@SiteName VARCHAR(50),
	@SiteAddress VARCHAR(50),
	@SiteTown VARCHAR(50),
	@SiteCounty VARCHAR(50),
	@SitePCode VARCHAR(8),
	@SiteLong FLOAT,
	@SiteLat FLOAT,
	@SiteTelephone VARCHAR(20),
	@EDISTelephone VARCHAR(20),
	@EDISSerialNo VARCHAR(10),
	@JobType CHAR(1),
	@VisitDateTime DATETIME,
	@Faults VARCHAR(255),
	@EngineerID INT,
	@Description VARCHAR(50),
	@DaysOut INT
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.ENG_PushEngineerJob	@CallReference,
									@Client,
									@SiteID,
									@SiteName,
									@SiteAddress,
									@SiteTown,
									@SiteCounty,
									@SitePCode,
									@SiteLong,
									@SiteLat,
									@SiteTelephone,
									@EDISTelephone,
									@EDISSerialNo,
									@JobType,
									@VisitDateTime,
									@Faults,
									@EngineerID,
									@Description,
									@DaysOut


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ENG_PushEngineerJob2] TO PUBLIC
    AS [dbo];

