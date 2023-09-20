CREATE
 PROCEDURE [dbo].[zRS_CDBarrelCharge] AS
SET
 NOCOUNT ON SELECT
 PropertyName
,PropertyValue FROM
 Configuration 
 WHERE PropertyName = 'Calculated Deficit Cash Value'
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_CDBarrelCharge] TO PUBLIC
    AS [dbo];

