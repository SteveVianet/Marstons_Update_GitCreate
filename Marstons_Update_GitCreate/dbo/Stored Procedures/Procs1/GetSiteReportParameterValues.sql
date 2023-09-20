CREATE PROCEDURE [dbo].[GetSiteReportParameterValues]
(
	@EDISID		INTEGER,
	@ReportID	INTEGER = NULL
) 
AS

SELECT EDISID,
	 ReportID,
	 ParameterID,
	 ParameterValue
FROM dbo.ReportParameters
WHERE EDISID = @EDISID
AND ( (ReportID = @ReportID) OR (@ReportID IS NULL) )

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteReportParameterValues] TO PUBLIC
    AS [dbo];

