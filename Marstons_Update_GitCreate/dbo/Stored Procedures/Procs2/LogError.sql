CREATE PROCEDURE [dbo].[LogError]
(
	@ErrorNumber int,
	@ErrorDescription varchar(1024),
	@ErrorSource varchar(255),
	@MethodName varchar(255)
)

AS

INSERT INTO dbo.ErrorLogs
(UserName, ErrorNumber, ErrorDescription, ErrorSource, MethodName)
VALUES
(SYSTEM_USER, @ErrorNumber, @ErrorDescription, @ErrorSource, @MethodName)

IF @ErrorNumber = 4445 -- Fatal Error raising Call
BEGIN
    EXEC [dbo].[SendEmail] 'auditor@vianetplc.com', 'Auditor', 'FailedToReachJW@vianetplc.com', 'Error when raising Call', @ErrorDescription, NULL, NULL, NULL, NULL
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[LogError] TO PUBLIC
    AS [dbo];

