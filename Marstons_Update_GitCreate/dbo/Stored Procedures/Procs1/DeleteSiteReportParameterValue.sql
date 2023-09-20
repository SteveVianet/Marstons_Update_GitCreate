CREATE PROCEDURE dbo.DeleteSiteReportParameterValue
(
	@EDISID		INTEGER,
	@ReportID		INTEGER,
	@ParameterID		INTEGER
) 
AS

DELETE FROM dbo.ReportParameters
WHERE EDISID = @EDISID
AND ReportID = @ReportID
AND ParameterID = @ParameterID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteReportParameterValue] TO PUBLIC
    AS [dbo];

