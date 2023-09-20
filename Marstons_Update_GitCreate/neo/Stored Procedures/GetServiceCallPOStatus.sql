CREATE PROCEDURE [neo].[GetServiceCallPOStatus]
    @CallID INT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	SELECT po.ID, po.Description
	FROM dbo.Calls AS c
	JOIN [SQL1\SQL1].ServiceLogger.dbo.CallPOStatuses AS po
		ON po.ID = c.POStatusID
	WHERE c.ID = @CallID
	 
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetServiceCallPOStatus] TO PUBLIC
    AS [dbo];

