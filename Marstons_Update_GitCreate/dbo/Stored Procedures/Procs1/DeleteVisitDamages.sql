CREATE PROCEDURE dbo.DeleteVisitDamages
(
	@DamagesID 	INTEGER
)

AS


UPDATE dbo.VisitDamages
SET DamagesType = 99
WHERE DamagesID = @DamagesID

--DELETE
--FROM dbo.VisitDamages
--WHERE DamagesID = @DamagesID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteVisitDamages] TO PUBLIC
    AS [dbo];

