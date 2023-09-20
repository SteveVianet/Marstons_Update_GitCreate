CREATE PROCEDURE [dbo].[GetWebUser] 
(
	@UserID NVARCHAR(10),
	@PHC NVARCHAR(10),
	@Email	NVARCHAR(50)
)
AS

--DECLARE	@UserID NVARCHAR(10) = NULL -- 2200
--DECLARE	@PHC NVARCHAR(10) = NULL -- '91350'
--DECLARE	@Email NVARCHAR(50) = NULL -- 'adam.myatt@marstons.co.uk'

DECLARE @ReturnValue INT = -1

/* Errors
	0 = No Errors
	1 = User has expired
	2 = User has been Deleted
	3 = A relevant User does not exist
	4 = A relevant Site does not exist
*/

DECLARE @UserDetails TABLE (
	[ID] INT PRIMARY KEY NOT NULL, 
	[Login] VARCHAR(255) NOT NULL, 
	[Password] VARCHAR(255) NOT NULL,
	[Expired] BIT NOT NULL,
	[Deleted] BIT NOT NULL)

IF @Email <> ''
BEGIN

	INSERT INTO @UserDetails
		([ID], [Login], [Password], [Expired], [Deleted])
	SELECT TOP 1 
		[ID],
		[Login], 
		[Password],
		CASE 
			WHEN [Users].[NeverExpire] = 0
			THEN CASE 
				WHEN [Users].[LastWebsiteLoginDate] < DATEADD(DAY, -90, GETDATE())
				THEN 1
				ELSE 0
				END
			ELSE 0
		END AS [Expired],
		[Users].[Deleted]
	FROM 
		[Users]
	WHERE
		[EMail] = @Email

END
ELSE IF @UserID <> ''
BEGIN

	INSERT INTO @UserDetails
		([ID], [Login], [Password], [Expired], [Deleted])
	SELECT TOP 1 
		[Users].[ID],
		[Users].[Login], 
		[Users].[Password],
		CASE 
			WHEN [Users].[NeverExpire] = 0
			THEN CASE 
				WHEN [Users].[LastWebsiteLoginDate] < DATEADD(DAY, -90, GETDATE())
				THEN 1
				ELSE 0
				END
			ELSE 0
		END AS [Expired],
		[Users].[Deleted]
	FROM 
		[Users]
	WHERE 
		[ID] = @UserID AND [UserType] IN (5,6)
	
END
ELSE IF @PHC <> ''
BEGIN

	INSERT INTO @UserDetails
		([ID], [Login], [Password], [Expired], [Deleted])
	SELECT TOP 1 
		[Users].[ID],
		[Users].[Login], 
		[Users].[Password],
		CASE 
			WHEN [Users].[NeverExpire] = 0
			THEN CASE 
				WHEN [Users].[LastWebsiteLoginDate] < DATEADD(DAY, -90, GETDATE())
				THEN 1
				ELSE 0
				END
			ELSE 0
		END AS [Expired],
		[Users].[Deleted]
	FROM [Users]
	JOIN [UserSites]
		ON [Users].[ID] = [UserSites].[UserID]
	JOIN [Sites] 
		ON [UserSites].[EDISID] = [Sites].[EDISID]
	WHERE 
		[Sites].[SiteID] = @PHC 
	AND 
		[UserType] IN (5,6)
	GROUP BY 
		[Users].[ID],
		[Users].[Login], 
		[Users].[Password],
		[Users].[Deleted],
		[Users].[NeverExpire],
		[Users].[LastWebsiteLoginDate]
	HAVING 
		COUNT([UserSites].[EDISID]) <= 2

END

-- Set default return value to "No Errors"
SET @ReturnValue = 0 

IF EXISTS (SELECT * FROM @UserDetails)
BEGIN
	-- We have a User, run a background-check. We can't simply trust the first User we see.
	IF EXISTS (SELECT * FROM @UserDetails WHERE [Expired] = 1)
	BEGIN
		-- User has expired, deny. We don't allow slackers.
		SET @ReturnValue = 1
			
	END
	ELSE IF EXISTS (SELECT * FROM @UserDetails WHERE [Deleted] = 1)
	BEGIN
		-- User has been deleted, deny. We don't allow ghosts.
		SET @ReturnValue = 2

	END
	ELSE
	BEGIN
		-- User checks out fine, allow.
		SELECT TOP 1
			[Login],
			[Password]
		FROM @UserDetails

	END
END
ELSE
BEGIN
	IF @Email <> ''
	BEGIN
		-- Could not find a user with a matching email address
		SET @ReturnValue = 3
	END
	ELSE IF @UserID <> ''
	BEGIN
		-- Could not find a valid user of the correct (licensee) type with the specified ID
		SET @ReturnValue = 3
	END
	ELSE IF @PHC <> ''
	BEGIN
		-- No User, we must determine what the issue is
		IF EXISTS (SELECT * FROM [Sites] WHERE [Sites].[SiteID] = @PHC)
		BEGIN
			-- Site exists, so a (licensee) User must not exist
			SET @ReturnValue = 3
		END
		ELSE
		BEGIN
			-- The Site does not exist
			SET @ReturnValue = 4
		END
	END
END

--SELECT @ReturnValue AS [ReturnValue];
RETURN @ReturnValue;


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUser] TO PUBLIC
    AS [dbo];

