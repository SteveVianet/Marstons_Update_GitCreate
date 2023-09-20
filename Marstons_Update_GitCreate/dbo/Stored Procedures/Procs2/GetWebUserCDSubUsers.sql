CREATE PROCEDURE [dbo].[GetWebUserCDSubUsers]
(
	@UserID				INT,
	@OnlyNextLevel		BIT = 0
)

AS

SET DATEFIRST 1
SET NOCOUNT ON

DECLARE @UserHasAllSites	BIT
DECLARE @DatabaseID	INTEGER
DECLARE @UserTypeID	INTEGER
DECLARE @GetBDMs		BIT
DECLARE @GetRMs		BIT
DECLARE @GetLicensees		BIT

DECLARE @ID AS INT
DECLARE @UserName AS VARCHAR(255)
DECLARE @SubCompanyName VARCHAR(255)
DECLARE @CompanyName VARCHAR(255)
DECLARE @UserType AS INT
DECLARE @Login AS VARCHAR(255)
DECLARE @Password AS VARCHAR(255)
DECLARE @Parent AS INT
DECLARE @ParentRM AS INT
DECLARE @ParentBDM AS INT
DECLARE @ThisUsersSites	TABLE (EDISID INTEGER NOT NULL)
DECLARE @SubUsers TABLE (ID INTEGER, CompanyName VARCHAR(255), SubCompanyName VARCHAR(255), UserName VARCHAR(255), UserType INTEGER, Login VARCHAR(255), Password VARCHAR(255), Parent INTEGER, ParentRM INTEGER, ParentBDM INTEGER)



SELECT @UserHasAllSites = AllSitesVisible, @UserTypeID = UserType 
FROM Users 
JOIN UserTypes ON Users.UserType = UserTypes.ID
WHERE Users.ID = @UserID

IF @UserTypeID IN (3,4,15)
BEGIN
  --CEO or MD
	--SET @GetBDMs = 1
	SET @GetBDMs = CASE @OnlyNextLevel WHEN 1 THEN 0 ELSE 1 END
	SET @GetRMs = 1
	SET @GetLicensees = 0
END
ELSE IF @UserTypeID = 1 
BEGIN  --RM
	SET @GetBDMs = 1
	SET @GetRMs = 0
	SET @GetLicensees = 0
END
ELSE IF @UserType = 2
BEGIN  --BDM
	SET @GetBDMs = 0
	SET @GetRMs = 0
	SET @GetLicensees = 0
END
ELSE	
BEGIN  --Licensee or Other
	SET @GetBDMs = 0
	SET @GetRMs = 0
	SET @GetLicensees = 0
END

INSERT INTO @ThisUsersSites
SELECT Sites.EDISID 
FROM Sites
JOIN UserSites ON Sites.EDISID = UserSites.EDISID
WHERE UserID = @UserID AND Hidden = 0

DECLARE curUsers CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT ID, '' AS CompanyName, '' AS SubCompanyName, UserName, UserType, Login, Password
	FROM Users
	JOIN UserSites ON Users.ID = UserSites.UserID
	WHERE ((UserType = 1 AND @GetRMs = 1) OR (UserType = 2 AND @GetBDMs = 1) OR (UserType IN (5,6) AND @GetLicensees = 1))
	AND (UserSites.EDISID IN (SELECT EDISID FROM @ThisUsersSites) OR @UserHasAllSites = 1)
	AND ID <> @UserID
	GROUP BY ID, UserName, UserType, [Login], [Password]
	

OPEN curUsers
FETCH NEXT FROM curUsers INTO @ID, @CompanyName, @SubCompanyName, @UserName, @UserType, @Login, @Password
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @Parent = CASE ID WHEN @ID THEN @UserID ELSE ID END
	FROM Users
	JOIN UserSites ON Users.ID = UserSites.UserID
	WHERE UserType = 1
	AND UserSites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @ID)
	GROUP BY ID

	SELECT @ParentRM = CASE ID WHEN @ID THEN @UserID ELSE ID END
	FROM Users
	JOIN UserSites ON Users.ID = UserSites.UserID
	WHERE UserType = 1
	AND UserSites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @ID)
	GROUP BY ID

	SELECT @ParentBDM = CASE ID WHEN @ID THEN @UserID ELSE ID END
	FROM Users
	JOIN UserSites ON Users.ID = UserSites.UserID
	WHERE UserType = 2
	AND UserSites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @ID)
	GROUP BY ID

	INSERT INTO @SubUsers
	VALUES(@ID, @CompanyName, @SubCompanyName, @UserName, @UserType, @Login, @Password, @Parent, @ParentRM, @ParentBDM)

	FETCH NEXT FROM curUsers INTO @ID, @CompanyName, @SubCompanyName, @UserName, @UserType, @Login, @Password
END


SELECT ID, CompanyName, SubCompanyName, UserName, UserType, [Login], [Password], Parent, ParentRM, ParentBDM FROM @SubUsers

CLOSE curUsers
DEALLOCATE curUsers

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCDSubUsers] TO PUBLIC
    AS [dbo];

