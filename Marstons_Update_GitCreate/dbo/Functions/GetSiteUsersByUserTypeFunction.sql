CREATE FUNCTION dbo.GetSiteUsersByUserTypeFunction (@UserTypeID as int, @EDISID as int)
RETURNS varchar(8000)
AS
BEGIN
DECLARE @RetVal varchar(8000)
SELECT @RetVal = ''
SELECT @RetVal=@RetVal + Users.UserName + ', '
FROM Users
JOIN UserSites ON UserSites.UserID = Users.[ID]
WHERE Users.UserType = @UserTypeID
AND UserSites.EDISID = @EDISID
select @RetVal = CASE WHEN LEN(@RetVal) > 0 THEN left(@RetVal, len(@RetVal)-1) END
RETURN (ISNULL(@RetVal, '<None>'))
END
