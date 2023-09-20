CREATE PROCEDURE [dbo].[GetWebUserByPropertyHash] 
(
	@PropertyName VARCHAR(50)= '',
	@HashValue VARCHAR(255) = ''
)
AS

--DECLARE	@PropertyName VARCHAR(50)= 'SoldTo'
--DECLARE	@HashValue VARCHAR(255) = 'b0f942b07b56c34b66aeccbb8abaf3c7'

DECLARE @ReturnValue INT = -1


/* Errors
	0 = No Errors
	1 = User has expired
	2 = User has been Deleted
	3 = A relevant User does not exist
	4 = A relevant Site does not exist
*/

DECLARE @SitePropertyValues TABLE (
	[EDISID] INT PRIMARY KEY NOT NULL,
	[Value] VARCHAR(255) NOT NULL,
	[Hash] VARCHAR(32))

DECLARE @UserDetails TABLE (
	[ID] INT PRIMARY KEY NOT NULL, 
	[Login] VARCHAR(255) NOT NULL, 
	[Password] VARCHAR(255) NOT NULL,
	[Expired] BIT NOT NULL,
	[Deleted] BIT NOT NULL)

IF @PropertyName <> '' AND @HashValue <> ''
BEGIN

	INSERT INTO @SitePropertyValues
		([EDISID], [Value])
	SELECT [EDISID], [Value]
	FROM [Properties]
	JOIN [SiteProperties]
		ON [SiteProperties].[PropertyID] = [Properties].[ID]
	WHERE 
		LOWER([Properties].[Name]) = LOWER(@PropertyName)
	
	IF @PropertyName = 'SoldTo'
	BEGIN
		-- Generate Hash for: Heineken / Star Pubs 
		DECLARE @PrivateKey VARCHAR(200) = 'ITNVianet'
		DECLARE @Seperator VARCHAR(1) = '|'
		DECLARE @Date VARCHAR(8) = CONVERT(VARCHAR(10), GETDATE(), 112)

		UPDATE @SitePropertyValues
		SET [Hash] = 
			CONVERT(VARCHAR(32), 
			HashBytes('MD5', @PrivateKey + @Seperator + @Date + @Seperator + [Value]), 
			2)

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
		FROM @SitePropertyValues AS [HashedValues]
		JOIN [Sites]
			ON [Sites].[EDISID] = [HashedValues].[EDISID]
		JOIN [UserSites]
			ON [UserSites].[EDISID] = [HashedValues].[EDISID]
		JOIN [Users]
			ON [Users].[ID] = [UserSites].[UserID]
		WHERE
			LOWER([HashedValues].[Hash]) = LOWER(@HashValue)
		AND 
			[Users].[UserType] IN (5,6)
		AND
			[Sites].[Hidden] = 0
		GROUP BY 
			[Users].[ID],
			[Users].[Login], 
			[Users].[Password],
			[Users].[Deleted],
			[Users].[NeverExpire],
			[Users].[LastWebsiteLoginDate]
		HAVING 
			COUNT([UserSites].[EDISID]) <= 2

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
			-- No User, we must determine what the issue is
			IF EXISTS (SELECT * FROM [Properties] WHERE [Properties].[Name] = @PropertyName)
			BEGIN
				-- Property Exists, check whether we can match a Site
				IF EXISTS (
					SELECT * 
					FROM @SitePropertyValues AS [HashedValues]
					WHERE 
						LOWER([HashedValues].[Hash]) = LOWER(@HashValue))
				BEGIN
					-- We found a Site, which means the User doesn't exist. 
					SET @ReturnValue = 3
				END
				ELSE
				BEGIN
					-- We can't find a site which has the desired property value.
					SET @ReturnValue = 4
				END
			END
			ELSE
			BEGIN
				-- Cannot find site, we have no hope of doing so when the property doesn't even exist
				SET @ReturnValue = 4
			END

		END
	END
	ELSE
	BEGIN
		-- Not using a known property/hash methodology. 
		-- We can't look for a Site without knowing how to create the matching hash.
		SET @ReturnValue = 4
	END

END

--SELECT @ReturnValue AS [ReturnValue];
RETURN @ReturnValue;


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserByPropertyHash] TO PUBLIC
    AS [dbo];

