CREATE PROCEDURE GetSubUserSites
(
    @UserID INT
)
AS

-- Get the Current Users Type
DECLARE @MasterUserType	INT
IF @UserID IS NOT NULL
BEGIN
	SELECT @MasterUserType = Users.UserType
	FROM Users
	WHERE Users.ID = @UserID
END

-- Get whether the User has implicit site assignments
DECLARE @AllSitesVisible BIT
IF @MasterUserType IS NOT NULL
BEGIN
	SELECT @AllSitesVisible = UserTypes.AllSitesVisible
	FROM UserTypes
	WHERE ID = @MasterUserType
END

IF @AllSitesVisible = 1
BEGIN
    --Master User can see everything
    SELECT EDISID 
    FROM Sites
    WHERE Sites.Hidden = 0
END
ELSE
BEGIN
    DECLARE @RelevantUsers TABLE (UserID INT NOT NULL PRIMARY KEY, UserTypeID INT NOT NULL, AllSitesVisible BIT NOT NULL)
    
    INSERT INTO @RelevantUsers
    SELECT  DISTINCT
            Users.ID AS UserID,
            UserTypes.ID AS UserTypeID,
            UserTypes.AllSitesVisible AS AllSitesVisible
    FROM Users
    JOIN UserTypes ON Users.UserType = UserTypes.ID
    JOIN UserSites ON UserSites.UserID = Users.ID
    JOIN Sites ON Sites.EDISID = UserSites.EDISID
    JOIN (  SELECT EDISID 
            FROM UserSites 
            WHERE UserID = @UserID
         ) AS MasterUserSites
           ON MasterUserSites.EDISID = UserSites.EDISID
    WHERE Users.Deleted = 0
    AND Users.Anonymise = 0
    AND Sites.Hidden = 0
    AND Users.ID <> @UserID
    AND (
        (@MasterUserType IN (3,4) AND Users.UserType IN (1, 2, 15, 5, 6))	--CEO/MD
        OR
        (@MasterUserType = 15 AND Users.UserType IN (1, 2, 5, 6))			--ROD
	    OR
	    (@MasterUserType = 1 AND Users.UserType IN (2, 5, 6))				--RM
	    OR
	    (@MasterUserType = 2 AND Users.UserType IN (5, 6))
	    )
    
    --Are any of the Sub Users marked for seeing everything?
    SELECT TOP 1 @AllSitesVisible = CASE WHEN UserID IS NOT NULL THEN 1 ELSE 0 END
    FROM @RelevantUsers
    WHERE AllSitesVisible = 1
    
    IF @AllSitesVisible = 1
    BEGIN
        --A Sub User can see everything
        SELECT EDISID 
        FROM Sites
        WHERE Sites.Hidden = 0
    END
    ELSE
    BEGIN
        SELECT  DISTINCT
                EDISID
        FROM UserSites
        JOIN @RelevantUsers AS RelevantUsers
            ON RelevantUsers.UserID = UserSites.UserID
    END
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSubUserSites] TO PUBLIC
    AS [dbo];

