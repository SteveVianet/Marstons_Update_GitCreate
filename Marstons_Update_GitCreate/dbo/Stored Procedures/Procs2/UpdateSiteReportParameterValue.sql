CREATE PROCEDURE dbo.UpdateSiteReportParameterValue
(
	@EDISID		INTEGER,
	@ReportID		INTEGER,
	@ParameterID		INTEGER,
	@ParameterValue	VARCHAR(255)
) 
AS

UPDATE dbo.ReportParameters
SET ParameterValue = @ParameterValue
WHERE EDISID = @EDISID
AND ReportID = @ReportID
AND ParameterID = @ParameterID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteReportParameterValue] TO PUBLIC
    AS [dbo];

