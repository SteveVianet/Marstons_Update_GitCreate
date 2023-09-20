CREATE PROCEDURE [dbo].[CleanUpProposedFontSetups]
AS

-- Delete blank job sheets (created by accident)
DELETE
FROM ProposedFontSetups
WHERE ID NOT IN (
	SELECT ProposedFontSetupID
	FROM ProposedFontSetupItems
	GROUP BY ProposedFontSetupID
)
AND Comment IS NULL
AND CallID IS NULL
AND DATEDIFF(Day, CreateDate, GETDATE()) > 14

-- Anything completed should really be available too
UPDATE ProposedFontSetups
SET Available = 1
WHERE Completed = 1 AND Available = 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[CleanUpProposedFontSetups] TO PUBLIC
    AS [dbo];

