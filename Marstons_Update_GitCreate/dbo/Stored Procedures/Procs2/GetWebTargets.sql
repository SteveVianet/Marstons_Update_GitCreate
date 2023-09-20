CREATE PROCEDURE [dbo].[GetWebTargets]
(
	@GetCustomerTargets		BIT = 1,
	@GetProductTargets		BIT = 1
)
AS

DECLARE @Master BIT = 1

IF @GetCustomerTargets = 1
BEGIN
	SELECT 
		CASE WHEN ISNUMERIC(TargetTillYield.Value) = 1 THEN CAST(TargetTillYield.Value AS INT) ELSE NULL END AS TargetTillYield, 
		CASE WHEN ISNUMERIC(TargetQualityOutOfSpec.Value) = 1 THEN CAST(TargetQualityOutOfSpec.Value AS INT) ELSE NULL END AS TargetQualityOutOfSpec, 
		CASE WHEN ISNUMERIC(TargetCleaningOutOfSpec.Value) = 1 THEN CAST(TargetCleaningOutOfSpec.Value AS INT) ELSE NULL END AS TargetCleaningOutOfSpec, 
		CASE WHEN ISNUMERIC(TargetEquipmentAlerts.Value) = 1 THEN CAST(TargetEquipmentAlerts.Value AS INT) ELSE NULL END AS TargetEquipmentAlerts, 
		CASE WHEN ISNUMERIC(TargetLowThroughputLines.Value) = 1 THEN CAST(TargetLowThroughputLines.Value AS INT) ELSE NULL END AS TargetLowThroughputLines, 
		CASE WHEN ISNUMERIC(TargetManagementEngagement.Value) = 1 THEN CAST(TargetManagementEngagement.Value AS INT) ELSE NULL END AS TargetManagementEngagement, 
		CASE WHEN ISNUMERIC(TargetTenantEngagement.Value) = 1 THEN CAST(TargetTenantEngagement.Value AS INT) ELSE NULL END AS TargetTenantEngagement
	FROM
		(SELECT @Master AS Value) AS MasterValue
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetTillYield') AS TargetTillYield ON 1=1
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetQualityOutOfSpec') AS TargetQualityOutOfSpec ON 1=1
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetCleaningOutOfSpec') AS TargetCleaningOutOfSpec ON 1=1
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetEquipmentAlerts') AS TargetEquipmentAlerts ON 1=1
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetLowThroughputLines') AS TargetLowThroughputLines ON 1=1
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetManagementEngagement') AS TargetManagementEngagement ON 1=1
	LEFT JOIN
		(SELECT PropertyValue AS Value FROM Configuration WHERE PropertyName = 'TargetTenantEngagement') AS TargetTenantEngagement ON 1=1
END

IF @GetProductTargets = 1	
BEGIN
	SELECT 
		ID, 
		[Description] AS CategoryName,
		TargetPouringYield
	FROM 
		ProductCategories
	WHERE
		IncludeInEstateReporting = 1
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebTargets] TO PUBLIC
    AS [dbo];

