CREATE PROCEDURE ProcVendorAnalysisTreatmentTypes
AS
BEGIN
    DELETE FROM [ProjNike].[dbo].[VendorAnalysisOnTreatmentTypeData];
    WITH RecentTrips AS (
    SELECT TOP (20)
        b.[MemberId],
        a.[Driver_Id],
        MAX(a.[DateOfService]) AS LastTripDate,
        COUNT(*) AS TripCount
    FROM 
        [ReportingStaging].[ctc].[OnSceneInfo_Lyft] a 
    LEFT JOIN 
        [CalltheCar-HC].[dbo].[Trip] b 
    ON 
        a.[CTCTripId] = b.[TripId]
    WHERE 
        a.[Status] NOT IN ('canceled', 'failed')
    GROUP BY 
        b.[MemberId], 
        a.[Driver_Id]
    ORDER BY TripCount DESC
	)
	INSERT INTO 
		[ProjNike].[dbo].[VendorAnalysisOnTreatmentTypeData]
	SELECT
		e.[MemberId],
		a.[CTCRideId],
		CAST(b.[DateOfService] AS DATE) AS [DateOfService],
		d.[TreatmentTypeName],
		a.[Driver_Id],
		a.[Driver_FirstName] as 'DriverName',
		a.[ActualPickup_Address],
		a.[ActualDropoff_Address],
		CAST(a.[DistanceMiles] AS FLOAT) AS [DistanceMiles],
		a.[Price_Amount],
		CAST(a.[RequestedPickup_Lat] AS FLOAT) AS [RequestedPickup_Lat],
		CAST(a.[RequestedPickup_Lng] AS FLOAT) AS [RequestedPickup_Lng],
		CAST(a.[RequestedDropoff_Lat] AS FLOAT) AS [RequestedDropoff_Lat],
		CAST(a.[RequestedDropoff_Lng] AS FLOAT) AS [RequestedDropoff_Lng],
		a.[RideType] as [Vendor],
		a.[Driver_ImageUrl] as 'DriverImage'
	--INTO 
	--	[ProjNike].[dbo].[VendorAnalysisOnTreatmentTypeData]
	FROM 
		[ReportingStaging].[ctc].[OnSceneInfo_Lyft] a
	LEFT JOIN 
		[CalltheCar-HC].[dbo].[Trip] b
	ON 
		a.[CTCTripId] = b.[TripId]
	LEFT JOIN
		[CalltheCar-HC].[dbo].[Tripleg] c
	ON
		a.[CTCTripLegId] = c.[TripLegId]
	LEFT JOIN
		[CalltheCar-HC].[dbo].[TreatmentType] d
	ON
		c.[TreatmentTypeId] = d.[TreatmentTypeId]
	LEFT JOIN
		[CalltheCar-HC].[dbo].[MemberInfo] e
	ON
		b.[MemberId] = e.[Id]
	WHERE 
		b.[MemberId] IN (SELECT MemberId FROM RecentTrips WHERE LastTripDate >= DATEADD(MONTH, -15, GETDATE())) AND 
		a.[Status] NOT IN ('canceled', 'failed')
	ORDER BY 
		b.[DateOfService] DESC, a.[CTCRideId];
	WITH RecentTrips AS (
    SELECT TOP (20)
        b.[MemberId],
        a.[driver.id],
        MAX(a.[begin_trip_time]) AS LastTripDate,
        COUNT(*) AS TripCount
    FROM 
        [CITS].[core].[UberData] a 
    LEFT JOIN 
        [CalltheCar-HC].[dbo].[Trip] b 
	ON CASE 
        WHEN CHARINDEX('-', a.[expense_memo], CHARINDEX('-', a.[expense_memo]) + 1) > 0 
        THEN LEFT(a.[expense_memo], CHARINDEX('-', a.[expense_memo], CHARINDEX('-', a.[expense_memo]) + 1) - 1)
        ELSE a.[expense_memo]
		END = b.[TripNo]
	WHERE 
		a.[status] = 'completed'
	GROUP BY 
		b.[MemberId], 
		a.[driver.id]
	ORDER BY 
		TripCount DESC
	)
	INSERT INTO 
		[ProjNike].[dbo].[VendorAnalysisOnTreatmentTypeData]
	SELECT
		c.[MemberId],
		a.[expense_memo] as 'CTCRideId',
		CAST(a.[begin_trip_time] AS DATE) AS [DateOfService],
		e.[TreatmentTypeName],
		a.[driver.id] as 'Driver_Id',
		a.[driver.name] as 'DriverName',
		a.[pickup.address] as [ActualPickup_Address],
		a.[destination.address] as [ActualDropoff_Address],
		CAST(a.[trip_distance_miles] AS FLOAT) AS [DistanceMiles],
		a.[client_fare_numeric] as [Price_Amount],
		CAST(a.[pickup.latitude] AS FLOAT) AS [RequestedPickup_Lat],
		CAST(a.[pickup.longitude] AS FLOAT) AS [RequestedPickup_Lng],
		CAST(a.[destination.latitude] AS FLOAT) AS [RequestedDropoff_Lat],
		CAST(a.[destination.longitude] AS FLOAT) AS [RequestedDropoff_Lng],
		a.[product.display_name] as [Vendor],
		a.[driver.picture_url] as 'DriverImage'
	FROM 
		[CITS].[core].[UberData] a
	LEFT JOIN 
		[CalltheCar-HC].[dbo].[Trip] b
	ON 
		CASE WHEN CHARINDEX('-', a.[expense_memo], CHARINDEX('-', a.[expense_memo]) + 1) > 0 THEN LEFT(a.[expense_memo], CHARINDEX('-', a.[expense_memo], CHARINDEX('-', a.[expense_memo]) + 1) - 1) ELSE a.[expense_memo] END = b.[TripNo]
	LEFT JOIN
		[CalltheCar-HC].[dbo].[MemberInfo] c
	ON
		b.[MemberId]=c.[Id]
	LEFT JOIN
		[CalltheCar-HC].[dbo].[Tripleg] d
	ON
		b.[TripId]=d.[TripId]
	LEFT JOIN
		[CalltheCar-HC].[dbo].[TreatmentType] e
	ON
		d.[TreatmentTypeId]=e.[TreatmentTypeId]
	WHERE 
		b.[MemberId] IN (SELECT MemberId FROM RecentTrips WHERE LastTripDate >= DATEADD(MONTH, -15, GETDATE())) AND 
		a.[status] = 'completed'
	ORDER BY 
		a.[begin_trip_time] DESC, a.[expense_memo];
END;