CREATE PROCEDURE dbo.NIS_GET_USER_DETAILS_2
(
	@USERID	AS	INT
)
AS
SELECT     ID AS UserID, 0 AS DataExists, 0 AS DataOnStartUp, EMail, UserName AS FName, 1050 AS License, PhoneNumber AS Phone, '1234' AS PinCode, 
                      Login AS Registration, UserName AS SName, 'False' AS SendErrors, '31-DEC-2049' AS ExpireDate
FROM         dbo.Users
WHERE     (ID = @USERID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_GET_USER_DETAILS_2] TO PUBLIC
    AS [dbo];

