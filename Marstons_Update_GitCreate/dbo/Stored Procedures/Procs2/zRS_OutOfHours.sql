CREATE PROCEDURE [dbo].[zRS_OutOfHours]


(
      @From DATETIME = NULL,
      @To         DATETIME = NULL
)
AS

SET NOCOUNT ON

SET DATEFIRST 1         

SELECT      Sites.SiteID                                                                                                AS    [SiteID]    
      ,     Sites.Name                                                                                                  AS    [Site Name] 
      ,     Disp.WC
      ,     Disp.Date

      ,     Disp.Shift                                                                                                                                                                                                        
      ,     Disp.[Dispensed Pints]                                                                             AS    [TotalDisp]
      ,     Hidden
      
FROM  Sites


RIGHT  JOIN(      

            Select      MasterDates.EDISID                  
                  ,     DATEADD(dd, -(DATEPART(dw, MasterDates.[Date])-1), MasterDates.[Date])           AS    [WC]  
                  ,     MasterDates.[Date]    -1                                                                                      AS    [Date]
                  ,     [DLData].[Shift]-1                                                                                          AS    [Shift]                 
                  ,     SUM  (DLData.Quantity)                                                                               AS    [Dispensed Pints]


            FROM DLData

                  JOIN MasterDates       ON MasterDates.ID = DLData.DownloadID

                  WHERE MasterDates.[Date] between @From AND @To
                  
                  AND Shift IN (3,4,5,6) And (DLData.Quantity)  >0.1
                  
                                          
                  GROUP BY                
                  EDISID      
                  ,     DATEADD(dd, -(DATEPART(dw, MasterDates.[Date])-1), MasterDates.[Date])                 -- WEEK
                  ,     [DLData].[Shift]
                  ,     MasterDates.[Date]
                                                                                          
                  
      ) AS Disp         ON    Sites.EDISID      =     Disp.EDISID
      


      

            GROUP BY                
            Sites.SiteID                  
      ,     Sites.Name
      ,     Disp.WC
      ,     Disp.Date

      ,     Disp.Shift
      ,     Disp.[Dispensed Pints]
      ,     Hidden
                  
            
            ORDER BY
            SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_OutOfHours] TO PUBLIC
    AS [dbo];

