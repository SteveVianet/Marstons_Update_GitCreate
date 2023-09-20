CREATE PROCEDURE dbo.AddSiteReportParameterValue
(
	@EDISID		INTEGER,
	@ReportID		INTEGER,
	@ParameterID		INTEGER,
	@ParameterValue	VARCHAR(255)
) 
AS

INSERT INTO dbo.ReportParameters
(EDISID, ReportID, ParameterID, ParameterValue)
VALUES
(@EDISID, @ReportID, @ParameterID, @ParameterValue)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteReportParameterValue] TO PUBLIC
    AS [dbo];

