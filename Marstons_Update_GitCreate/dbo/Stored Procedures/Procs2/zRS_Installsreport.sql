CREATE PROCEDURE [dbo].[zRS_Installsreport]

(

      @From                 DATETIME,

      @To                   DATETIME

)

AS

SELECT     dbo.Configuration.PropertyValue AS Company, dbo.GetCallReference(dbo.Calls.ID) AS Callref, dbo.Calls.RaisedOn, dbo.Calls.RaisedBy,

                      CASE WHEN dbo.Calls.PriorityID = 1 THEN 'Standard' ELSE 'High' END AS Priority,

                      CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasons(Calls.ID) ELSE '' END AS CallReasonType, dbo.Sites.SiteID, dbo.Sites.Name,

                      dbo.Sites.PostCode, dbo.Calls.PlanningIssueID, dbo.Calls.ClosedOn, dbo.Calls.SalesReference, dbo.Calls.AuthCode,

                      GlobalCallType.Description AS GlobalCallType, CASE WHEN dbo.Sites.Quality = 1 THEN 'iDraught' ELSE 'Standard' END AS Systemtype,

                      dbo.ModemTypes.Description AS Commstype, dbo.Contracts.Description AS Contractname, InstallNewPanelQuantity, InstallRefurbPanelQuantity,

                      NewMetersQuantity, RefurbMetersQuantity, Socketinstalled, Transfersocket, ProvidedCleanSecure, CabledBarCellar, BarsCabled, Clearedglasses,

                      AmbientSensors, RecircMeters, LaggedLines, EstimatedLabourMinutes, DATEDIFF(MINUTE, Calls.VisitStartedOn, dbo.Calls.VisitEndedOn)

                      AS ActualTimeOnSite, CASE WHEN Calls.InvoicedOn IS NOT NULL THEN 1 ELSE 0 END AS Checked, Engineers.Name AS Engineer,

                      CASE WHEN OpenSiteInstalls.EDISID IS NOT NULL OR

                      InstallsClosedAfterTo.EDISID IS NOT NULL THEN 1 ELSE 0 END AS OpenInstallForThisSite, dbo.Owners.Name AS Owners, Calls.InstallCallID

FROM         dbo.Calls LEFT OUTER JOIN

                      dbo.CallReasons ON dbo.CallReasons.CallID = dbo.Calls.ID LEFT OUTER JOIN

                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON

                      dbo.CallReasons.ReasonTypeID = GlobalCallReasonTypes.ID LEFT OUTER JOIN

                      dbo.Sites ON dbo.Calls.EDISID = dbo.Sites.EDISID LEFT OUTER JOIN

                      [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS GlobalCallType ON dbo.Calls.CallCategoryID = GlobalCallType.ID INNER JOIN

                      dbo.Configuration ON dbo.Configuration.PropertyName = 'Company Name' INNER JOIN

                      dbo.ModemTypes ON dbo.Sites.ModemTypeID = dbo.ModemTypes.ID INNER JOIN

                      dbo.Contracts ON dbo.Calls.ContractID = dbo.Contracts.ID INNER JOIN

                      [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.ID = Calls.EngineerID INNER JOIN

                      dbo.Owners ON dbo.Sites.OwnerID = dbo.Owners.ID

LEFT JOIN

(

      SELECT      CallID,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN ( 32,125) THEN Quantity ELSE 0 END) AS InstallNewPanelQuantity,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (31,124)  THEN Quantity ELSE 0 END) AS InstallRefurbPanelQuantity,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (37, 38, 39, 40,129) THEN Quantity ELSE 0 END) AS NewMetersQuantity,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (35,36,126,127,128) THEN Quantity ELSE 0 END) AS RefurbMetersQuantity,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (24) THEN Quantity ELSE 0 END) AS Socketinstalled,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (25) THEN Quantity ELSE 0 END) AS Transfersocket,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (26,27) THEN Quantity ELSE 0 END) AS ProvidedCleanSecure,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (47) THEN Quantity ELSE 0 END) AS CabledBarCellar,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (48) THEN Quantity ELSE 0 END) AS BarsCabled,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (49) THEN Quantity ELSE 0 END) AS Clearedglasses,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (63) THEN Quantity ELSE 0 END) AS AmbientSensors,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (65,145) THEN Quantity ELSE 0 END) AS RecircMeters,

                        SUM(LabourMinutes) AS EstimatedLabourMinutes,

                        SUM(CASE WHEN CallBillingItems.BillingItemID IN (94) THEN Quantity ELSE 0 END) AS LaggedLines

      FROM CallBillingItems

      GROUP BY CallID

) AS CallQuantities ON CallQuantities.CallID = Calls.[ID]

LEFT JOIN

(

      SELECT EDISID, InstallCallID

      FROM Calls

      JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]

      JOIN (      SELECT CallID, MAX([ID]) AS LastStatusID

                  FROM CallStatusHistory

                  GROUP BY CallID) AS LastCallStatus ON LastCallStatus.LastStatusID = CallStatusHistory.[ID]

      WHERE CallStatusHistory.StatusID <> 4

      AND CallCategoryID = 4

      AND Calls.AbortReasonID = 0 AND Calls.UseBillingItems = 1

      GROUP BY EDISID, InstallCallID

) AS OpenSiteInstalls ON OpenSiteInstalls.EDISID = Sites.EDISID AND OpenSiteInstalls.InstallCallID = Calls.InstallCallID

LEFT JOIN

(

         SELECT Calls.EDISID, Calls.InstallCallID, MIN(ClosedOn) AS Phase1Closed

         FROM Calls

         JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]

      JOIN (      SELECT CallID, MAX([ID]) AS LastStatusID

                  FROM CallStatusHistory

                  GROUP BY CallID) AS LastCallStatus ON LastCallStatus.LastStatusID = CallStatusHistory.[ID]

      JOIN CallReasons ON CallReasons.CallID = Calls.[ID]

      JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes ON CallReasonTypes.[ID] = CallReasons.ReasonTypeID

      WHERE CallStatusHistory.StatusID = 4

         AND Calls.AbortReasonID = 0

         AND InstallCallID IS NOT NULL

         GROUP BY Calls.EDISID, Calls.InstallCallID

) AS Phase1Installs ON Phase1Installs.EDISID = Sites.EDISID AND Phase1Installs.InstallCallID = Calls.InstallCallID

LEFT JOIN

(

      SELECT EDISID, InstallCallID

      FROM Calls

      JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]

      JOIN (      SELECT CallID, MAX([ID]) AS LastStatusID

                  FROM CallStatusHistory

                  GROUP BY CallID) AS LastCallStatus ON LastCallStatus.LastStatusID = CallStatusHistory.[ID]

      WHERE CallStatusHistory.StatusID = 4

      AND CallCategoryID = 4

      AND Calls.AbortReasonID = 0 AND Calls.UseBillingItems = 1

      AND ClosedOn > DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

      GROUP BY EDISID, InstallCallID

) AS InstallsClosedAfterTo ON InstallsClosedAfterTo.EDISID = Sites.EDISID AND InstallsClosedAfterTo.InstallCallID = Calls.InstallCallID

WHERE     (dbo.Calls.AbortReasonID = 0) AND (dbo.Calls.ClosedOn BETWEEN ISNULL(Phase1Closed, @From) AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))) AND (dbo.Calls.UseBillingItems = 1)

AND Calls.CallCategoryID IN (4, 6, 9)

AND Calls.EDISID IN

(

      SELECT EDISID

      FROM Calls

      WHERE Calls.CallCategoryID IN (4, 6, 9)

      AND (Calls.ClosedOn BETWEEN @From AND  DATEADD(SECOND, -1, DATEADD(DAY, 1, @To)))

      AND Calls.AbortReasonID = 0

      AND Calls.UseBillingItems = 1

         --AND InstallCallID IS NOT NULL

)

GROUP BY Configuration.PropertyValue, GlobalCallType.Description,dbo.GetCallReference(Calls.ID), dbo.Calls.RaisedOn, dbo.Calls.RaisedBy, dbo.Calls.PriorityID, dbo.udfConcatCallReasons(Calls.ID), dbo.Sites.SiteID,

                      dbo.Sites.Name, dbo.Sites.PostCode, Calls.UseBillingItems, dbo.Calls.PlanningIssueID, dbo.Calls.AbortReasonID, dbo.Calls.ClosedOn,  dbo.Calls.SalesReference, dbo.Calls.AuthCode,

                     dbo.Sites.Quality,dbo.ModemTypes.Description,dbo.Contracts.Description,

                     InstallNewPanelQuantity,

                                InstallRefurbPanelQuantity,

                                NewMetersQuantity,

                                RefurbMetersQuantity,

                                Socketinstalled,

                                Transfersocket,

                                ProvidedCleanSecure,

                                CabledBarCellar,

                                BarsCabled,

                                Clearedglasses,

                                AmbientSensors,

                                RecircMeters,

                                EstimatedLabourMinutes,

                                LaggedLines,

                                DATEDIFF(MINUTE, Calls.VisitStartedOn, VisitEndedOn),

                                CASE WHEN Calls.InvoicedOn IS NOT NULL THEN 1 ELSE 0 END,

                                Engineers.Name,

                                CASE WHEN OpenSiteInstalls.EDISID IS NOT NULL OR InstallsClosedAfterTo.EDISID IS NOT NULL THEN 1 ELSE 0 END,dbo.Owners.Name, Calls.InstallCallID

ORDER BY SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_Installsreport] TO PUBLIC
    AS [dbo];

