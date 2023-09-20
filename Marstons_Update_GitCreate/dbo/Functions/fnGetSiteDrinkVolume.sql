CREATE FUNCTION [dbo].[fnGetSiteDrinkVolume]
(
      @EDISID             INT,
      @PercentageOfPint   FLOAT,
      @ProductID          INT
)

RETURNS FLOAT

AS

BEGIN
	DECLARE @Drinks                     FLOAT
	DECLARE @DrinkParameter             INT
	DECLARE @IsCask                     INT
	DECLARE @ProductCategoryID          INT
	DECLARE @ProductCategoryName	    VARCHAR(50)
	DECLARE @PercentageOfLitre          FLOAT
	DECLARE @VolumeUSFlOz               FLOAT

	/*
	
	Get site drink actions type from site property "Drink Actions Parameter"

	Key:
	
	NULL (site property not set) defaults to standard (pints)

	       1 = Standard (pints)
            2 = No drink actions supported - use actual volume
            3 = Stnd Europe (CL)
            4 = Czech (CL)
            5 = US Fl OZ (Chillis 8 & 16)
            6 = US Fl OZ (Flatbread 16 and Pitcher)
            7 = US Fl OZ (Texas Roadhouse)
            8 = US Fl OZ (AMC)
            9 = US Fl OZ (Hard Rock Cafe)
            10 = US Fl OZ (Chillis v2 13 & 19)
            11 = US Fl OZ (AMC Disney)
            12 = US FL OZ (BWW)
            13 = US Fl OZ (AMC Arlington)
            14 = US FL OZ (Native New Yorker)
            15 = US Fl OZ (Zipps)
            16 = US Fl OZ (Hard Rock Cafe UK)
            17 = US Fl OZ (AMC 2)
            18 = US Fl OZ (AMC 10 sites with 1 and 18)
            19 = US Fl OZ (AMC 28.5)
            20 = US Fl OZ (US1828.5)
            21 = US Fl Oz (Chickies)
            22 = US Fl oz (Matador)
            23 = US Fl oz (Hornet)
            24 = US Fl oz (Darden)
            25 = US Fl oz (Little Pub Co Patrick Carrols)
            26 = US Fl OZ (AbInbev Busch Stadium)
            27 = US Fl OZ (AMC New 24oz Cup Size Ã¢â‚¬â€œ Based on parameter 19 but with 24 oz addition)
            28 = US Fl OZ (Mellow Mushroom Sites)
            29 = US Fl OZ (Whiskey Tango Foxtrot)
            30 = US Fl OZ (Angry Ginger)
            31 = US Fl OZ (Mandeville Beer Garden)
            32 = US Fl OZ (Flatbread Somerville)
            33 = US Fl OZ (AMC Angry Orchard LTO - SITES PREVIOUSLY ON D.A.P 17)
            34 = US Fl OZ (AMC Angry Orchard LTO - SITES PREVIOUSLY ON D.A.P 19)
            35 = US Fl OZ (AMC Angry Orchard LTO - SITES PREVIOUSLY ON D.A.P 27)
            36 = US Fl OZ (Marble Brewery)
            37 = US Fl OZ (Reed & Greenough)
            38 = US Fl OZ (Flatbread Portland)
            39 = US Fl OZ (BlackBird (AKA Manito Tap House))
            40 = US Fl Oz (Norwegian Cruise Lines)
            41 = US Fl Oz (Taos Mesa Brewing Company)
            42 = US Fl Oz (Texas Roadhouse (Bubba 33))
            43 = US Fl Oz (Tavern Hospitality - Tavern Downtown)
            44 = US Fl Oz (Biergarten)
            45 = US Fl Oz (Tavern Hospitality - Platt Park)
            46 = US Fl Oz (The Dudes Brewing Company)
            47 = US Fl Oz (Levy Restaurants Chase Field)
            48 = US Fl Oz (Boston's Gourmet Pizza)
            49 = US Fl Oz (Boston's Gourmet Pizza - Irving)
            50 = US Fl Oz (Brixx Pizza Cincinnati)
            51 = US Fl Oz (Real Mex - Chevy's)
            52 = US Fl Oz (Real Mex - El Torito)
            53 = (Worlds End Tank Beer)
            54 = US Fl Oz (Chilis Deland)
            55 = US Fl Oz (Outback Steakhouse)
            56 = US Fl Oz (Chilis Land O Lakes)
            57 = (St Austell - Samuel Jones)
            58 = (St Austell - Samples 1/10 Pints)
            59 = (Brewhouse & Kitchen)
	*/

	SELECT @DrinkParameter = CAST(SiteProperties.Value AS INTEGER)
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE EDISID = @EDISID
	AND Properties.[Name] = 'Drink Actions Parameter'

	-- Get Product Category and IsCask values
	SELECT  @IsCask = IsCask,
			  @ProductCategoryID = CategoryID,
			  @ProductCategoryName = dbo.ProductCategories.[Description]
	FROM dbo.Products
	JOIN dbo.ProductCategories ON dbo.ProductCategories.ID = dbo.Products.CategoryID
	WHERE dbo.Products.[ID] = @ProductID

	--Convert from incoming dispense volume from pints to litres first
	SET @PercentageOfLitre = ((@PercentageOfPint / 100) * 568.261485) / 10
	SET @VolumeUSFlOz = (@PercentageOfPint / 100)* 19.2152

	IF @DrinkParameter = 1 OR @DrinkParameter IS NULL
	BEGIN
		--Start of type 1---------------------------------------------------------------------------------
		IF UPPER(@ProductCategoryName) LIKE '%STANDARD LAGER%'
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 15 THEN 0.0
			  WHEN @PercentageOfPint <= 33 THEN 0.25
			  WHEN @PercentageOfPint <= 62 THEN 0.5
			  WHEN @PercentageOfPint <= 80 THEN 0.75
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 135 THEN 1.25
			  WHEN @PercentageOfPint <= 164 THEN 1.5
			  WHEN @PercentageOfPint <= 220 THEN 2
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 310 THEN 3
			  WHEN @PercentageOfPint <= 321 THEN 3.25
			  WHEN @PercentageOfPint <= 360 THEN 3.5
			  WHEN @PercentageOfPint <= 420 THEN 4
			  WHEN @PercentageOfPint <= 470 THEN 4.5
			  WHEN @PercentageOfPint <= 520 THEN 5
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )

		ELSE IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 15 THEN 0.0
			  WHEN @PercentageOfPint <= 33 THEN 0.25
			  WHEN @PercentageOfPint <= 61 THEN 0.5
			  WHEN @PercentageOfPint <= 80 THEN 0.75
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 130 THEN 1.25
			  WHEN @PercentageOfPint <= 169 THEN 1.5
			  WHEN @PercentageOfPint <= 215 THEN 2
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 310 THEN 3
			  WHEN @PercentageOfPint <= 370 THEN 3.5
			  WHEN @PercentageOfPint <= 410 THEN 4
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
	    
		ELSE IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 15 THEN 0.0
			  WHEN @PercentageOfPint <= 30 THEN 0.25
			  WHEN @PercentageOfPint <= 63 THEN 0.5
			  WHEN @PercentageOfPint <= 80 THEN 0.75
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 130 THEN 1.25
			  WHEN @PercentageOfPint <= 160 THEN 1.5
			  WHEN @PercentageOfPint <= 220 THEN 2
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 310 THEN 3
			  WHEN @PercentageOfPint <= 335 THEN 3.25
			  WHEN @PercentageOfPint <= 360 THEN 3.5
			  WHEN @PercentageOfPint <= 420 THEN 4
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
	    
		ELSE IF UPPER(@ProductCategoryName) LIKE '%ALE - KEG%'
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 15 THEN 0.0
			  WHEN @PercentageOfPint <= 36 THEN 0.25
			  WHEN @PercentageOfPint <= 59 THEN 0.5
			  WHEN @PercentageOfPint <= 86 THEN 0.75
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 130 THEN 1.25
			  WHEN @PercentageOfPint <= 155 THEN 1.5
			  WHEN @PercentageOfPint <= 180 THEN 1.75
			  WHEN @PercentageOfPint <= 210 THEN 2
			  WHEN @PercentageOfPint <= 230 THEN 2.25
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 310 THEN 3
			  WHEN @PercentageOfPint <= 320 THEN 3.25
			  WHEN @PercentageOfPint <= 360 THEN 3.5
			  WHEN @PercentageOfPint <= 420 THEN 4
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
	    
		ElSE IF UPPER(@ProductCategoryName) LIKE '%ALE - CASK%'
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 15 THEN 0.0
			  WHEN @PercentageOfPint <= 34 THEN 0.25
			  WHEN @PercentageOfPint <= 59 THEN 0.5
			  WHEN @PercentageOfPint <= 85 THEN 0.75
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 129 THEN 1.25
			  WHEN @PercentageOfPint <= 155 THEN 1.5
			  WHEN @PercentageOfPint <= 173 THEN 1.75
			  WHEN @PercentageOfPint <= 230 THEN 2
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 310 THEN 3
			  WHEN @PercentageOfPint <= 335 THEN 3.25
			  WHEN @PercentageOfPint <= 360 THEN 3.5
			  WHEN @PercentageOfPint <= 420 THEN 4
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
	          
		ELSE IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 15 THEN 0.0
			  WHEN @PercentageOfPint <= 34 THEN 0.25
			  WHEN @PercentageOfPint <= 59 THEN 0.5
			  WHEN @PercentageOfPint <= 81 THEN 0.75
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 131 THEN 1.25
			  WHEN @PercentageOfPint <= 169 THEN 1.5
			  WHEN @PercentageOfPint <= 180 THEN 1.75
			  WHEN @PercentageOfPint <= 230 THEN 2
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 310 THEN 3
			  WHEN @PercentageOfPint <= 335 THEN 3.25
			  WHEN @PercentageOfPint <= 360 THEN 3.5
			  WHEN @PercentageOfPint <= 320 THEN 4
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
	    
		ELSE
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfPint <= 22 THEN 0.0
			  WHEN @PercentageOfPint <= 27 THEN 0.25
			  WHEN @PercentageOfPint <= 68 THEN 0.5
			  WHEN @PercentageOfPint <= 120 THEN 1
			  WHEN @PercentageOfPint <= 170 THEN 1.5
			  WHEN @PercentageOfPint <= 220 THEN 2
			  WHEN @PercentageOfPint <= 260 THEN 2.5
			  WHEN @PercentageOfPint <= 320 THEN 3
			  WHEN @PercentageOfPint <= 330 THEN 3.5
			  WHEN @PercentageOfPint <= 420 THEN 4
			  WHEN @PercentageOfPint <= 440 THEN 4.5
			  WHEN @PercentageOfPint <= 510 THEN 5
			  WHEN @PercentageOfPint <= 550 THEN 5.5
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )

		--End of type 1---------------------------------------------------------------------------------

	END

	ELSE IF @DrinkParameter = 2
	BEGIN
		--Start of type 2---------------------------------------------------------------------------------
		SELECT @Drinks = @PercentageOfPint / 100
		--End of type 2-----------------------------------------------------------------------------------
	    
	END

	ELSE IF @DrinkParameter = 3
	BEGIN
		--Start of type 3---------------------------------------------------------------------------------

		--If product category is Stout then do this check (for Guinness, Murphys etc)

		IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
		BEGIN
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfLitre <= 6 THEN 0    
			  WHEN @PercentageOfLitre <= 19.5 THEN 0.25
			  WHEN @PercentageOfLitre <= 30 THEN 0.5
			  WHEN @PercentageOfLitre <= 44 THEN 0.75
			  WHEN @PercentageOfLitre <= 60 THEN 1
			  WHEN @PercentageOfLitre <= 69 THEN 1.25
			  WHEN @PercentageOfLitre <= 85.5 THEN 1.5
			  WHEN @PercentageOfLitre <= 114.5 THEN 2
			  WHEN @PercentageOfLitre <= 135.5 THEN 2.5
			  WHEN @PercentageOfLitre <= 172 THEN 3
			  WHEN @PercentageOfLitre <= 182.5 THEN 3.5
			  WHEN @PercentageOfLitre <= 223 THEN 4
			  WHEN @PercentageOfLitre <= 240 THEN 4.5
			  WHEN @PercentageOfLitre <= 270 THEN 5
			  WHEN @PercentageOfLitre <= 287.5 THEN 5.5
			  WHEN @PercentageOfLitre <= 316.5 THEN 6
			  WHEN @PercentageOfLitre <= 335 THEN 6.5
			  WHEN @PercentageOfLitre <= 375 THEN 7
			  WHEN @PercentageOfLitre <= 425 THEN 8
			  WHEN @PercentageOfLitre <= 490 THEN 9
			  WHEN @PercentageOfLitre <= 545 THEN 10
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
		END

		ELSE
		BEGIN
			  SELECT @Drinks = (
			  CASE  
			  WHEN @PercentageOfLitre <= 10 THEN 0    
			  WHEN @PercentageOfLitre <= 35 THEN 0.5  
			  WHEN @PercentageOfLitre <= 70 THEN 1
			  WHEN @PercentageOfLitre <= 80 THEN 1.5
			  WHEN @PercentageOfLitre <= 105 THEN 2    
			  WHEN @PercentageOfLitre <= 131 THEN 2.5      
			  WHEN @PercentageOfLitre <= 155 THEN 3
			  WHEN @PercentageOfLitre <= 180 THEN 3.5
			  WHEN @PercentageOfLitre <= 205 THEN 4
			  WHEN @PercentageOfLitre <= 230 THEN 4.5 
			  WHEN @PercentageOfLitre <= 250 THEN 5
			  WHEN @PercentageOfLitre <= 307 THEN 6 
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			  END
			  )
		END

		--End of type 3-----------------------------------------------------------------------------------

	END

	ELSE IF @DrinkParameter = 4
	BEGIN
		--Start of type 4---------------------------------------------------------------------------------
		--15 cl is small unit
		--20 cl is Half spout
		--30 cl is medium
		--50 cl is standard unit

		--If product category is Spout (a unique Czech drink type)
		IF UPPER(@ProductCategoryName) LIKE '%SPOUT%'
		BEGIN
			  SELECT @Drinks = (
			  CASE
			  WHEN @PercentageOfLitre <= 15  THEN 0
			  WHEN @PercentageOfLitre <= 25 THEN 0.4  
			  WHEN @PercentageOfLitre <= 50 THEN 0.8   
			  WHEN @PercentageOfLitre <= 75 THEN 1.2
			  WHEN @PercentageOfLitre <= 110 THEN 2
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			  END
			  )

		END

		ELSE
		BEGIN
			  SELECT @Drinks = (
			  CASE                                            
			  WHEN @PercentageOfLitre <= 20  THEN 0
			  WHEN @PercentageOfLitre <= 27  THEN 0.4
			  WHEN @PercentageOfLitre <= 36 THEN 0.6
			  WHEN @PercentageOfLitre <= 62 THEN 1   
			  WHEN @PercentageOfLitre <= 82 THEN 1.5
			  WHEN @PercentageOfLitre <= 115 THEN 2
			  WHEN @PercentageOfLitre <= 165 THEN 3
			  WHEN @PercentageOfLitre <= 205 THEN 4
			  WHEN @PercentageOfLitre <= 305 THEN 6
			  WHEN @PercentageOfLitre <= 355 THEN 7
			  WHEN @PercentageOfLitre <= 405 THEN 8
			  WHEN @PercentageOfLitre <= 455 THEN 9
			  WHEN @PercentageOfLitre <= 505 THEN 10
			  WHEN @PercentageOfLitre <= 555 THEN 11
			  WHEN @PercentageOfLitre <= 605 THEN 12
			  WHEN @PercentageOfLitre <= 655 THEN 13
			  WHEN @PercentageOfLitre <= 705 THEN 14
			  WHEN @PercentageOfLitre <= 755 THEN 15
			  ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			  END
			  )

		END

		--End of type 4-----------------------------------------------------------------------------------

	END

	ELSE IF @DrinkParameter = 5
    BEGIN 
		--Start of type 5 this is for Chillis---------------------------------------------------------------------------------
		---US flo oz 10 & 20 glass sizes - but these need to be shown as 8 and 16
 
		SELECT @Drinks = (
		CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0
			WHEN @VolumeUSFlOz <=14 THEN 8
			WHEN @VolumeUSFlOz <=25 THEN 16
			WHEN @VolumeUSFlOz <=30 THEN 24
			WHEN @VolumeUSFlOz <=45 THEN 32
			WHEN @VolumeUSFlOz <=55 THEN 40
			WHEN @VolumeUSFlOz <=65 THEN 48
			WHEN @VolumeUSFlOz <=75 THEN 56
			WHEN @VolumeUSFlOz <=85 THEN 64
			WHEN @VolumeUSFlOz <=95 THEN 72
			WHEN @VolumeUSFlOz <=115 THEN 80
			WHEN @VolumeUSFlOz <=135 THEN 96
			WHEN @VolumeUSFlOz <=150 THEN 112
			WHEN @VolumeUSFlOz <=250 THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	

	ELSE IF @DrinkParameter = 6
	BEGIN
		--Start of type 6 this is for Flatbread---------------------------------------------------------------------------------
		---US flo oz 16 glass sizes & Pitcher

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0  
			WHEN @VolumeUSFlOz <=9 THEN 6.5
			WHEN @VolumeUSFlOz <=17 THEN 13    
			WHEN @VolumeUSFlOz <=24 THEN 21               
			WHEN @VolumeUSFlOz <=32 THEN 26
			WHEN @VolumeUSFlOz <=38 THEN 32
			WHEN @VolumeUSFlOz <=50 THEN 48
			WHEN @VolumeUSFlOz <=64 THEN 64
			WHEN @VolumeUSFlOz <=100 THEN 72
			WHEN @VolumeUSFlOz <=300 THEN 0
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END


	ELSE IF @DrinkParameter = 7
	BEGIN
		--Start of type 7 this is for Texas roadhouse---------------------------------------------------------------------------------
		---US flo oz 10 & 20 glass sizes but to show as US flo oz 9 & 19 pour sizes

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0  
			WHEN @VolumeUSFlOz <=11 THEN 8.5 -- 10oz Drink (8.5oz target size)
			WHEN @VolumeUSFlOz <=17 THEN 14.5 -- 16oz Drink (14.5oz target size)
			WHEN @VolumeUSFlOz <=22 THEN 19.5 -- 20oz Drinks (19.5oz target size)
			WHEN @VolumeUSFlOz <=30 THEN 25.5 --3x 10oz Drinks (8.5 oz target size)
			WHEN @VolumeUSFlOz <=33 THEN 29 --2x 16oz Drinks (14.5oz target size)
			WHEN @VolumeUSFlOz <= 40 THEN 39 --2x 20oz Drinks (19.5oz target size)
			WHEN @VolumeUSFlOz <=50 THEN 43.5 --3x 16oz Drinks (14.5oz target size)
			WHEN @VolumeUSFlOz <=65 THEN 58.5 --3x 20oz Drinks (19.5oz target size)
			WHEN @VolumeUSFlOz <=82 THEN 78 --4x 20oz Drinks (19.5oz target size)
			WHEN @VolumeUSFlOz <=97 THEN 87 --6x 16oz Drinks (14.5oz target size)
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END


	ELSE IF @DrinkParameter = 8
	BEGIN
		--Start of type 8 this is for AMC---------------------------------------------------------------------------------
		---US flo oz 16 & Pitcher

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=28 THEN 18
			WHEN @VolumeUSFlOz <=38 THEN 36
			WHEN @VolumeUSFlOz <=42 THEN 39
			WHEN @VolumeUSFlOz <=65 THEN 52
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=120 THEN 104
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END


	ELSE IF @DrinkParameter = 9
	BEGIN
		--Start of type 9 this is for Hard Rock Cafe---------------------------------------------------------------------------------
		---US flo oz 13 & 17 & mo says no Pitcher

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0  
			WHEN @VolumeUSFlOz <=9.5 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=20 THEN 17
			WHEN @VolumeUSFlOz <=26 THEN 26
			WHEN @VolumeUSFlOz <=36 THEN 32
			WHEN @VolumeUSFlOz <=54 THEN 46
			WHEN @VolumeUSFlOz <=66 THEN 64
			WHEN @VolumeUSFlOz <=82 THEN 80
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	

ELSE IF @DrinkParameter = 10
                BEGIN
          --Start of type 10 this is for Chilis V2---------------------------------------------------------------------------------
          ---US flo oz Target Sizes are 13oz & 19oz - Glass Sizes are 16oz & 23oz 
		  
            SELECT @Drinks = (
               CASE
               WHEN @VolumeUSFlOz <= 5  THEN 0 
               WHEN @VolumeUSFlOz <=9 THEN 6
               WHEN @VolumeUSFlOz <=17 THEN 13 -- 1x 13oz pours
               WHEN @VolumeUSFlOz <=26 THEN 19 -- 1x 19oz pours
               WHEN @VolumeUSFlOz <=34 THEN 26 -- 2x 13oz pours
               WHEN @VolumeUSFlOz <=46 THEN 38 -- 2x 19oz pours (or 3x 13oz with 1oz variance)
               WHEN @VolumeUSFlOz <=70 THEN 57 -- 3x 19oz pours
               WHEN @VolumeUSFlOz <=92 THEN 76 -- 4x 19oz pours
               WHEN @VolumeUSFlOz <=120 THEN 95 -- 5x 19oz pours
               WHEN @VolumeUSFlOz <=140 THEN 114 -- 6x 19oz pours
               WHEN @VolumeUSFlOz <=160 THEN 133 -- 7x 19oz pours
               WHEN @VolumeUSFlOz <=180 THEN 152 -- 8x 19oz pours
               WHEN @VolumeUSFlOz <=210 THEN 171 -- 9x 19oz pours
               WHEN @VolumeUSFlOz <=240 THEN 190 -- 10x 19oz pours
               ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
               END
          )
     END       

       
	
	          
	ELSE IF @DrinkParameter = 11
	BEGIN
		---US flo oz 16 & Pitcher  (AMC Disney)

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=27 THEN 18
			WHEN @VolumeUSFlOz <=38 THEN 30
			WHEN @VolumeUSFlOz <=42 THEN 39
			WHEN @VolumeUSFlOz <=65 THEN 52
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END


	ElSE IF @DrinkParameter = 12
	BEGIN
		--Start of type 11 this is for BWW --------------------------------------------------------------------------------
		---US flo oz 14.5 or 21 

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 8   THEN 0
			WHEN @VolumeUSFlOz <=16.5 THEN 14.5
			WHEN @VolumeUSFlOz <=24   THEN 21
			WHEN @VolumeUSFlOz <=40   THEN 42
			WHEN @VolumeUSFlOz <=58   THEN 56.5
			WHEN @VolumeUSFlOz <=80   THEN 84
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)     
	END
	
	          
	ELSE IF @DrinkParameter = 13
	BEGIN
		---00158 - parks arlington
	  
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=46 THEN 30
			WHEN @VolumeUSFlOz <=65 THEN 52
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END


	ELSE IF @DrinkParameter = 14
	BEGIN
		---Native New Yorkers

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 8   THEN 0
			WHEN @VolumeUSFlOz <=17 THEN 14
			WHEN @VolumeUSFlOz <=23  THEN 20
			WHEN @VolumeUSFlOz <=30  THEN 28
			WHEN @VolumeUSFlOz <=46   THEN 40
			WHEN @VolumeUSFlOz <=65   THEN 55
			WHEN @VolumeUSFlOz <=84   THEN 80
			WHEN @VolumeUSFlOz <=150   THEN 150
			WHEN @VolumeUSFlOz <=250  THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END

	
	ELSE IF @DrinkParameter = 15
    BEGIN
       ---Zipps             
	   
        SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 10 THEN 0
            WHEN @VolumeUSFlOz <=19 THEN 13.5 -- 1x 13.5oz drink (Pint)
            WHEN @VolumeUSFlOz <=36 THEN 29.5 -- 1x 29.5oz pours
            WHEN @VolumeUSFlOz <=46 THEN 43 -- 1x 29.5oz and 13.5oz pours
            WHEN @VolumeUSFlOz <=52 THEN 50 -- 1x Pitcher
            WHEN @VolumeUSFlOz <=64 THEN 59 -- 2x 29.5oz pour
            WHEN @VolumeUSFlOz <=68 THEN 62 -- 1x 64oz 'Growler'
            WHEN @VolumeUSFlOz <=98 THEN 88.5 -- 3x 29.5oz pours
            WHEN @VolumeUSFlOz <=120 THEN 100 -- 2x 50oz pours
            WHEN @VolumeUSFlOz <=135 THEN 118 -- 4x 29.5ox pours
            WHEN @VolumeUSFlOz <=180 THEN 150 -- 3x 50oz pours
            WHEN @VolumeUSFlOz <=196 THEN 177 -- 6x 29.5iz pours
            WHEN @VolumeUSFlOz <=240 THEN 200 -- 4x Pitcher                                    
            WHEN @VolumeUSFlOz <=280 THEN 250 -- flush
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
            END
        )
    END
	

	ELSE IF @DrinkParameter = 16
	BEGIN
		---Hard Rock Cafe UK
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 4  THEN 0
			WHEN @VolumeUSFlOz <=10  THEN 9
			WHEN @VolumeUSFlOz <=20  THEN 18
			WHEN @VolumeUSFlOz <=29  THEN 27
			WHEN @VolumeUSFlOz <=40  THEN 36
			WHEN @VolumeUSFlOz <=49  THEN 45
			WHEN @VolumeUSFlOz <=55  THEN 54
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END


	ELSE IF @DrinkParameter = 17
	BEGIN
		--- AMC 2
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 6 THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=25 THEN 18
			WHEN @VolumeUSFlOz <=38 THEN 26.5
			WHEN @VolumeUSFlOz <=42 THEN 39
			WHEN @VolumeUSFlOz <=65 THEN 52
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
		END
		)
	END


	ELSE IF @DrinkParameter = 18
    BEGIN
		---  18 = US Fl OZ  AMC HAWTHORN 12 Location (16oz & 20oz Glass) 
                           
        SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <=9.5 THEN 0
            WHEN @VolumeUSFlOz <=14.5 THEN 13 -- 1 x 13oz
            WHEN @VolumeUSFlOz <=30 THEN 18 -- 1 x 20oz
            WHEN @VolumeUSFlOz <=48 THEN 36 -- 2 x 20oz
            WHEN @VolumeUSFlOz <=66 THEN 54 -- 3 x 20o
            WHEN @VolumeUSFlOz <=88 THEN 72 -- 4 x 20oz
            WHEN @VolumeUSFlOz <=105 THEN 90 -- 5 x 20oz  
            WHEN @VolumeUSFlOz <=130 THEN 108 -- 6 x 20oz
            WHEN @VolumeUSFlOz <=152 THEN 126 -- 7 x 20oz
            WHEN @VolumeUSFlOz <=172 THEN 144 -- 8 x 20oz
            WHEN @VolumeUSFlOz <=198 THEN 162 -- 9 x 20oz
            WHEN @VolumeUSFlOz <=220 THEN 180 -- 10 x 20oz
            WHEN @VolumeUSFlOz <=242 THEN 198 -- 11 x 20oz
            WHEN @VolumeUSFlOz <=264 THEN 216 -- 12 x 20oz
            WHEN @VolumeUSFlOz <=286 THEN 234 -- 13 x 20oz
            WHEN @VolumeUSFlOz <=300 THEN 252 -- 14 x 20oz
            WHEN @VolumeUSFlOz <=310 THEN 300 --
            WHEN @VolumeUSFlOz <=350 THEN 350 --
            WHEN @VolumeUSFlOz <=400 THEN 400 --
            WHEN @VolumeUSFlOz <=450 THEN 450 --
            WHEN @VolumeUSFlOz <=500 THEN 500 --
            WHEN @VolumeUSFlOz <=550 THEN 550 --
            WHEN @VolumeUSFlOz <=600 THEN 600 --
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
        END
        )
    END

	ELSE IF @DrinkParameter = 19
	BEGIN
		---  19 = US Fl OZ (AMC 28.5) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=2 THEN 0
			WHEN @VolumeUSFlOz <=6 THEN 2.5
			WHEN @VolumeUSFlOz <=9 THEN 6.5
			WHEN @VolumeUSFlOz <=17 THEN 13
			WHEN @VolumeUSFlOz <=27 THEN 26
			WHEN @VolumeUSFlOz <=38 THEN 28.5
			WHEN @VolumeUSFlOz <=46 THEN 39
			WHEN @VolumeUSFlOz <=69 THEN 57
			WHEN @VolumeUSFlOz <=90 THEN 85.5
			WHEN @VolumeUSFlOz <=130 THEN 114
			WHEN @VolumeUSFlOz <=250 THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END

	
	ELSE IF @DrinkParameter = 20
	BEGIN
		---  20 = US Fl OZ (US1828.5) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=3 THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 6.5
			WHEN @VolumeUSFlOz <=12 THEN 13
			WHEN @VolumeUSFlOz <=17.6 THEN 13.5
			WHEN @VolumeUSFlOz <=24 THEN 18
			WHEN @VolumeUSFlOz <=38 THEN 28.5
			WHEN @VolumeUSFlOz <=48 THEN 36
			WHEN @VolumeUSFlOz <=76 THEN 57
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=90 THEN 85.5
			WHEN @VolumeUSFlOz <=130 THEN 114
			WHEN @VolumeUSFlOz <=250 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END

	
	ELSE IF @DrinkParameter = 21
	BEGIN
		---  21 = US Fl OZ (Chickies) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=4 THEN 0
			WHEN @VolumeUSFlOz <=11 THEN 8
			WHEN @VolumeUSFlOz <=15 THEN 12
			WHEN @VolumeUSFlOz <=30 THEN 24
			WHEN @VolumeUSFlOz <=40 THEN 36
			WHEN @VolumeUSFlOz <=55 THEN 48
			WHEN @VolumeUSFlOz <=64 THEN 60
			WHEN @VolumeUSFlOz <=80 THEN 72
			WHEN @VolumeUSFlOz <=110 THEN 96
			WHEN @VolumeUSFlOz <=150 THEN 120
			WHEN @VolumeUSFlOz <=250 THEN 240
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
		IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
			SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1.5 THEN 0
			WHEN @VolumeUSFlOz <=5 THEN 3
			WHEN @VolumeUSFlOz <=9 THEN 6
			WHEN @VolumeUSFlOz <=12 THEN 11
			WHEN @VolumeUSFlOz <=15 THEN 14	
			WHEN @VolumeUSFlOz <=30 THEN 28	
			WHEN @VolumeUSFlOz <=42 THEN 42	
			WHEN @VolumeUSFlOz <=65 THEN 56	
			WHEN @VolumeUSFlOz <=85 THEN 80
			WHEN @VolumeUSFlOz <=110 THEN 94
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END                             
            )

	END
	
	
	ELSE IF @DrinkParameter = 22
	BEGIN
		---  22 = US Fl OZ (Chickies) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=4 THEN 0
			WHEN @VolumeUSFlOz <=10 THEN 7
			WHEN @VolumeUSFlOz <=16 THEN 14
			WHEN @VolumeUSFlOz <=24 THEN 21
			WHEN @VolumeUSFlOz <=32 THEN 28
			WHEN @VolumeUSFlOz <=45 THEN 42
			WHEN @VolumeUSFlOz <=64 THEN 56
			WHEN @VolumeUSFlOz <=80 THEN 70
			WHEN @VolumeUSFlOz <=112 THEN 98
			WHEN @VolumeUSFlOz <=128 THEN 112
			WHEN @VolumeUSFlOz <=250 THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	
	ELSE IF @DrinkParameter = 23
	BEGIN
		---  23 = US Fl OZ (Hornet) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=5 THEN 0
			WHEN @VolumeUSFlOz <=7 THEN 6
			WHEN @VolumeUSFlOz <=13.5 THEN 12
			WHEN @VolumeUSFlOz <=18 THEN 16
			WHEN @VolumeUSFlOz <=26 THEN 24
			WHEN @VolumeUSFlOz <=35 THEN 32
			WHEN @VolumeUSFlOz <=40 THEN 36
			WHEN @VolumeUSFlOz <=50 THEN 48
			WHEN @VolumeUSFlOz <=62 THEN 60
			WHEN @VolumeUSFlOz <=68 THEN 64
			WHEN @VolumeUSFlOz <=85 THEN 80
			WHEN @VolumeUSFlOz <=105 THEN 96
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END	
		)
	END
	
	
	ELSE IF @DrinkParameter = 24
	BEGIN
		---  24 = US Fl OZ (Darden)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=7.5 THEN 0
			WHEN @VolumeUSFlOz <=11.5 THEN 8.75
			WHEN @VolumeUSFlOz <=15 THEN 12.5
			WHEN @VolumeUSFlOz <=23 THEN 17.5
			WHEN @VolumeUSFlOz <=27 THEN 25
			WHEN @VolumeUSFlOz <=45 THEN 35
			WHEN @VolumeUSFlOz <=63 THEN 52.5
			WHEN @VolumeUSFlOz <=84 THEN 70
			WHEN @VolumeUSFlOz <=108 THEN 87.5
			WHEN @VolumeUSFlOz <=130THEN 105
			WHEN @VolumeUSFlOz <=150 THEN 150
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	
	ELSE IF @DrinkParameter = 25
	BEGIN
		---  25 = US Fl OZ (LittlePubCoPatrickCarrols) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=5 THEN 0
			WHEN @VolumeUSFlOz <=9.5 THEN 8
			WHEN @VolumeUSFlOz <=11 THEN 10
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=23 THEN 20
			WHEN @VolumeUSFlOz <=32 THEN 26
			WHEN @VolumeUSFlOz <=40 THEN 39
			WHEN @VolumeUSFlOz <=46 THEN 40
			WHEN @VolumeUSFlOz <=56 THEN 52
			WHEN @VolumeUSFlOz <=69 THEN 60
			WHEN @VolumeUSFlOz <=80 THEN 79
			WHEN @VolumeUSFlOz <=85 THEN 80
			WHEN @VolumeUSFlOz <=150 THEN 100
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	
	ELSE IF @DrinkParameter = 26
	BEGIN
		---  26 = US Fl OZ (AbInbev Busch Stadium)

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=5 THEN 0
			WHEN @VolumeUSFlOz <=12 THEN 9
			WHEN @VolumeUSFlOz <=30 THEN 18
			WHEN @VolumeUSFlOz <=50 THEN 36 -- 2x 18oz pours
			WHEN @VolumeUSFlOz <=70 THEN 54 -- 3x 18oz pours
			WHEN @VolumeUSFlOz <=90 THEN 72 -- 4x 18oz 
			WHEN @VolumeUSFlOz <=100 THEN 90 -- 5x 18oz pours
			WHEN @VolumeUSFlOz <=140 THEN 108 -- 6x 18oz pours   
			WHEN @VolumeUSFlOz <=165 THEN 126 -- 7x 18oz pours
			WHEN @VolumeUSFlOz <=175 THEN 144 -- 8x 18oz pours
			WHEN @VolumeUSFlOz <=195 THEN 162 -- 9x 18oz pours
			WHEN @VolumeUSFlOz <=200 THEN 180 -- 10x 18oz pours
			WHEN @VolumeUSFlOz <=245 THEN 198 -- 11x 18oz pours
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	
	ELSE IF @DrinkParameter = 27
	BEGIN
		--- 27 = US Fl OZ (AMC New 24oz Cup Size Ã¢â‚¬â€œ Based on parameter 19 but with 24 oz addition)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=2 THEN 0
			WHEN @VolumeUSFlOz <=4 THEN 2.5
			WHEN @VolumeUSFlOz <=9 THEN 6.5
			WHEN @VolumeUSFlOz <=17 THEN 13
			WHEN @VolumeUSFlOz <=25 THEN 21
			WHEN @VolumeUSFlOz <=32 THEN 26
			WHEN @VolumeUSFlOz <=38 THEN 28.5
			WHEN @VolumeUSFlOz <=42 THEN 39
			WHEN @VolumeUSFlOz <=55 THEN 42
			WHEN @VolumeUSFlOz <=69 THEN 57
			WHEN @VolumeUSFlOz <=90 THEN 85.5
			WHEN @VolumeUSFlOz <=130 THEN 114
			WHEN @VolumeUSFlOz <=250 THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END

ELSE IF @DrinkParameter = 28
	BEGIN
		--- 28 = US Fl OZ (Mellow Mushroom Sites)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=.5 THEN 0
			WHEN @VolumeUSFlOz <=2 THEN 1
			WHEN @VolumeUSFlOz <=6 THEN 4 -- 4oz flight
			WHEN @VolumeUSFlOz <=12 THEN 8 -- 10oz High Gravity (8oz target size)
			WHEN @VolumeUSFlOz <=18 THEN 13 -- 16oz (13oz target size) 
			WHEN @VolumeUSFlOz <=23 THEN 20 -- 2x 10oz 
			WHEN @VolumeUSFlOz <=29 THEN 26 -- 2x 16oz 
			WHEN @VolumeUSFlOz <=42 THEN 39 -- 3x 16oz
			WHEN @VolumeUSFlOz <=64 THEN 57 -- 60oz Pitcher (57oz target)
			WHEN @VolumeUSFlOz <=130 THEN 114 -- 2x 60oz pither
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	ELSE IF @DrinkParameter = 29
	BEGIN
		--- 29 = US Fl OZ (Whiskey Tango Foxtrot)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1.5 THEN 0
			WHEN @VolumeUSFlOz <=3 THEN 2
			WHEN @VolumeUSFlOz <=12 THEN 8 -- 10oz (8oz target size)
			WHEN @VolumeUSFlOz <=17 THEN 14 -- 16oz (14oz target size) 
			WHEN @VolumeUSFlOz <=17 THEN 16.5 -- 18.50oz (16.5oz target size) 
			WHEN @VolumeUSFlOz <=19 THEN 18 -- 20oz (18oz target size)  
			WHEN @VolumeUSFlOz <=24 THEN 19.5 -- 21.5oz (19.5oz target size)
			WHEN @VolumeUSFlOz <=34 THEN 33 -- 2x 18.5oz Drinks (16.5oz target size)
			WHEN @VolumeUSFlOz <=37 THEN 36 -- 2x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=34 THEN 39 -- 2x 21.5oz Drinks (19.5oz target size)
			WHEN @VolumeUSFlOz <=45 THEN 42 -- 3x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=50 THEN 49.5 -- 3x 18.5oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=58 THEN 54 -- 3x 20oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=60 THEN 58.5 -- 3x 21.5oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=70 THEN 66 -- 4x 18.5oz Drinks (16.50oz target size)
			WHEN @VolumeUSFlOz <=80 THEN 78 -- 4x 21.5oz Drinks (19.50oz target size)
			WHEN @VolumeUSFlOz <=84 THEN 78 -- 4x 21.5oz Drinks (19.50oz target size)
			WHEN @VolumeUSFlOz <=95 THEN 90 -- 5x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=110 THEN 108 -- 6x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=116 THEN 115.5 -- 7x 18.5oz Drinks (16.5oz target size)
			WHEN @VolumeUSFlOz <=127 THEN 126 -- 7x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=160 THEN 144 -- 8x 20oz Drinks (18oz target size)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	ELSE IF @DrinkParameter = 30
	BEGIN
		--- 30 = US Fl OZ (Angry Ginger)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1 THEN 0
			WHEN @VolumeUSFlOz <=3 THEN 2
			WHEN @VolumeUSFlOz <=8 THEN 4
			WHEN @VolumeUSFlOz <=16.5 THEN 14-- 1x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=25 THEN 18 -- 1x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=33 THEN 28 -- 2x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=41 THEN 36 -- 2x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=44 THEN 42 -- 3x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=54.5 THEN 54 -- 3x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=60 THEN 56 -- 4x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=75 THEN 72 -- 4x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=95 THEN 90 -- 5x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=130THEN 105
			WHEN @VolumeUSFlOz <=150 THEN 150
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	ELSE IF @DrinkParameter = 31
	BEGIN
		--- 31 = US Fl OZ (Mandeville Beer Garden)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=0.5 THEN 0
			WHEN @VolumeUSFlOz <=2 THEN 1 -- Sample 1oz
			WHEN @VolumeUSFlOz <=8 THEN 6 -- 8oz Cup (6oz target size)
			WHEN @VolumeUSFlOz <=12 THEN 10 -- 12oz cup (10oz target size)
			WHEN @VolumeUSFlOz <=17 THEN 14 -- 16oz cup (14oz target size) 
			WHEN @VolumeUSFlOz <=24 THEN 20 -- 2x 12oz (10oz target size) 
			WHEN @VolumeUSFlOz <=35 THEN 28 -- 2x 16oz cup (14oz target size)  
			WHEN @VolumeUSFlOz <=50 THEN 42 -- 3x 16oz cup (14oz target size) 
			WHEN @VolumeUSFlOz <=69 THEN 56 -- 4x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=75 THEN 70 -- 5x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=95 THEN 84 -- 6x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=130 THEN 105
			WHEN @VolumeUSFlOz <=150 THEN 150
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	ELSE IF @DrinkParameter = 32
	BEGIN
		--- 32 = US Fl OZ (Flatbread Somerville) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 2  THEN 0
			WHEN @VolumeUSFlOz <= 4  THEN 3.75
			WHEN @VolumeUSFlOz <=9 THEN 7.25
			WHEN @VolumeUSFlOz <=13 THEN 11.5
			WHEN @VolumeUSFlOz <=19 THEN 15 
			WHEN @VolumeUSFlOz <=24 THEN 23 
			WHEN @VolumeUSFlOz <=32 THEN 30
			WHEN @VolumeUSFlOz <=50 THEN 45 
			WHEN @VolumeUSFlOz <=64 THEN 60 
			WHEN @VolumeUSFlOz <=80 THEN 75
			WHEN @VolumeUSFlOz <=110 THEN 105
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	ELSE IF @DrinkParameter = 33
	BEGIN
		---  33 = US Fl OZ (AMC Angry Orchard LTO - SITES PREVIOUSLY ON D.A.P 17)
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 6 THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=25 THEN 18
			WHEN @VolumeUSFlOz <=38 THEN 26.5
			WHEN @VolumeUSFlOz <=42 THEN 39
			WHEN @VolumeUSFlOz <=65 THEN 52
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2			
			END
			)
			
	   	IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
			SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1.5 THEN 0
			WHEN @VolumeUSFlOz <=6 THEN 4
			WHEN @VolumeUSFlOz <=10 THEN 6.5
			WHEN @VolumeUSFlOz <=16 THEN 13
			WHEN @VolumeUSFlOz <=25 THEN 18
			WHEN @VolumeUSFlOz <=38 THEN 26.5
			WHEN @VolumeUSFlOz <=42 THEN 39
			WHEN @VolumeUSFlOz <=65 THEN 52
			WHEN @VolumeUSFlOz <=85 THEN 72
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
            END
		)
	END
	
	ELSE IF @DrinkParameter = 34
	BEGIN
		---  34 = US Fl OZ (AMC Angry Orchard LTO - SITES PREVIOUSLY ON D.A.P 19)
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=2 THEN 0
			WHEN @VolumeUSFlOz <=6 THEN 2.5
			WHEN @VolumeUSFlOz <=9 THEN 6.5
			WHEN @VolumeUSFlOz <=17 THEN 13
			WHEN @VolumeUSFlOz <=27 THEN 26
			WHEN @VolumeUSFlOz <=38 THEN 28.5
			WHEN @VolumeUSFlOz <=46 THEN 39
			WHEN @VolumeUSFlOz <=69 THEN 57
			WHEN @VolumeUSFlOz <=90 THEN 85.5
			WHEN @VolumeUSFlOz <=130 THEN 114
			WHEN @VolumeUSFlOz <=250 THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
			)
			
	   	IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
			SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=2 THEN 0
			WHEN @VolumeUSFlOz <=7 THEN 4
			WHEN @VolumeUSFlOz <=9 THEN 6.5
			WHEN @VolumeUSFlOz <=17 THEN 13
			WHEN @VolumeUSFlOz <=27 THEN 26
			WHEN @VolumeUSFlOz <=38 THEN 28.5
			WHEN @VolumeUSFlOz <=46 THEN 39
			WHEN @VolumeUSFlOz <=69 THEN 57
			WHEN @VolumeUSFlOz <=90 THEN 85.5
			WHEN @VolumeUSFlOz <=130 THEN 114
			WHEN @VolumeUSFlOz <=250 THEN 250
			END                             
        )
    END
	
	ELSE IF @DrinkParameter = 35
	BEGIN
		---  35 = US Fl OZ (AMC Angry Orchard LTO - SITES PREVIOUSLY ON D.A.P 27)
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=9 THEN 0
			WHEN @VolumeUSFlOz <=17.5 THEN 13 -- 1 x 13oz
			WHEN @VolumeUSFlOz <=27 THEN 21 -- 1 x 21oz
			WHEN @VolumeUSFlOz <=36 THEN 26 -- 2 x 13oz
			WHEN @VolumeUSFlOz <=54 THEN 42 -- 2 x 21oz
			WHEN @VolumeUSFlOz <=60.5 THEN 57 -- Pitcher (60oz Glass)
			WHEN @VolumeUSFlOz <=78 THEN 63 -- 3 x 21oz
			WHEN @VolumeUSFlOz <=105 THEN 84 -- 4 x 21oz
			WHEN @VolumeUSFlOz <=130 THEN 105 -- 5 x 21oz  
			WHEN @VolumeUSFlOz <=156 THEN 126 -- 6 x 21oz
			WHEN @VolumeUSFlOz <=182 THEN 147 -- 7 x 21oz
			WHEN @VolumeUSFlOz <=208 THEN 168 -- 8 x 21oz
			WHEN @VolumeUSFlOz <=234 THEN 189 -- 9 x 21oz
			WHEN @VolumeUSFlOz <=260 THEN 210 -- 10 x 21oz
			WHEN @VolumeUSFlOz <=286 THEN 231 -- 11 x 21oz
			WHEN @VolumeUSFlOz <=312 THEN 252 -- 12 x 21oz
			WHEN @VolumeUSFlOz <=338 THEN 273 -- 13 x 21oz
			WHEN @VolumeUSFlOz <=364 THEN 294 -- 14 x 21oz
			WHEN @VolumeUSFlOz <=390 THEN 315 -- 15 x 21oz
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
	    )
		IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1.5 THEN 0
			WHEN @VolumeUSFlOz <=2.5 THEN 2
			WHEN @VolumeUSFlOz <=5 THEN 4
			WHEN @VolumeUSFlOz <=9.5 THEN 6
			WHEN @VolumeUSFlOz <=17.5 THEN 13 -- 1 x 13oz
			WHEN @VolumeUSFlOz <=27 THEN 21 -- 1 x 21oz
			WHEN @VolumeUSFlOz <=36 THEN 26 -- 2 x 13oz
			WHEN @VolumeUSFlOz <=54 THEN 42 -- 2 x 21oz
			WHEN @VolumeUSFlOz <=60.5 THEN 57 -- Pitcher (60oz Glass)
			WHEN @VolumeUSFlOz <=78 THEN 63 -- 3 x 21oz
			WHEN @VolumeUSFlOz <=105 THEN 84 -- 4 x 21oz
			WHEN @VolumeUSFlOz <=130 THEN 105 -- 5 x 21oz  
			WHEN @VolumeUSFlOz <=156 THEN 126 -- 6 x 21oz
			WHEN @VolumeUSFlOz <=182 THEN 147 -- 7 x 21oz
			WHEN @VolumeUSFlOz <=208 THEN 168 -- 8 x 21oz
			WHEN @VolumeUSFlOz <=234 THEN 189 -- 9 x 21oz
			WHEN @VolumeUSFlOz <=260 THEN 210 -- 10 x 21oz
			WHEN @VolumeUSFlOz <=286 THEN 231 -- 11 x 21oz
			WHEN @VolumeUSFlOz <=312 THEN 252 -- 12 x 21oz
			WHEN @VolumeUSFlOz <=338 THEN 273 -- 13 x 21oz
			WHEN @VolumeUSFlOz <=364 THEN 294 -- 14 x 21oz
			WHEN @VolumeUSFlOz <=390 THEN 315 -- 15 x 21oz
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END                                  
	    )		
	END
	  
	ELSE IF @DrinkParameter = 36
	BEGIN
		--- 36 = US Fl OZ (Marble Brewery)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 3  THEN 0
			WHEN @VolumeUSFlOz <= 5  THEN 4 -- 4oz Cup (4oz target size)
			WHEN @VolumeUSFlOz <=10 THEN 8 -- 10oz Cup (8oz target size)
			WHEN @VolumeUSFlOz <=17 THEN 14 -- 16oz Cup (14oz target size)
			WHEN @VolumeUSFlOz <=25 THEN 18.5 -- 21.5oz Cup (18.5oz target size)  
			WHEN @VolumeUSFlOz <=34 THEN 32 -- 32oz Cup (32oz target size)
			WHEN @VolumeUSFlOz <=48 THEN 42 -- 3x 16oz Cup (14oz target size)
			WHEN @VolumeUSFlOz <=57 THEN 55.5 -- 3x 21.5oz Cup (18.5oz target size)
			WHEN @VolumeUSFlOz <=66 THEN 64 -- 64oz Growler (64oz target size)
			WHEN @VolumeUSFlOz <=88 THEN 74 -- 4x 21.5oz Cup (18.5oz target size)
			WHEN @VolumeUSFlOz <=100 THEN 96 -- 3x 32oz Cup (32oz target size)		
			WHEN @VolumeUSFlOz <=132 THEN 128 -- 2x 64oz Growler (64oz target size) 
			WHEN @VolumeUSFlOz <=195 THEN 192 -- 2x 64oz Growler (64oz target size)
			WHEN @VolumeUSFlOz <=250 THEN 250 
			WHEN @VolumeUSFlOz <=350 THEN 300 
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
			)

	END
	
	ELSE IF @DrinkParameter = 37
	BEGIN
		--- 37 = US Fl OZ (Reed & Greenough)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 1  THEN 0
			WHEN @VolumeUSFlOz <= 3  THEN 1
			WHEN @VolumeUSFlOz <=9 THEN 5
			WHEN @VolumeUSFlOz <=19 THEN 15 
			WHEN @VolumeUSFlOz <=25 THEN 25 
			WHEN @VolumeUSFlOz <=32 THEN 30
			WHEN @VolumeUSFlOz <=50 THEN 45 
			WHEN @VolumeUSFlOz <=64 THEN 60 
			WHEN @VolumeUSFlOz <=80 THEN 75
			WHEN @VolumeUSFlOz <=96 THEN 90
			WHEN @VolumeUSFlOz <=110 THEN 105
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	ELSE IF @DrinkParameter = 38
	BEGIN
		--- 38 = US Fl OZ (Flatbread Portland) 
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 2  THEN 0
			WHEN @VolumeUSFlOz <= 4  THEN 3.75
			WHEN @VolumeUSFlOz <=9 THEN 7
			WHEN @VolumeUSFlOz <=13 THEN 11
			WHEN @VolumeUSFlOz <=19 THEN 14.5 
			WHEN @VolumeUSFlOz <=24 THEN 22 
			WHEN @VolumeUSFlOz <=32 THEN 29
			WHEN @VolumeUSFlOz <=50 THEN 43.5 
			WHEN @VolumeUSFlOz <=64 THEN 58 
			WHEN @VolumeUSFlOz <=80 THEN 72.5
			WHEN @VolumeUSFlOz <=105 THEN 101.5 
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
	ELSE IF @DrinkParameter = 39
	BEGIN
		--- 39 = US Fl OZ (BlackBird [AKA Manito Tap House])  
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 2  THEN 1
			WHEN @VolumeUSFlOz <= 4  THEN 4
			WHEN @VolumeUSFlOz <=7 THEN 6.5 --16oz Tulip(6.5, 8.5, 10.5, 12.5 and 14.5oz target size)
			WHEN @VolumeUSFlOz <=9 THEN 8.5 --16oz Tulip(6.5, 8.5, 10.5, 12.5 and 14.5oz target size)
			WHEN @VolumeUSFlOz <=11 THEN 10.5 --16oz Tulip(6.5, 8.5, 10.5, 12.5 and 14.5oz target size)
			WHEN @VolumeUSFlOz <=13 THEN 12.5 --16oz Tulip(6.5, 8.5, 10.5, 12.5 and 14.5oz target size)
			WHEN @VolumeUSFlOz <=16 THEN 14.5 --16oz Tulip(6.5, 8.5, 10.5, 12.5 and 14.5oz target size)
			WHEN @VolumeUSFlOz <=23 THEN 17 --20oz Glass(17oz target size)
			WHEN @VolumeUSFlOz <=26 THEN 25 --2x 12.5oz Tulip
			WHEN @VolumeUSFlOz <=30 THEN 29 --2x 14.5oz Tulip
			WHEN @VolumeUSFlOz <=38 THEN 34 --2x 20oz Glass(17oz target size)
			WHEN @VolumeUSFlOz <=46	THEN 43.5 --3x 14.5oz Tulip
			WHEN @VolumeUSFlOz <=54 THEN 51 --3x 20oz Glass(17oz target size)
			WHEN @VolumeUSFlOz <=60 THEN 58 --4x 14.5oz Tulip
			WHEN @VolumeUSFlOz <=70 THEN 68 --4x 20oz Glass(17oz target size)
			WHEN @VolumeUSFlOz <=80 THEN 72.5 --5x 14.5oz Tulip
			WHEN @VolumeUSFlOz <=100 THEN 85 --5x 20oz Glass(17oz target size)
			WHEN @VolumeUSFlOz <=150 THEN 150 --flush
			WHEN @VolumeUSFlOz <=250 THEN 250 --flush
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END

ELSE IF @DrinkParameter = 40
	BEGIN
		---Norwegian Cruise Lines
	  
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 6 THEN 4
			WHEN @VolumeUSFlOz <= 12 THEN 8   
			WHEN @VolumeUSFlOz <=19 THEN 14.5
			WHEN @VolumeUSFlOz <=38 THEN 29    
			WHEN @VolumeUSFlOz <=57 THEN 43.5    
			WHEN @VolumeUSFlOz <=70 THEN 58     
			WHEN @VolumeUSFlOz <= 105 THEN 87     
			WHEN @VolumeUSFlOz <=121 THEN 100   
			WHEN @VolumeUSFlOz <=150 THEN 150
			WHEN @VolumeUSFlOz <=250 THEN 250
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
ELSE IF @DrinkParameter = 41
	BEGIN
		---Taos Mesa Brewing Company
 
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1 THEN 0
			WHEN @VolumeUSFlOz <=2 THEN 1
			WHEN @VolumeUSFlOz <=6 THEN 4 -- 4oz Sample
			WHEN @VolumeUSFlOz <=12 THEN 10 -- 13oz cup (10oz target size)
			WHEN @VolumeUSFlOz <=17 THEN 14 -- 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=24 THEN 20 -- 2x 13oz (10oz target size)
			WHEN @VolumeUSFlOz <=35 THEN 30 -- 1x 32oz cup (14oz target size) 
			WHEN @VolumeUSFlOz <=50 THEN 42 -- 3x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=69 THEN 56 -- 4x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=75 THEN 70 -- 5x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=95 THEN 84 -- 6x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=130 THEN 105
			WHEN @VolumeUSFlOz <=150 THEN 150
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END

        )

	END
	
	
	ElSE IF @DrinkParameter = 42
	BEGIN
		--Start of type 11 this is for Texas Roadhouse (Bubba 33) --------------------------------------------------------------------------------
		---US flo oz 14.5 or 21 

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 3.5 THEN 0			
			WHEN @VolumeUSFlOz <= 6  THEN 4.25
			WHEN @VolumeUSFlOz <=11 THEN 10.25
			WHEN @VolumeUSFlOz <=16.5 THEN 14.5
			WHEN @VolumeUSFlOz <=24 THEN 21
			WHEN @VolumeUSFlOz <=32 THEN 29
			WHEN @VolumeUSFlOz <=45 THEN 42
			WHEN @VolumeUSFlOz <=60 THEN 58
			WHEN @VolumeUSFlOz <=65 THEN 63
			WHEN @VolumeUSFlOz <=75 THEN 72.5
			WHEN @VolumeUSFlOz <=96 THEN 84
			WHEN @VolumeUSFlOz <=100 THEN 100
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)     
	END
	
	ELSE IF @DrinkParameter = 43
	BEGIN
		---Tavern Hospitality - Tavern Downtown
 
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=2 THEN 0
			WHEN @VolumeUSFlOz <=3.5 THEN 3
			WHEN @VolumeUSFlOz <=8 THEN 7
			WHEN @VolumeUSFlOz <=20 THEN 16 -- 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=32 THEN 32 -- 2x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=52 THEN 48 -- 3x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=70 THEN 64 -- 4x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=85 THEN 80 -- 5x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=100 THEN 96 -- 6x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=120 THEN 112 -- 7x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=135 THEN 128 -- 8x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=150 THEN 144 -- 9x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=170 THEN 160 -- 10x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=180 THEN 176 -- 11x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=200 THEN 192 -- 12x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=215 THEN 108 -- 13x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=230 THEN 224  -- 14x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=250 THEN 240 -- 15x 16oz cup (14oz target size)
			WHEN @VolumeUSFlOz <=400 THEN 300  -- Rare flush
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END

        )

	END
	
	ElSE IF @DrinkParameter = 44
	BEGIN
		--Start of type 44 this is for Biergarten --------------------------------------------------------------------------------
		
			SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 3.5 THEN 0			
			WHEN @VolumeUSFlOz <= 6  THEN 6
			WHEN @VolumeUSFlOz <=11 THEN 9
			WHEN @VolumeUSFlOz <=17 THEN 14
			WHEN @VolumeUSFlOz <=22 THEN 18
			WHEN @VolumeUSFlOz <=35 THEN 29
			WHEN @VolumeUSFlOz <=50 THEN 42
			WHEN @VolumeUSFlOz <=65 THEN 58
			WHEN @VolumeUSFlOz <=82 THEN 70
			WHEN @VolumeUSFlOz <=96 THEN 87
			WHEN @VolumeUSFlOz <=128 THEN 120
			WHEN @VolumeUSFlOz <=160 THEN 145
			WHEN @VolumeUSFlOz <=192 THEN 174
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)     
	END
	
	ELSE IF @DrinkParameter = 45
	BEGIN
		--- 45 = US Fl OZ (Tavern Hospitality - Platt Park)
		
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=1.5 THEN 0
			WHEN @VolumeUSFlOz <=2.5 THEN 2 -- 2oz Taster
			WHEN @VolumeUSFlOz <=5 THEN 4 -- 4oz flight
			WHEN @VolumeUSFlOz <=12 THEN 8 -- 10oz (8oz target size)
			WHEN @VolumeUSFlOz <=17 THEN 14 -- 16oz (14oz target size) 
			WHEN @VolumeUSFlOz <=19 THEN 18 -- 20oz (18oz target size)  
			WHEN @VolumeUSFlOz <=37 THEN 28 -- 2x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=37 THEN 36 -- 2x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=45 THEN 42 -- 3x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=58 THEN 54 -- 3x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=75 THEN 72 -- 4x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=90 THEN 84 -- 6x 16oz Drinks (14oz target size)
			WHEN @VolumeUSFlOz <=95 THEN 90 -- 5x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=110 THEN 108 -- 6x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=127 THEN 126 -- 7x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=155 THEN 144 -- 8x 20oz Drinks (18oz target size)
			WHEN @VolumeUSFlOz <=165 THEN 162 -- 9x 20oz Drinks (18oz target size)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
	END
	
		ElSE IF @DrinkParameter = 46
	BEGIN
		--- 46 = US Fl Oz (The Dudes Brewing Company)

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 2.5 THEN 0
			WHEN @VolumeUSFlOz <= 5 THEN 3.5 -- 4oz flight (3.5oz target size)
			WHEN @VolumeUSFlOz <= 7 THEN 6 -- 6oz target
			WHEN @VolumeUSFlOz <= 10.5 THEN 8 -- 8/10oz (8oz target size)
			WHEN @VolumeUSFlOz <= 13 THEN 12 -- 8/10oz (8oz target size)
			WHEN @VolumeUSFlOz <= 18 THEN 14 -- 16oz 'pint' (14.5oz target size)
			WHEN @VolumeUSFlOz <= 27 THEN 22 -- 16oz 'pint' (14.5oz target size)
			WHEN @VolumeUSFlOz <= 34 THEN 28 -- 8/10oz (8oz target size)			
			WHEN @VolumeUSFlOz <=40 THEN 32 -- 32oz Growler (32oz target size)
			WHEN @VolumeUSFlOz <=55 THEN 43.5 -- 3 x 16oz 'pints' (43.5 target size)
			WHEN @VolumeUSFlOz <=75 THEN 64
			WHEN @VolumeUSFlOz <=100 THEN 96 -- 3 x 32oz Growler
			WHEN @VolumeUSFlOz <=250 THEN 250
			WHEN @VolumeUSFlOz <=300 THEN 300
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)
		
		IF UPPER(@ProductCategoryName) LIKE '%WINE%'
			SELECT @Drinks = (
			CASE
            WHEN @VolumeUSFlOz <= 3.49  THEN 0
			WHEN @VolumeUSFlOz <= 7.5 THEN 5 
            WHEN @VolumeUSFlOz <= 12.5 THEN 10 
            WHEN @VolumeUSFlOz <= 17 THEN 15 
            WHEN @VolumeUSFlOz <= 22 THEN 20 
            WHEN @VolumeUSFlOz <= 27 THEN 25 
            WHEN @VolumeUSFlOz <= 32 THEN 30 
            WHEN @VolumeUSFlOz <= 37 THEN 35                                                
			WHEN @VolumeUSFlOz <= 42 THEN 40
            WHEN @VolumeUSFlOz <= 47 THEN 45                                                
			WHEN @VolumeUSFlOz <= 52 THEN 50			
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
		END
		)		
		
		 IF UPPER(@ProductCategoryName) LIKE '%LIGHT BEER%'
            SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 3  THEN 0
            WHEN @VolumeUSFlOz <= 5 THEN 3.74 -- 4oz
            WHEN @VolumeUSFlOz <= 10.5 THEN 7.47 -- 8oz
            WHEN @VolumeUSFlOz <= 26 THEN 14.95 -- 16oz
            WHEN @VolumeUSFlOz <= 40 THEN 29.9 -- 2x16oz
            WHEN @VolumeUSFlOz <= 60 THEN 44.85
            WHEN @VolumeUSFlOz <= 72 THEN 59.8
            WHEN @VolumeUSFlOz <= 85 THEN 74.75                                               
            WHEN @VolumeUSFlOz <= 102 THEN 89.7
            WHEN @VolumeUSFlOz <= 117 THEN 104.65                                               
            WHEN @VolumeUSFlOz <= 135 THEN 119.9
            WHEN @VolumeUSFlOz <= 150 THEN 134.55                                               
            WHEN @VolumeUSFlOz <= 170 THEN 149.5
            WHEN @VolumeUSFlOz <= 190 THEN 164.45                                               
            WHEN @VolumeUSFlOz <= 206 THEN 179.4                                                        
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
        END
       )     
        
   IF UPPER(@ProductCategoryName) LIKE '%IPA%'
        SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 3  THEN 0
            WHEN @VolumeUSFlOz <= 5 THEN 3.64 -- 4oz
            WHEN @VolumeUSFlOz <= 10.5 THEN 7.29 -- 8oz
            WHEN @VolumeUSFlOz <= 26 THEN 14.58 -- 16oz
            WHEN @VolumeUSFlOz <= 40 THEN 29.16 -- 2x16oz
            WHEN @VolumeUSFlOz <= 60 THEN 43.74
            WHEN @VolumeUSFlOz <= 72 THEN 58.32
            WHEN @VolumeUSFlOz <= 85 THEN 72.9                                              
            WHEN @VolumeUSFlOz <= 102 THEN 87.48
            WHEN @VolumeUSFlOz <= 117 THEN 102.06                                              
            WHEN @VolumeUSFlOz <= 135 THEN 116.64
            WHEN @VolumeUSFlOz <= 150 THEN 131.22                                               
            WHEN @VolumeUSFlOz <= 170 THEN 145.8
            WHEN @VolumeUSFlOz <= 190 THEN 160.38                                              
            WHEN @VolumeUSFlOz <= 206 THEN 174.96                                                       
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
         END
         )            


        IF UPPER(@ProductCategoryName) LIKE '%ENGLISH STYLE%'
        SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 3  THEN 0
            WHEN @VolumeUSFlOz <= 5 THEN 3.73 -- 4oz
            WHEN @VolumeUSFlOz <= 10.5 THEN 7.45 -- 8oz
            WHEN @VolumeUSFlOz <= 26 THEN 14.90 -- 16oz
            WHEN @VolumeUSFlOz <= 40 THEN 29.8 -- 2x16oz
            WHEN @VolumeUSFlOz <= 60 THEN 44.7
            WHEN @VolumeUSFlOz <= 72 THEN 59.6
            WHEN @VolumeUSFlOz <= 85 THEN 74.5                                              
            WHEN @VolumeUSFlOz <= 102 THEN 89.4
            WHEN @VolumeUSFlOz <= 117 THEN 104.3                                             
            WHEN @VolumeUSFlOz <= 135 THEN 119.2
            WHEN @VolumeUSFlOz <= 150 THEN 134.1                                              
            WHEN @VolumeUSFlOz <= 170 THEN 149
            WHEN @VolumeUSFlOz <= 190 THEN 163.9                                              
            WHEN @VolumeUSFlOz <= 206 THEN 178.8                                                       
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
        END
        )

        IF UPPER(@ProductCategoryName) LIKE '%HIGH CARBONATION%'
         SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 3  THEN 0
            WHEN @VolumeUSFlOz <= 5 THEN 3.59 -- 4oz
            WHEN @VolumeUSFlOz <= 10.5 THEN 7.18 -- 8oz
            WHEN @VolumeUSFlOz <= 26 THEN 14.36 -- 16oz
            WHEN @VolumeUSFlOz <= 40 THEN 28.72 -- 2x16oz
            WHEN @VolumeUSFlOz <= 60 THEN 43.08
            WHEN @VolumeUSFlOz <= 72 THEN 57.44
            WHEN @VolumeUSFlOz <= 85 THEN 71.8                                              
            WHEN @VolumeUSFlOz <= 102 THEN 86.16
            WHEN @VolumeUSFlOz <= 117 THEN 100.52                                               
            WHEN @VolumeUSFlOz <= 135 THEN 114.88
            WHEN @VolumeUSFlOz <= 150 THEN 129.24                                              
            WHEN @VolumeUSFlOz <= 170 THEN 143.6
            WHEN @VolumeUSFlOz <= 190 THEN 157.96                                              
            WHEN @VolumeUSFlOz <= 206 THEN 172.32                                                       
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
        END
        )                          

        IF UPPER(@ProductCategoryName) LIKE '%NITRO POURS%'
         SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 3  THEN 0
            WHEN @VolumeUSFlOz <= 5 THEN 3.67 -- 4oz
            WHEN @VolumeUSFlOz <= 10.5 THEN 7.33 -- 8oz
            WHEN @VolumeUSFlOz <= 26 THEN 14.67 -- 16oz
            WHEN @VolumeUSFlOz <= 40 THEN 29.34 -- 2x16oz
            WHEN @VolumeUSFlOz <= 60 THEN 44.01
            WHEN @VolumeUSFlOz <= 72 THEN 58.68
            WHEN @VolumeUSFlOz <= 85 THEN 73.35                                             
            WHEN @VolumeUSFlOz <= 102 THEN 88.02
            WHEN @VolumeUSFlOz <= 117 THEN 102.69                                              
            WHEN @VolumeUSFlOz <= 135 THEN 117.36
            WHEN @VolumeUSFlOz <= 150 THEN 132.03                                              
            WHEN @VolumeUSFlOz <= 170 THEN 146.7
            WHEN @VolumeUSFlOz <= 190 THEN 161.37                                               
            WHEN @VolumeUSFlOz <= 206 THEN 176.04                                                       
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
        END
        )                          

       IF UPPER(@ProductCategoryName) LIKE '%SOUR BEERS%'
        SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 3  THEN 0
            WHEN @VolumeUSFlOz <= 5 THEN 3.75 -- 4oz
            WHEN @VolumeUSFlOz <= 10.5 THEN 7.49 -- 8oz
            WHEN @VolumeUSFlOz <= 26 THEN 14.99 -- 16oz
            WHEN @VolumeUSFlOz <= 40 THEN 29.98 -- 2x16oz
            WHEN @VolumeUSFlOz <= 60 THEN 44.97
            WHEN @VolumeUSFlOz <= 72 THEN 59.96
            WHEN @VolumeUSFlOz <= 85 THEN 74.95                                             
            WHEN @VolumeUSFlOz <= 102 THEN 89.94
            WHEN @VolumeUSFlOz <= 117 THEN 104.93                                              
            WHEN @VolumeUSFlOz <= 135 THEN 119.92
            WHEN @VolumeUSFlOz <= 150 THEN 134.91                                              
            WHEN @VolumeUSFlOz <= 170 THEN 149.9
            WHEN @VolumeUSFlOz <= 190 THEN 164.89                                              
            WHEN @VolumeUSFlOz <= 206 THEN 179.88                                                       
           ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
        END
        )                          

       IF UPPER(@ProductCategoryName) LIKE '%BARREL AGED BEERS%'
        SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 2.4  THEN 0
            WHEN @VolumeUSFlOz <= 4.6 THEN 3.64 -- 4oz
            WHEN @VolumeUSFlOz <= 8.6 THEN 5.46 -- 6oz
            WHEN @VolumeUSFlOz <= 19 THEN 10.92 -- 12oz
            WHEN @VolumeUSFlOz <= 33 THEN 21.84 -- 2x12oz
            WHEN @VolumeUSFlOz <= 47 THEN 32.76
            WHEN @VolumeUSFlOz <= 61 THEN 43.68
            WHEN @VolumeUSFlOz <= 75 THEN 54.6                                             
            WHEN @VolumeUSFlOz <= 89 THEN 65.52
            WHEN @VolumeUSFlOz <= 103 THEN 76.44                                              
            WHEN @VolumeUSFlOz <= 117 THEN 87.36
            WHEN @VolumeUSFlOz <= 131 THEN 92.28                                               
            WHEN @VolumeUSFlOz <= 145 THEN 109.2
            WHEN @VolumeUSFlOz <= 159 THEN 120.12                                              
            WHEN @VolumeUSFlOz <= 173 THEN 131.04                                                        
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2

        END
        )                                          
 
	END
	
    ElSE IF @DrinkParameter = 47
    BEGIN
        --- 47 = US Fl Oz (Levy Restaurants Chase Field)

        SELECT @Drinks = (
           CASE
			WHEN @VolumeUSFlOz <=1 THEN 0
			WHEN @VolumeUSFlOz <=7 THEN 1
			WHEN @VolumeUSFlOz <=10 THEN 9.25
			WHEN @VolumeUSFlOz <=12 THEN 11.25
			WHEN @VolumeUSFlOz <=16 THEN 13 --(1x 13oz Drink)
			WHEN @VolumeUSFlOz <=22 THEN 18.5 --(1x 18.5oz Drink)
			WHEN @VolumeUSFlOz <=28 THEN 22.5 --(1x 22.5oz Drink)
			WHEN @VolumeUSFlOz <=32 THEN 26 --(2x 13oz Drinks)
			WHEN @VolumeUSFlOz <=46 THEN 37 --(2x 18.5oz Drinks)
			WHEN @VolumeUSFlOz <=50 THEN 39  --(3x 13oz Drinks)
			WHEN @VolumeUSFlOz <=60 THEN 45 --(2x 22.5oz Drinks)
			WHEN @VolumeUSFlOz <=70 THEN 55.5 --(3x 18.5oz Drinks)
			WHEN @VolumeUSFlOz <=80 THEN 67.5 --(3x 22.5oz Drinks)
			WHEN @VolumeUSFlOz <=90 THEN 74 --(4x 18.5oz Drinks)
			WHEN @VolumeUSFlOz <=105 THEN 90 --(4x 22.5oz Drinks)
           ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
           END
        )    
    END
	
	ElSE IF @DrinkParameter = 48
	BEGIN
		--- 48 = US Fl Oz (Boston's Gourmet Pizza)

		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=0.9 THEN 0
			WHEN @VolumeUSFlOz <=12 THEN 1			
			WHEN @VolumeUSFlOz <=18 THEN 14 --(1x 16oz Drink)
			WHEN @VolumeUSFlOz <=38 THEN 29 --(1x 32oz Drink)
			WHEN @VolumeUSFlOz <=45 THEN 42 --(3x 16oz Drinks)
			WHEN @VolumeUSFlOz <=65 THEN 56 --(2x 32oz Drinks)
			WHEN @VolumeUSFlOz <=75 THEN 70  --(5x 16oz Drinks)
			WHEN @VolumeUSFlOz <=95 THEN 87  --(3x 32oz Drinks)
			WHEN @VolumeUSFlOz <=160 THEN 112  --(1x 120 Drinks)
			WHEN @VolumeUSFlOz <=230 THEN 224  --(2x 120oz Drinks)
			WHEN @VolumeUSFlOz <=340 THEN 336  --(3x 120oz Drinks)			
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
		)     
	END
	
	ElSE IF @DrinkParameter = 49
	BEGIN
			--- 49 = US Fl Oz (Boston's Gourmet Pizza - Irving)

		SELECT @Drinks = (

			CASE
			WHEN @VolumeUSFlOz <=0.9 THEN 0
			WHEN @VolumeUSFlOz <=12 THEN 1                          
			WHEN @VolumeUSFlOz <=18 THEN 14 --(1x 16oz Drink)
			WHEN @VolumeUSFlOz <=25 THEN 21 --(1x 23oz Drink)
			WHEN @VolumeUSFlOz <=38 THEN 29 --(1x 32oz Drink)
			WHEN @VolumeUSFlOz <=50 THEN 42 --(3x 16oz Drinks)
			WHEN @VolumeUSFlOz <=75 THEN 60 --(1x 64oz Drinks)
			WHEN @VolumeUSFlOz <=95 THEN 87  --(3x 32oz Drinks)
			WHEN @VolumeUSFlOz <=140 THEN 120  --(2x 64oz Drinks)
			WHEN @VolumeUSFlOz <=200 THEN 180  --(3x 64oz Drinks)
			WHEN @VolumeUSFlOz <=270 THEN 240  --(4x 64oz Drinks)              
			WHEN @VolumeUSFlOz <=350 THEN 300  --(5x 64oz Drinks)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END

		)    

	END
	
	ElSE IF @DrinkParameter = 50
    BEGIN
        --- 50= US Fl Oz (Brixx Pizza Cincinnati)
        SELECT @Drinks = (
           CASE
			WHEN @VolumeUSFlOz <=0.75 THEN 0
			WHEN @VolumeUSFlOz <=2 THEN 2
			WHEN @VolumeUSFlOz <=6 THEN 4
			WHEN @VolumeUSFlOz <=11 THEN 8 --(1x 10oz Drink)
			WHEN @VolumeUSFlOz <=17 THEN 13 --(1x 14oz Drink)
			WHEN @VolumeUSFlOz <=23 THEN 19 --(2x 10oz Drinks)
			WHEN @VolumeUSFlOz <=30 THEN 26 --(2x 14oz Drinks)
			WHEN @VolumeUSFlOz <=42 THEN 39 --(3x 14oz Drink)
			WHEN @VolumeUSFlOz <=60 THEN 52 --(4x 14oz Drink)
			WHEN @VolumeUSFlOz <=75 THEN 64 --(1x 64oz Growler)
			WHEN @VolumeUSFlOz <=150 THEN 128 --(2x 64oz Growler)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END

        )   

    END
	
	ElSE IF @DrinkParameter = 51
    BEGIN
        --- 51 = US Fl Oz (Real Mex - Chevy's)
        SELECT @Drinks = (
           CASE
			WHEN @VolumeUSFlOz <=0.5 THEN 0
			WHEN @VolumeUSFlOz <=10 THEN 1
			WHEN @VolumeUSFlOz <=17 THEN 12	--(1x 14oz Drink)	
			WHEN @VolumeUSFlOz <=21 THEN 19 --(1x 21oz Drink)
			WHEN @VolumeUSFlOz <=30 THEN 22	--(1x 24oz Drink)
			WHEN @VolumeUSFlOz <=40 THEN 38 --(2x 21oz Drinks)
			WHEN @VolumeUSFlOz <=50 THEN 44 --(2x 24oz Drinks)
			WHEN @VolumeUSFlOz <=65 THEN 47 --(3x 21oz Drink)
			WHEN @VolumeUSFlOz <=75 THEN 66 --(3x 24oz Drink)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
			)

		-- BELOW RULE IS FOR MARGARITA
		IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=0.5 THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 5 --(5oz Regular Margarita)
			WHEN @VolumeUSFlOz <=16 THEN 12 --(12oz 'Grande' Margarita)      
			WHEN @VolumeUSFlOz <=25 THEN 24 --(2x 12oz 'Grande' Margarita) 
			WHEN @VolumeUSFlOz <=40 THEN 30 --(30oz Pitcher Margarita)
			WHEN @VolumeUSFlOz <=80 THEN 60 --(1x 21oz Drink)
			WHEN @VolumeUSFlOz <=110 THEN 100 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=160 THEN 150 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=210 THEN 200 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=260 THEN 250 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=310 THEN 300 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=360 THEN 350 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=410 THEN 400 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=460 THEN 450 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=510 THEN 500 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=560 THEN 550 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=610 THEN 600 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=660 THEN 650 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=710 THEN 700 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=760 THEN 750 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=810 THEN 800 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=860 THEN 850 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=910 THEN 900 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=960 THEN 950 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=1100 THEN 1000 --(Frozen Margarita Flush/fill)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END                             
            )			
    END
                                       
	ElSE IF @DrinkParameter = 52
    BEGIN
        --- 52 = US Fl Oz (Real Mex - El Torito)
 
        SELECT @Drinks = (
           CASE
			WHEN @VolumeUSFlOz <=0.5 THEN 0
			WHEN @VolumeUSFlOz <=10 THEN 1
			WHEN @VolumeUSFlOz <=18 THEN 14 --(1x 16oz Drink)         
			WHEN @VolumeUSFlOz <=21 THEN 19 --(1x 21oz Drink)
			WHEN @VolumeUSFlOz <=27 THEN 22 --(1x 24oz Drink)
			WHEN @VolumeUSFlOz <=34 THEN 28 --(2x 16oz Drink)
			WHEN @VolumeUSFlOz <=40 THEN 38 --(2x 21oz Drinks)
			WHEN @VolumeUSFlOz <=50 THEN 44 --(2x 24oz Drinks)
			WHEN @VolumeUSFlOz <=65 THEN 47 --(3x 21oz Drink)
			WHEN @VolumeUSFlOz <=75 THEN 66 --(3x 24oz Drink)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
           END
        )
		
			-- BELOW RULE IS FOR MARGARITA
		IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <=2 THEN 0
			WHEN @VolumeUSFlOz <=8 THEN 4.5 --(5oz Regular Margarita)
			WHEN @VolumeUSFlOz <=16 THEN 12 --(12oz 'Grande' Margarita)      
			WHEN @VolumeUSFlOz <=25 THEN 24 --(2x 12oz 'Grande' Margarita) 
			WHEN @VolumeUSFlOz <=40 THEN 30 --(30oz Pitcher Margarita)
			WHEN @VolumeUSFlOz <=80 THEN 60 --(1x 21oz Drink)
			WHEN @VolumeUSFlOz <=110 THEN 100 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=160 THEN 150 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=210 THEN 200 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=260 THEN 250 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=310 THEN 300 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=360 THEN 350 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=410 THEN 400 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=460 THEN 450 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=510 THEN 500 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=560 THEN 550 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=610 THEN 600 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=660 THEN 650 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=710 THEN 700 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=760 THEN 750 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=810 THEN 800 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=860 THEN 850 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=910 THEN 900 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=960 THEN 950 --(Frozen Margarita Flush/fill)
			WHEN @VolumeUSFlOz <=1100 THEN 1000 --(Frozen Margarita Flush/fill)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END                            
            )
	END
			
	ElSE IF @DrinkParameter = 53
    BEGIN
        --- 53 = (Worlds End Tank Beer)
		SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 22 THEN 0.0
			WHEN @PercentageOfPint <= 27 THEN 0.25
			WHEN @PercentageOfPint <= 68 THEN 0.5
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 170 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 320 THEN 3
			WHEN @PercentageOfPint <= 330 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			WHEN @PercentageOfPint <= 440 THEN 4.5
			WHEN @PercentageOfPint <= 510 THEN 5
			WHEN @PercentageOfPint <= 550 THEN 5.5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
 
		IF UPPER(@ProductCategoryName) LIKE '%STANDARD LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 33 THEN 0.25
			WHEN @PercentageOfPint <= 62 THEN 0.5
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 135 THEN 1.25
			WHEN @PercentageOfPint <= 164 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 321 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			WHEN @PercentageOfPint <= 470 THEN 4.5
			WHEN @PercentageOfPint <= 520 THEN 5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
 
		ELSE IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 33 THEN 0.25
			WHEN @PercentageOfPint <= 55 THEN 0.5
			WHEN @PercentageOfPint <= 75 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 135 THEN 1.5
			WHEN @PercentageOfPint <= 190 THEN 2
			WHEN @PercentageOfPint <= 230 THEN 2.5
			WHEN @PercentageOfPint <= 280 THEN 3
			WHEN @PercentageOfPint <= 320 THEN 3.5
			WHEN @PercentageOfPint <= 370 THEN 4
			WHEN @PercentageOfPint <= 420 THEN 4.5
			WHEN @PercentageOfPint <= 550 THEN 5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
		   
		ELSE IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 63 THEN 0.5
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 160 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
		   
		ELSE IF UPPER(@ProductCategoryName) LIKE '%ALE - KEG%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 36 THEN 0.25
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 86 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 155 THEN 1.5
			WHEN @PercentageOfPint <= 180 THEN 1.75
			WHEN @PercentageOfPint <= 210 THEN 2
			WHEN @PercentageOfPint <= 230 THEN 2.25
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 320 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
		   
		ElSE IF UPPER(@ProductCategoryName) LIKE '%ALE - CASK%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 34 THEN 0.25
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 85 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 129 THEN 1.25
			WHEN @PercentageOfPint <= 155 THEN 1.5
			WHEN @PercentageOfPint <= 173 THEN 1.75
			WHEN @PercentageOfPint <= 230 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
				 
		ELSE IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 34 THEN 0.25
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 81 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 131 THEN 1.25
			WHEN @PercentageOfPint <= 169 THEN 1.5
			WHEN @PercentageOfPint <= 180 THEN 1.75
			WHEN @PercentageOfPint <= 230 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 320 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)       
    END
			
	ELSE IF @DrinkParameter = 54
	BEGIN 
		--Start of type 54 this is for Chillis Deland---------------------------------------------------------------------------------
		---US flo oz 10, 14 & 20 glass sizes - Target Sizes US flo oz 19, 12 & 8
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5  THEN 0
			WHEN @VolumeUSFlOz <= 11.5 THEN 8 -- 1 x 10oz Glass (Target Size 8oz)
			WHEN @VolumeUSFlOz <= 15 THEN 12 -- 1 x 14oz (Target Size 12oz)
			WHEN @VolumeUSFlOz <= 16.5 THEN 16 -- 2 x 10oz Glass (Target Size 16oz)
			WHEN @VolumeUSFlOz <= 25 THEN 19 -- 1 x 22oz Glass (Target Size 19oz)
			WHEN @VolumeUSFlOz <= 30 THEN 24 -- 2 x 14oz Glass & 3 x 10oz Glass (Target Size 24oz)
			WHEN @VolumeUSFlOz <= 34 THEN 32 -- 4 x 10oz Glass
			WHEN @VolumeUSFlOz <= 46 THEN 38 -- 2 x 22oz Glass (Target Size 38oz)
			WHEN @VolumeUSFlOz <= 54 THEN 48 -- 4 x 14oz Glass (Target Size 48oz)
			WHEN @VolumeUSFlOz <= 72 THEN 57 -- 3 x 22oz Glass (Target Size 57oz)
			WHEN @VolumeUSFlOz <= 92 THEN 76 -- 4 x 22oz Glass (Target Size 76oz)
			WHEN @VolumeUSFlOz <= 120 THEN 95 -- 5 x 22oz Glass (Target Size (95oz)
			WHEN @VolumeUSFlOz <= 150 THEN 114 -- 6 x 22oz Glass (Target Size 114oz)
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
		END
		)
	END
	
	ELSE IF @DrinkParameter = 55
	BEGIN

		--Start of type 55 this is for Outback Steakhouse---------------------------------------------------------------------------------
		---US flo oz 16oz - Pint & 22oz -Big Bloke glass sizes - Target Sizes US flo oz 13oz & 18.5oz

		SELECT @Drinks = (
            CASE
            WHEN @VolumeUSFlOz <= 2.5 THEN 0
            WHEN @VolumeUSFlOz <= 5.5 THEN 3.68 -- Beer sample
			WHEN @VolumeUSFlOz <= 11 THEN 6.5  -- 1/2 16oz (Targer Size 6.5oz)
            WHEN @VolumeUSFlOz <= 16.99 THEN 13 -- 1 x 16oz (Target Size 13oz)
            WHEN @VolumeUSFlOz <= 24.5 THEN 18.5 -- 1 x 22oz Glass (Target Size 18.5oz)
            WHEN @VolumeUSFlOz <= 34 THEN 26 -- 2 x 16oz Glass (Target Size 26oz)
            WHEN @VolumeUSFlOz <= 46 THEN 37 -- 2 x 22oz Glass (Target Size 37oz) or 3 x 16oz (Targer of 39oz - 2oz variance)
            WHEN @VolumeUSFlOz <= 70 THEN 55.5 -- 3 x 22oz Glass (Target Size 55.5oz)
			WHEN @VolumeUSFlOz <= 96 THEN 74 -- 4 x 22oz Glass (Target Size 74oz)
			WHEN @VolumeUSFlOz <= 120 THEN 92.5 -- 5 x 22oz Glass (Target Size 92.5oz)
			WHEN @VolumeUSFlOz <= 144 THEN 111 -- 6 x 22oz Glass (Target Size 111oz)
			WHEN @VolumeUSFlOz <= 168 THEN 129.5 -- 7 x 22oz Glass (Target Size 129.5oz)
			WHEN @VolumeUSFlOz <= 192 THEN 148 -- 8 x 22oz Glass (Target Size 148oz)
			WHEN @VolumeUSFlOz <= 216 THEN 166.5 -- 9 x 22oz Glass (Target Size 166.5oz)
			WHEN @VolumeUSFlOz <= 240 THEN 185 -- 10 x 22oz Glass (Target Size 185oz)
			WHEN @VolumeUSFlOz <= 264 THEN 203.5 -- 11 x 22oz Glass (Target Size 203.5oz)
			WHEN @VolumeUSFlOz <= 288 THEN 222 -- 12 x 22oz Glass (Target Size 222oz)
			WHEN @VolumeUSFlOz <= 312 THEN 240.5 -- 13 x 22oz Glass (Target Size 240.5oz)
			WHEN @VolumeUSFlOz <= 336 THEN 259 -- 14 x 22oz Glass (Target Size 259oz)
			WHEN @VolumeUSFlOz <= 360 THEN 277.5 -- 15 x 22oz Glass (Target Size 277.5oz)                                          
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
			)

        -- PREMIUM LAGER = Stella glass is 17oz and target size is 15.4oz, BB Glass is 22oz and target size is 18.5--               

		IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			SELECT @Drinks = (
			CASE
            WHEN @VolumeUSFlOz <= 2.5  THEN 0
            WHEN @VolumeUSFlOz <= 5.5  THEN 3.68 -- Beer Sample size
            WHEN @VolumeUSFlOz <= 11 THEN 7.7  -- 1/2 17oz (Target size 7.7oz)
            WHEN @VolumeUSFlOz <= 18 THEN 15.4 -- 1 x 17oz (Target Size 15.4oz)
            WHEN @VolumeUSFlOz <= 24 THEN 18.5 -- 1 x 22oz Glass (Target Size 18.5oz)
            WHEN @VolumeUSFlOz <= 36 THEN 30.8 -- 2 x 17oz Glass (Target Size 30.8oz)
            WHEN @VolumeUSFlOz <= 48 THEN 37 -- 2 x 22oz Glass (Target Size 37oz)
            WHEN @VolumeUSFlOz <= 53 THEN 46.2 -- 3 x 17oz Glass (Target Size 46.2oz)
            WHEN @VolumeUSFlOz <= 72 THEN 55.5 -- 3 x 22oz Glass (Target Size 55.5oz)                                        
			WHEN @VolumeUSFlOz <= 96 THEN 74 -- 4 x 22oz Glass (Target Size 74oz)
			WHEN @VolumeUSFlOz <= 120 THEN 92.5 -- 5 x 22oz Glass (Target Size 92.5oz)
			WHEN @VolumeUSFlOz <= 144 THEN 111 -- 6 x 22oz Glass (Target Size 111oz)
			WHEN @VolumeUSFlOz <= 168 THEN 129.5 -- 7 x 22oz Glass (Target Size 129.5oz)
			WHEN @VolumeUSFlOz <= 192 THEN 148 -- 8 x 22oz Glass (Target Size 148oz)
			WHEN @VolumeUSFlOz <= 216 THEN 166.5 -- 9 x 22oz Glass (Target Size 166.5oz)
			WHEN @VolumeUSFlOz <= 240 THEN 185 -- 10 x 22oz Glass (Target Size 185oz)
			WHEN @VolumeUSFlOz <= 264 THEN 203.5 -- 11 x 22oz Glass (Target Size 203.5oz)
			WHEN @VolumeUSFlOz <= 288 THEN 222 -- 12 x 22oz Glass (Target Size 222oz)
			WHEN @VolumeUSFlOz <= 312 THEN 240.5 -- 13 x 22oz Glass (Target Size 240.5oz)
			WHEN @VolumeUSFlOz <= 336 THEN 259 -- 14 x 22oz Glass (Target Size 259oz)
			WHEN @VolumeUSFlOz <= 360 THEN 277.5 -- 15 x 22oz Glass (Target Size 277.5oz)
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
			END
			)
		END
	
	ELSE IF @DrinkParameter = 56
    BEGIN
		--Start of type 56 this is for Chillis Land O Lakes---------------------------------------------------------------------------------
		---US flo oz Target Sizes are 8oz, 13oz & 19oz - Glass Sizes are 10oz,16oz & 22oz 
		SELECT @Drinks = (
			CASE
			WHEN @VolumeUSFlOz <= 5 THEN 0 
			WHEN @VolumeUSFlOz <=12.5 THEN 8 -- 1x 10oz pours
			WHEN @VolumeUSFlOz <=17 THEN 13 -- 1x 13oz pours
			WHEN @VolumeUSFlOz <=26 THEN 19 -- 1x 19oz pours
			WHEN @VolumeUSFlOz <=34 THEN 26 -- 2x 13oz pours
			WHEN @VolumeUSFlOz <=46 THEN 38 -- 2x 19oz pours (or 3x 13oz with 1oz variance)
			WHEN @VolumeUSFlOz <=70 THEN 57 -- 3x 19oz pours
			WHEN @VolumeUSFlOz <=92 THEN 76 -- 4x 19oz pours
			WHEN @VolumeUSFlOz <=120 THEN 95 -- 5x 19oz pours
			WHEN @VolumeUSFlOz <=140 THEN 114 -- 6x 19oz pours
			WHEN @VolumeUSFlOz <=160 THEN 133 -- 7x 19oz pours
			WHEN @VolumeUSFlOz <=180 THEN 152 -- 8x 19oz pours
			WHEN @VolumeUSFlOz <=210 THEN 171 -- 9x 19oz pours
			WHEN @VolumeUSFlOz <=240 THEN 190 -- 10x 19oz pours
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100.00)*2, 0)/2
		END
       )
	END
	   
	ELSE IF @DrinkParameter = 57
    BEGIN
        --Start of type 57 - St Austell - Samuel Jones-------------------------------------------------------------------
        IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
           SELECT @Drinks = (
           CASE
           WHEN @PercentageOfPint <= 9 THEN 0.0
           WHEN @PercentageOfPint <= 15 THEN 0.1
           WHEN @PercentageOfPint <= 29 THEN 0.25
           WHEN @PercentageOfPint <= 39 THEN 0.33                                      
           WHEN @PercentageOfPint <= 59 THEN 0.5
           WHEN @PercentageOfPint <= 70 THEN 0.66                                       
           WHEN @PercentageOfPint <= 80 THEN 0.75
           WHEN @PercentageOfPint <= 91 THEN 0.9
           WHEN @PercentageOfPint <= 120 THEN 1
           WHEN @PercentageOfPint <= 129 THEN 1.25
           WHEN @PercentageOfPint <= 139 THEN 1.33                                     
           WHEN @PercentageOfPint <= 159 THEN 1.5
           WHEN @PercentageOfPint <= 170 THEN 1.66
           WHEN @PercentageOfPint <= 180 THEN 1.75
           WHEN @PercentageOfPint <= 190 THEN 1.90
           WHEN @PercentageOfPint <= 210 THEN 2
           WHEN @PercentageOfPint <= 229 THEN 2.25
           WHEN @PercentageOfPint <= 239 THEN 2.33                                    
           WHEN @PercentageOfPint <= 259 THEN 2.5
           WHEN @PercentageOfPint <= 270 THEN 2.66
           WHEN @PercentageOfPint <= 280 THEN 2.75
           WHEN @PercentageOfPint <= 290 THEN 2.9
           WHEN @PercentageOfPint <= 310 THEN 3
           WHEN @PercentageOfPint <= 329 THEN 3.25
           WHEN @PercentageOfPint <= 339 THEN 3.33
           WHEN @PercentageOfPint <= 360 THEN 3.5
           WHEN @PercentageOfPint <= 420 THEN 4
           WHEN @PercentageOfPint <= 470 THEN 4.5
           WHEN @PercentageOfPint <= 520 THEN 5
           ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
        END
       )

                     
    ELSE IF UPPER(@ProductCategoryName) LIKE '%STANDARD LAGER%'
            SELECT @Drinks = (
            CASE
            WHEN @PercentageOfPint <= 9 THEN 0.0
            WHEN @PercentageOfPint <= 15 THEN 0.1
            WHEN @PercentageOfPint <= 29 THEN 0.25
            WHEN @PercentageOfPint <= 39 THEN 0.33                                      
            WHEN @PercentageOfPint <= 59 THEN 0.5
            WHEN @PercentageOfPint <= 70 THEN 0.66                                      
            WHEN @PercentageOfPint <= 80 THEN 0.75
            WHEN @PercentageOfPint <= 91 THEN 0.9
            WHEN @PercentageOfPint <= 120 THEN 1
            WHEN @PercentageOfPint <= 129 THEN 1.25
            WHEN @PercentageOfPint <= 139 THEN 1.33                                    
            WHEN @PercentageOfPint <= 159 THEN 1.5
            WHEN @PercentageOfPint <= 170 THEN 1.66
            WHEN @PercentageOfPint <= 180 THEN 1.75
            WHEN @PercentageOfPint <= 190 THEN 1.90
            WHEN @PercentageOfPint <= 210 THEN 2
            WHEN @PercentageOfPint <= 229 THEN 2.25
            WHEN @PercentageOfPint <= 239 THEN 2.33                                    
            WHEN @PercentageOfPint <= 259 THEN 2.5
            WHEN @PercentageOfPint <= 270 THEN 2.66
            WHEN @PercentageOfPint <= 280 THEN 2.75
            WHEN @PercentageOfPint <= 290 THEN 2.9
            WHEN @PercentageOfPint <= 310 THEN 3
            WHEN @PercentageOfPint <= 329 THEN 3.25
            WHEN @PercentageOfPint <= 339 THEN 3.33
            WHEN @PercentageOfPint <= 360 THEN 3.5
            WHEN @PercentageOfPint <= 420 THEN 4
            WHEN @PercentageOfPint <= 470 THEN 4.5
            WHEN @PercentageOfPint <= 520 THEN 5
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
         END
        )

                       
    ELSE IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
            SELECT @Drinks = (
            CASE
            WHEN @PercentageOfPint <= 9 THEN 0.0
            WHEN @PercentageOfPint <= 15 THEN 0.1
            WHEN @PercentageOfPint <= 29 THEN 0.25
            WHEN @PercentageOfPint <= 39 THEN 0.33                                      
            WHEN @PercentageOfPint <= 59 THEN 0.5
            WHEN @PercentageOfPint <= 70 THEN 0.66                                      
            WHEN @PercentageOfPint <= 80 THEN 0.75
            WHEN @PercentageOfPint <= 91 THEN 0.9
            WHEN @PercentageOfPint <= 120 THEN 1
            WHEN @PercentageOfPint <= 129 THEN 1.25
            WHEN @PercentageOfPint <= 139 THEN 1.33                                    
            WHEN @PercentageOfPint <= 159 THEN 1.5
            WHEN @PercentageOfPint <= 170 THEN 1.66
            WHEN @PercentageOfPint <= 180 THEN 1.75
            WHEN @PercentageOfPint <= 190 THEN 1.90
            WHEN @PercentageOfPint <= 210 THEN 2
            WHEN @PercentageOfPint <= 229 THEN 2.25
            WHEN @PercentageOfPint <= 239 THEN 2.33                                    
            WHEN @PercentageOfPint <= 259 THEN 2.5
            WHEN @PercentageOfPint <= 270 THEN 2.66
            WHEN @PercentageOfPint <= 280 THEN 2.75
            WHEN @PercentageOfPint <= 290 THEN 2.9
            WHEN @PercentageOfPint <= 310 THEN 3
            WHEN @PercentageOfPint <= 329 THEN 3.25
            WHEN @PercentageOfPint <= 339 THEN 3.33
            WHEN @PercentageOfPint <= 360 THEN 3.5
            WHEN @PercentageOfPint <= 420 THEN 4
            WHEN @PercentageOfPint <= 470 THEN 4.5
            WHEN @PercentageOfPint <= 520 THEN 5
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
         END
        )

             
    ELSE IF UPPER(@ProductCategoryName) LIKE '%ALE - KEG%'
            SELECT @Drinks = (
            CASE
            WHEN @PercentageOfPint <= 9 THEN 0.0
            WHEN @PercentageOfPint <= 15 THEN 0.1
            WHEN @PercentageOfPint <= 29 THEN 0.25
            WHEN @PercentageOfPint <= 39 THEN 0.33                                       
            WHEN @PercentageOfPint <= 59 THEN 0.5
            WHEN @PercentageOfPint <= 70 THEN 0.66                                      
            WHEN @PercentageOfPint <= 80 THEN 0.75
            WHEN @PercentageOfPint <= 91 THEN 0.9
            WHEN @PercentageOfPint <= 120 THEN 1
            WHEN @PercentageOfPint <= 129 THEN 1.25
            WHEN @PercentageOfPint <= 139 THEN 1.33                                    
            WHEN @PercentageOfPint <= 159 THEN 1.5
            WHEN @PercentageOfPint <= 170 THEN 1.66
            WHEN @PercentageOfPint <= 180 THEN 1.75
            WHEN @PercentageOfPint <= 190 THEN 1.90
            WHEN @PercentageOfPint <= 210 THEN 2
            WHEN @PercentageOfPint <= 229 THEN 2.25
            WHEN @PercentageOfPint <= 239 THEN 2.33                                    
            WHEN @PercentageOfPint <= 259 THEN 2.5
            WHEN @PercentageOfPint <= 270 THEN 2.66
            WHEN @PercentageOfPint <= 280 THEN 2.75
            WHEN @PercentageOfPint <= 290 THEN 2.9
            WHEN @PercentageOfPint <= 310 THEN 3
            WHEN @PercentageOfPint <= 329 THEN 3.25
            WHEN @PercentageOfPint <= 339 THEN 3.33
            WHEN @PercentageOfPint <= 360 THEN 3.5
            WHEN @PercentageOfPint <= 420 THEN 4
            WHEN @PercentageOfPint <= 470 THEN 4.5
            WHEN @PercentageOfPint <= 520 THEN 5
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
         END
        )

             
    ElSE IF UPPER(@ProductCategoryName) LIKE '%ALE - CASK%'
            SELECT @Drinks = (
            CASE
            WHEN @PercentageOfPint <= 9 THEN 0.0
            WHEN @PercentageOfPint <= 15 THEN 0.1
            WHEN @PercentageOfPint <= 29 THEN 0.25
            WHEN @PercentageOfPint <= 39 THEN 0.33                                      
            WHEN @PercentageOfPint <= 59 THEN 0.5
            WHEN @PercentageOfPint <= 70 THEN 0.66                                      
            WHEN @PercentageOfPint <= 80 THEN 0.75
            WHEN @PercentageOfPint <= 91 THEN 0.9
            WHEN @PercentageOfPint <= 120 THEN 1
            WHEN @PercentageOfPint <= 129 THEN 1.25
            WHEN @PercentageOfPint <= 139 THEN 1.33                                    
            WHEN @PercentageOfPint <= 159 THEN 1.5
            WHEN @PercentageOfPint <= 170 THEN 1.66
            WHEN @PercentageOfPint <= 180 THEN 1.75
            WHEN @PercentageOfPint <= 190 THEN 1.90
            WHEN @PercentageOfPint <= 210 THEN 2
            WHEN @PercentageOfPint <= 229 THEN 2.25
            WHEN @PercentageOfPint <= 239 THEN 2.33                                    
            WHEN @PercentageOfPint <= 259 THEN 2.5
            WHEN @PercentageOfPint <= 270 THEN 2.66
            WHEN @PercentageOfPint <= 280 THEN 2.75
            WHEN @PercentageOfPint <= 290 THEN 2.9
            WHEN @PercentageOfPint <= 310 THEN 3
            WHEN @PercentageOfPint <= 329 THEN 3.25
            WHEN @PercentageOfPint <= 339 THEN 3.33
            WHEN @PercentageOfPint <= 360 THEN 3.5
            WHEN @PercentageOfPint <= 420 THEN 4
            WHEN @PercentageOfPint <= 470 THEN 4.5
            WHEN @PercentageOfPint <= 520 THEN 5
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
         END
        )
         
    ELSE IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
            SELECT @Drinks = (
            CASE
            WHEN @PercentageOfPint <= 9 THEN 0.0
            WHEN @PercentageOfPint <= 15 THEN 0.1
            WHEN @PercentageOfPint <= 29 THEN 0.25
            WHEN @PercentageOfPint <= 39 THEN 0.33                                      
            WHEN @PercentageOfPint <= 59 THEN 0.5
            WHEN @PercentageOfPint <= 70 THEN 0.66                                       
            WHEN @PercentageOfPint <= 80 THEN 0.75
            WHEN @PercentageOfPint <= 91 THEN 0.9
            WHEN @PercentageOfPint <= 120 THEN 1
            WHEN @PercentageOfPint <= 129 THEN 1.25
            WHEN @PercentageOfPint <= 139 THEN 1.33                                    
            WHEN @PercentageOfPint <= 159 THEN 1.5
            WHEN @PercentageOfPint <= 170 THEN 1.66
            WHEN @PercentageOfPint <= 180 THEN 1.75
            WHEN @PercentageOfPint <= 190 THEN 1.90
            WHEN @PercentageOfPint <= 210 THEN 2
            WHEN @PercentageOfPint <= 229 THEN 2.25
            WHEN @PercentageOfPint <= 239 THEN 2.33                                    
            WHEN @PercentageOfPint <= 259 THEN 2.5
            WHEN @PercentageOfPint <= 270 THEN 2.66
            WHEN @PercentageOfPint <= 280 THEN 2.75
            WHEN @PercentageOfPint <= 290 THEN 2.9
            WHEN @PercentageOfPint <= 310 THEN 3
            WHEN @PercentageOfPint <= 329 THEN 3.25
            WHEN @PercentageOfPint <= 339 THEN 3.33
            WHEN @PercentageOfPint <= 360 THEN 3.5
            WHEN @PercentageOfPint <= 420 THEN 4
            WHEN @PercentageOfPint <= 470 THEN 4.5
            WHEN @PercentageOfPint <= 520 THEN 5
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
         END
        )
               
    ELSE

            SELECT @Drinks = (
            CASE
            WHEN @PercentageOfPint <= 9 THEN 0.0
            WHEN @PercentageOfPint <= 15 THEN 0.1
            WHEN @PercentageOfPint <= 29 THEN 0.25
            WHEN @PercentageOfPint <= 39 THEN 0.33                                      
            WHEN @PercentageOfPint <= 59 THEN 0.5
            WHEN @PercentageOfPint <= 70 THEN 0.66                                      
            WHEN @PercentageOfPint <= 80 THEN 0.75
            WHEN @PercentageOfPint <= 91 THEN 0.9
            WHEN @PercentageOfPint <= 120 THEN 1
            WHEN @PercentageOfPint <= 129 THEN 1.25
            WHEN @PercentageOfPint <= 139 THEN 1.33                                    
            WHEN @PercentageOfPint <= 159 THEN 1.5
            WHEN @PercentageOfPint <= 170 THEN 1.66
            WHEN @PercentageOfPint <= 180 THEN 1.75
            WHEN @PercentageOfPint <= 190 THEN 1.90
            WHEN @PercentageOfPint <= 210 THEN 2
            WHEN @PercentageOfPint <= 229 THEN 2.25
            WHEN @PercentageOfPint <= 239 THEN 2.33                                    
            WHEN @PercentageOfPint <= 259 THEN 2.5
            WHEN @PercentageOfPint <= 270 THEN 2.66
            WHEN @PercentageOfPint <= 280 THEN 2.75
            WHEN @PercentageOfPint <= 290 THEN 2.9
            WHEN @PercentageOfPint <= 310 THEN 3
            WHEN @PercentageOfPint <= 329 THEN 3.25
            WHEN @PercentageOfPint <= 339 THEN 3.33
            WHEN @PercentageOfPint <= 360 THEN 3.5
            WHEN @PercentageOfPint <= 420 THEN 4
            WHEN @PercentageOfPint <= 470 THEN 4.5
            WHEN @PercentageOfPint <= 520 THEN 5
            ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
         END
         )
	END

	ELSE IF @DrinkParameter = 58
	BEGIN	
	--Start of type 58 - St Austell - With Samples - 1/10 of a pint---------------------------------------------------------------------------------
		IF UPPER(@ProductCategoryName) LIKE '%STANDARD LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 33 THEN 0.25
			WHEN @PercentageOfPint <= 62 THEN 0.5
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 135 THEN 1.25
			WHEN @PercentageOfPint <= 164 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 321 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			WHEN @PercentageOfPint <= 470 THEN 4.5
			WHEN @PercentageOfPint <= 520 THEN 5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)

		ELSE IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 61 THEN 0.5
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 169 THEN 1.5
			WHEN @PercentageOfPint <= 215 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 370 THEN 3.5
			WHEN @PercentageOfPint <= 410 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
	    
		ELSE IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 63 THEN 0.5
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 160 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
	    
		ELSE IF UPPER(@ProductCategoryName) LIKE '%ALE - KEG%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 86 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 155 THEN 1.5
			WHEN @PercentageOfPint <= 180 THEN 1.75
			WHEN @PercentageOfPint <= 210 THEN 2
			WHEN @PercentageOfPint <= 230 THEN 2.25
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 320 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
	    
		ElSE IF UPPER(@ProductCategoryName) LIKE '%ALE - CASK%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 85 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 129 THEN 1.25
			WHEN @PercentageOfPint <= 155 THEN 1.5
			WHEN @PercentageOfPint <= 173 THEN 1.75
			WHEN @PercentageOfPint <= 230 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
	          
		ELSE IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 81 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 131 THEN 1.25
			WHEN @PercentageOfPint <= 169 THEN 1.5
			WHEN @PercentageOfPint <= 180 THEN 1.75
			WHEN @PercentageOfPint <= 230 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 320 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
			END
			)
	    
		ELSE
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 9 THEN 0.0
			WHEN @PercentageOfPint <= 15 THEN 0.1
			WHEN @PercentageOfPint <= 68 THEN 0.5
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 170 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 320 THEN 3
			WHEN @PercentageOfPint <= 330 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			WHEN @PercentageOfPint <= 440 THEN 4.5
			WHEN @PercentageOfPint <= 510 THEN 5
			WHEN @PercentageOfPint <= 550 THEN 5.5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)
			--------------------End of type 58-----------------------
	END
	
	ELSE IF @DrinkParameter = 59
	BEGIN
	--Start of type 59 (Brewhouse & Kitchen)---------------------------------------------------------------------------------
		IF UPPER(@ProductCategoryName) LIKE '%STANDARD LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 39 THEN 0.33
			WHEN @PercentageOfPint <= 60 THEN 0.5
			WHEN @PercentageOfPint <= 69 THEN 0.66
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 135 THEN 1.25
			WHEN @PercentageOfPint <= 164 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 321 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			WHEN @PercentageOfPint <= 470 THEN 4.5
			WHEN @PercentageOfPint <= 520 THEN 5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)

		ELSE IF UPPER(@ProductCategoryName) LIKE '%PREMIUM LAGER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 39 THEN 0.33
			WHEN @PercentageOfPint <= 60 THEN 0.5
			WHEN @PercentageOfPint <= 69 THEN 0.66
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 169 THEN 1.5
			WHEN @PercentageOfPint <= 215 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 370 THEN 3.5
			WHEN @PercentageOfPint <= 410 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)

		ELSE IF UPPER(@ProductCategoryName) LIKE '%CIDER%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 39 THEN 0.33
			WHEN @PercentageOfPint <= 60 THEN 0.5
			WHEN @PercentageOfPint <= 69 THEN 0.66
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 160 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)

		ELSE IF UPPER(@ProductCategoryName) LIKE '%ALE - KEG%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 39 THEN 0.33
			WHEN @PercentageOfPint <= 60 THEN 0.5
			WHEN @PercentageOfPint <= 69 THEN 0.66
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 160 THEN 1.5
			WHEN @PercentageOfPint <= 210 THEN 2
			WHEN @PercentageOfPint <= 230 THEN 2.25
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 320 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)

              
		ElSE IF UPPER(@ProductCategoryName) LIKE '%ALE - CASK%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 39 THEN 0.33
			WHEN @PercentageOfPint <= 60 THEN 0.5
			WHEN @PercentageOfPint <= 69 THEN 0.66
			WHEN @PercentageOfPint <= 80 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 130 THEN 1.25
			WHEN @PercentageOfPint <= 160 THEN 1.5
			WHEN @PercentageOfPint <= 230 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)
           
		ELSE IF UPPER(@ProductCategoryName) LIKE '%STOUT%'
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 15 THEN 0.0
			WHEN @PercentageOfPint <= 30 THEN 0.25
			WHEN @PercentageOfPint <= 39 THEN 0.33
			WHEN @PercentageOfPint <= 59 THEN 0.5
			WHEN @PercentageOfPint <= 69 THEN 0.66
			WHEN @PercentageOfPint <= 81 THEN 0.75
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 131 THEN 1.25
			WHEN @PercentageOfPint <= 169 THEN 1.5
			WHEN @PercentageOfPint <= 180 THEN 1.75
			WHEN @PercentageOfPint <= 230 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 310 THEN 3
			WHEN @PercentageOfPint <= 335 THEN 3.25
			WHEN @PercentageOfPint <= 360 THEN 3.5
			WHEN @PercentageOfPint <= 320 THEN 4
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)
          
		ELSE
			SELECT @Drinks = (
			CASE
			WHEN @PercentageOfPint <= 22 THEN 0.0
			WHEN @PercentageOfPint <= 27 THEN 0.25
			WHEN @PercentageOfPint <= 68 THEN 0.5
			WHEN @PercentageOfPint <= 120 THEN 1
			WHEN @PercentageOfPint <= 170 THEN 1.5
			WHEN @PercentageOfPint <= 220 THEN 2
			WHEN @PercentageOfPint <= 260 THEN 2.5
			WHEN @PercentageOfPint <= 320 THEN 3
			WHEN @PercentageOfPint <= 330 THEN 3.5
			WHEN @PercentageOfPint <= 420 THEN 4
			WHEN @PercentageOfPint <= 440 THEN 4.5
			WHEN @PercentageOfPint <= 510 THEN 5
			WHEN @PercentageOfPint <= 550 THEN 5.5
			ELSE ROUND((CAST(@PercentageOfPint AS FLOAT)/100)*2, 0)/2
		END
		)
			--End of type 59---------------------------------------------------------------------------------
	END

RETURN @Drinks            

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnGetSiteDrinkVolume] TO PUBLIC
    AS [dbo];

