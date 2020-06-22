/*drop functions for converting between units of measurement*/
DROP FUNCTION IF EXISTS num_servings;

/*drops functions for calculating nutrition and cost */
DROP FUNCTION IF EXISTS getCals;
DROP FUNCTION IF EXISTS getCarbs;
DROP FUNCTION IF EXISTS getFat;
DROP FUNCTION IF EXISTS getProt;
DROP FUNCTION IF EXISTS getCost;


/*drops functions for calculating the sum of nutrition and cost for each recipe item */
DROP FUNCTION IF EXISTS recCals;
DROP FUNCTION IF EXISTS recFat;
DROP FUNCTION IF EXISTS recCarbs;
DROP FUNCTION IF EXISTS recProt;
DROP FUNCTION IF EXISTS recCost;
DROP FUNCTION IF EXISTS get_recID;
DROP FUNCTION IF EXISTS get_unitID;
DROP FUNCTION IF EXISTS get_tagID;


/*Drop stored procedures to add ingredients to the database 
#Drop stored procedure to add ingredient to recipe */
DROP PROCEDURE IF EXISTS add_ingredient;
DROP PROCEDURE IF EXISTS add_food_to_recipe;
DROP PROCEDURE IF EXISTS add_conversion_factor;
DROP PROCEDURE IF EXISTS add_tag_to_recipe;




/*Drop Views will go here*/
DROP VIEW IF EXISTS reclist;






/*drops tables */
DROP TABLE IF EXISTS recDB.recipeIngredientList;
DROP TABLE IF EXISTS recDB.ingredients;
DROP TABLE IF EXISTS recDB.unitConversion;
DROP TABLE IF EXISTS recDB.unitMeasurement;
DROP TABLE IF EXISTS recDB.recTagList;
DROP TABLE IF EXISTS recDB.tags;
DROP TABLE IF EXISTS recDB.menuRecList;
DROP TABLE IF EXISTS recDB.recipe;
DROP TABLE IF EXISTS recDB.menu;


/*Create tables -----------------------------------------*/

CREATE TABLE recDB.menu (
	menuID int NOT NULL AUTO_INCREMENT,
    menuName varchar(30),
    menuDesc varchar(100),
    menuCost decimal(12,4),
    menuCalsPerServing decimal(12,4),
	menuFatPerServing decimal(12,4),
    menuCarbsPerServing decimal(12,4),
    menuProteinPerServing decimal(12,4),
	menuRating char(1),
    PRIMARY KEY(menuID),
    UNIQUE(menuName)
);

CREATE TABLE recDB.recipe (
	recipeID int NOT NULL AUTO_INCREMENT,
    recipeName varchar(30) NOT NULL,
    instructions text NOT NULL,
    difficulty char(1) NOT NULL,
    servings int NOT NULL,
    recipeCost decimal(12,4),
	CalsPerServing decimal(12,4),
	FatPerServing decimal(12,4),
    CarbsPerServing decimal(12,4),
    ProteinPerServing decimal(12,4),
	recipeRating char(1),
    recPhoto varchar(100),
    PRIMARY KEY(recipeID),
    UNIQUE(recipeName)
);


/*This menu table is not used in the database*/
CREATE TABLE recDB.menuRecList (
	menuRecListID int NOT NULL AUTO_INCREMENT,
	recipeID int NOT NULL,
	menuID int NOT NULL,
    PRIMARY KEY(menuRecListID),
    FOREIGN KEY(recipeID) REFERENCES recipe(recipeID),
	FOREIGN KEY(menuID) REFERENCES menu(menuID),
    UNIQUE(recipeID,menuID)
);


CREATE TABLE recDB.tags (
	tagID int NOT NULL AUTO_INCREMENT,
	tagName varchar(30) NOT NULL,
    PRIMARY KEY(tagID),
    UNIQUE(tagName)
);



CREATE TABLE recDB.recTagList (
	recTagListID int NOT NULL AUTO_INCREMENT,
	recipeID int NOT NULL,
	tagID int NOT NULL,
    PRIMARY KEY(recTagListID),
    FOREIGN KEY(recipeID) REFERENCES recipe(recipeID),
	FOREIGN KEY(tagID) REFERENCES tags(tagID),
    UNIQUE(recipeID,tagID)
);


CREATE TABLE recDB.unitMeasurement (
	ingredientUnitID int NOT NULL AUTO_INCREMENT,
	unitName varchar(30) NOT NULL,
    PRIMARY KEY(ingredientUnitID),
    UNIQUE(unitName)
);


CREATE TABLE recDB.unitConversion (
	unitConversionID int NOT NULL AUTO_INCREMENT,
	fromUnitID int,
	toUnitID int,
    scaleFactor decimal(12,4),
    PRIMARY KEY(unitConversionID),
    FOREIGN KEY(fromUnitID) REFERENCES unitMeasurement(ingredientUnitID),
    FOREIGN KEY(toUnitID) REFERENCES unitMeasurement(ingredientUnitID),
    UNIQUE(fromUnitID,toUnitID)
);



CREATE TABLE recDB.ingredients (
	ingredientID int NOT NULL AUTO_INCREMENT,
    foodName varchar(30),
	foodDesc varchar(100),
    servingsPerContainer decimal(12,4),
    servingSizeUnitID int,
    servingSizeAmount decimal(12,4),
	CalsPerIngredientServing decimal(12,4),
	FatPerIngredientServing decimal(12,4),
    CarbsPerIngredientServing decimal(12,4),
    ProteinPerIngredientServing decimal(12,4),
	purchaseCost decimal(12,4),
	costPerIngredientServing decimal(12,4),
    UNIQUE(foodName),
    PRIMARY KEY(ingredientID),
    FOREIGN KEY(servingSizeUnitID) REFERENCES unitMeasurement(ingredientUnitID)
);


CREATE TABLE recDB.recipeIngredientList (
	recipeIngredientListID int NOT NULL AUTO_INCREMENT,
    recipeID int NOT NULL,
    ingredientID int NOT NULL,
    ingredientUnitID int NOT NULL, 
    ingredientAmount decimal(12,4) NOT NULL,
	CalsPerIngredientAmount decimal(12,4),
	FatPerIngredientAmount decimal(12,4),
    CarbsPerIngredientAmount decimal(12,4),
    ProteinPerIngredientAmount decimal(12,4),
    CostPerIngredientAmount decimal(12,4),
    PRIMARY KEY(recipeIngredientListID),
	FOREIGN KEY(recipeID) REFERENCES recipe(recipeID),
	FOREIGN KEY(ingredientID) REFERENCES ingredients(ingredientID),
	FOREIGN KEY(ingredientUnitID) REFERENCES unitMeasurement(ingredientUnitID),
    UNIQUE(recipeID,ingredientID)
);


/*Create functions ------------------------------------------------*/

/*This function takes the ingredient amount, serving size, and scale factor 
It calculates an intermediate conversion for translating from ingredient to recipe*/
CREATE FUNCTION num_servings(ing_amount decimal(12,4), s_factor decimal(12,4), serv_size decimal(12,4))
RETURNS decimal(12,4) DETERMINISTIC 
RETURN(ing_amount*s_factor/serv_size);




/*The followng getCals, getCarbs....etc. getCost functions all do similar things 
they take a recID and ingID
The function calls num_servings and multiplies it by the Nutrition Per Serving amount 
The result is the amount of calories or fat etc that an ingredient contributes to a recipe
 */

CREATE FUNCTION getCals(recID int,ingID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN ((SELECT num_servings(
	(SELECT ingredientAmount FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID)
	, (SELECT scaleFactor FROM unitConversion WHERE unitConversion.fromUnitID = (SELECT servingSizeUnitID FROM ingredients WHERE ingredients.ingredientID = ingID)
	   AND unitConversion.toUnitID = (SELECT ingredientUnitID FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID))
	, (SELECT servingSizeAmount FROM ingredients WHERE ingredients.ingredientID = ingID)
	))* 
    (
    SELECT
    ingredients.CalsPerIngredientServing
    FROM ingredients 
    WHERE ingredients.ingredientID = ingID
    )
);

CREATE FUNCTION getCarbs(recID int,ingID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN ((SELECT num_servings(
	(SELECT ingredientAmount FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID)
	, (SELECT scaleFactor FROM unitConversion WHERE unitConversion.fromUnitID = (SELECT servingSizeUnitID FROM ingredients WHERE ingredients.ingredientID = ingID)
	   AND unitConversion.toUnitID = (SELECT ingredientUnitID FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID))
	, (SELECT servingSizeAmount FROM ingredients WHERE ingredients.ingredientID = ingID)
	))* 
    (
    SELECT
    ingredients.CarbsPerIngredientServing
    FROM ingredients 
    WHERE ingredients.ingredientID = ingID
    )
);

CREATE FUNCTION getFat(recID int,ingID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN ((SELECT num_servings(
	(SELECT ingredientAmount FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID)
	, (SELECT scaleFactor FROM unitConversion WHERE unitConversion.fromUnitID = (SELECT servingSizeUnitID FROM ingredients WHERE ingredients.ingredientID = ingID)
	   AND unitConversion.toUnitID = (SELECT ingredientUnitID FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID))
	, (SELECT servingSizeAmount FROM ingredients WHERE ingredients.ingredientID = ingID)
	))* 
    (
    SELECT
    ingredients.FatPerIngredientServing
    FROM ingredients 
    WHERE ingredients.ingredientID = ingID
    )
);

CREATE FUNCTION getProt(recID int,ingID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN ((SELECT num_servings(
	(SELECT ingredientAmount FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID)
	, (SELECT scaleFactor FROM unitConversion WHERE unitConversion.fromUnitID = (SELECT servingSizeUnitID FROM ingredients WHERE ingredients.ingredientID = ingID)
	   AND unitConversion.toUnitID = (SELECT ingredientUnitID FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID))
	, (SELECT servingSizeAmount FROM ingredients WHERE ingredients.ingredientID = ingID)
	))* 
    (
    SELECT
    ingredients.ProteinPerIngredientServing
    FROM ingredients 
    WHERE ingredients.ingredientID = ingID
    )
);


CREATE FUNCTION getCost(recID int,ingID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN ((SELECT num_servings(
	(SELECT ingredientAmount FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID)
	, (SELECT scaleFactor FROM unitConversion WHERE unitConversion.fromUnitID = (SELECT servingSizeUnitID FROM ingredients WHERE ingredients.ingredientID = ingID)
	   AND unitConversion.toUnitID = (SELECT ingredientUnitID FROM recipeIngredientList WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID))
	, (SELECT servingSizeAmount FROM ingredients WHERE ingredients.ingredientID = ingID)
	))* 
    (
    SELECT
    ingredients.costPerIngredientServing
    FROM ingredients 
    WHERE ingredients.ingredientID = ingID
    )
);




/*The following functions simply sum all nutrition and cost in a recipe to give the total 
nutrition and cost for the recipe  
*/
CREATE FUNCTION recCals(recID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN((SELECT SUM(CalsPerIngredientAmount)
FROM recipeIngredientList
WHERE recipeID = recID)/(SELECT recipe.servings FROM recipe WHERE recipe.recipeID = recID));



CREATE FUNCTION recFat(recID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN((SELECT SUM(FatPerIngredientAmount)
FROM recipeIngredientList
WHERE recipeID = recID)/(SELECT recipe.servings FROM recipe WHERE recipe.recipeID = recID));



CREATE FUNCTION recCarbs(recID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN((SELECT SUM(CarbsPerIngredientAmount)
FROM recipeIngredientList
WHERE recipeID = recID)/(SELECT recipe.servings FROM recipe WHERE recipe.recipeID = recID));


CREATE FUNCTION recProt(recID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN((SELECT SUM(ProteinPerIngredientAmount)
FROM recipeIngredientList
WHERE recipeID = recID)/(SELECT recipe.servings FROM recipe WHERE recipe.recipeID = recID));


CREATE FUNCTION recCost(recID int)
RETURNS decimal(12,4) DETERMINISTIC
RETURN((SELECT SUM(CostPerIngredientAmount)
FROM recipeIngredientList
WHERE recipeID = recID)/(SELECT recipe.servings FROM recipe WHERE recipe.recipeID = recID));



/*These functions make life easier by selecting a recipeID, unitID, tagID
by passing in the textual name*/
CREATE FUNCTION get_recID(recName varchar(50))
RETURNS int DETERMINISTIC
RETURN((
SELECT recipeID FROM recipe 
WHERE recipeName = recName));



CREATE FUNCTION get_unitID(unitN varchar(30))
RETURNS int DETERMINISTIC
RETURN ((
SELECT ingredientUnitID FROM unitMeasurement
WHERE unitName = unitN));

CREATE FUNCTION get_tagID(tagN varchar(30))
RETURNS int DETERMINISTIC
RETURN ((
SELECT tagID FROM tags
WHERE tagName = tagN));




/*Create procedures -------------------------------------------------------*/


/*This procedure adds unit conversions */
DELIMITER //

CREATE PROCEDURE add_conversion_factor(IN from_unit varchar(30), IN to_unit varchar(30), IN conversion decimal(12,4))
BEGIN
		INSERT INTO unitConversion (fromUnitID, toUnitID, scaleFactor)
		VALUES(get_UnitID(from_unit), get_UnitID(to_unit), conversion);
    
	
END //

DELIMITER ;


/*this add_ingredient procedure makes it much easier to add an ingredient*/
DELIMITER //

CREATE PROCEDURE add_ingredient(IN f_name varchar(30) 
							   ,IN f_Desc varchar(100)
                               ,IN total_servings decimal(12,4)
                               ,IN units varchar(30)
                               ,IN serving_amount decimal(12,4)
                               ,IN cals_serving decimal(12,4)
                               ,IN fat_serving decimal(12,4)
                               ,IN carbs_serving decimal(12,4)
                               ,IN prot_serving decimal(12,4)
                               ,IN cost decimal(12,4)
                               )
BEGIN
		INSERT INTO ingredients (foodName,foodDesc, servingsPerContainer, 
						servingSizeUnitID, servingSizeAmount, 
						CalsPerIngredientServing, FatPerIngredientServing, CarbsPerIngredientServing, 
                        ProteinPerIngredientServing, purchaseCost,costPerIngredientServing)	
		VALUES(f_name,f_Desc,total_servings,(SELECT ingredientUnitID FROM unitMeasurement WHERE unitName = units)
					,serving_amount,cals_serving,fat_serving,carbs_serving,prot_serving,cost,cost/total_servings);
    
	
END //

DELIMITER ;



/*this add_food_to_recipe procedure adds food to a recipe and then updates the 
recipe ingredient list with the nutrition and cost information and then updates the 
recipe nutrition and cost automatically. It does this using the functions created above*/
DELIMITER //

CREATE PROCEDURE add_food_to_recipe(IN f_name varchar(30),IN ing_Name varchar(30), IN u_name varchar(30), IN ingAmount decimal(12,4))
BEGIN
	DECLARE recID int;
    DECLARE ingUnitID int;
    DECLARE ingID int;
    SET recID = get_recID(f_name);
    SET ingUnitID = (SELECT ingredientUnitID FROM unitMeasurement WHERE unitName = u_name);
    SET ingID = (SELECT ingredientID FROM ingredients WHERE foodName = ing_Name);
	INSERT INTO recipeIngredientList ( recipeID, ingredientID, ingredientUnitID, ingredientAmount) 
	VALUES (recID,ingID,ingUnitID,ingAmount);
    
    UPDATE recipeIngredientList 
		SET CalsPerIngredientAmount = getCals(recID,ingID)
		, FatPerIngredientAmount = getFat(recID,ingID)
		, CarbsPerIngredientAmount = getCarbs(recID,ingID)
		, ProteinPerIngredientAmount = getProt(recID,ingID)
		, CostPerIngredientAmount = getCost(recID,ingID)
		WHERE recipeIngredientList.recipeID = recID AND recipeIngredientList.ingredientID = ingID;
        
        
	UPDATE recipe 
			SET recipeCost = recCost(recID)
			, CalsPerServing = recCals(recID)
			, FatPerServing = recFat(recID)
			, CarbsPerServing = recCarbs(recID)
			, ProteinPerServing = recProt(recID)
			WHERE recipe.recipeID = recID;
END //

DELIMITER ;



/*This procedure handles adding tags to recipes */
DELIMITER //

CREATE PROCEDURE add_tag_to_recipe(IN recN varchar(30), IN tagN varchar(30))
BEGIN
		INSERT INTO recTagList (recipeID, tagID)
		VALUES(get_recID(recN), get_tagID(tagN));
    
	
END //

DELIMITER ;


/*View to grab all data that is then sent to a node backend and then to React.js ----------------------------------------------*/
CREATE VIEW recList AS
SELECT recipe.recipeID,recipe.recipeName, recipe.servings, recipe.recPhoto,recipe.difficulty, recipe.recipeRating, recipe.instructions, recipe.CalsPerServing, recipe.FatPerServing
		, recipe.CarbsPerServing, recipe.ProteinPerServing, GROUP_CONCAT(DISTINCT TRIM(recipeIngredientList.ingredientAmount) + 0, " ", unitMeasurement.unitName, " " ,ingredients.foodName) AS ingredients
        , GROUP_CONCAT(DISTINCT tags.tagName) AS tags
FROM recipe
JOIN recipeIngredientList
ON recipe.recipeID = recipeIngredientList.recipeID
JOIN ingredients 
ON recipeIngredientList.ingredientID = ingredients.ingredientID
JOIN unitMeasurement 
ON recipeIngredientList.ingredientUnitID = unitMeasurement.ingredientUnitID
JOIN recTagList  
ON recTagList.recipeID = recipe.recipeID
JOIN tags 
ON tags.tagID = recTagList.tagID
GROUP BY (recipe.recipeID);

/*Inserts and calls to procedures to get data in */


/*Inserts unit of measurements */
INSERT INTO unitMeasurement (unitName) VALUES 
	("each"),
    ("cup"),
    ("tbsp"),
	("tsp"),
	("slice"),
    ("oz");

SELECT * FROM unitMeasurement;

/*This inserts tags into the tag table */
INSERT INTO tags (tagName) VALUES 
	("spicy"),
	("gluten-free"),
	("passover"),
	("indian"),
	("breakfast"),
	("dessert"),
	("vegan"),
	("vegetarian"),
    ("side"),
    ("Channukah"),
	("mexican");

SELECT * FROM tags;

/*This procedure easily adds conversion factors */
CALL add_conversion_factor("each","each",1);
CALL add_conversion_factor("slice","slice",1);
CALL add_conversion_factor("cup","cup",1);
CALL add_conversion_factor("tbsp","tbsp",1);
CALL add_conversion_factor("tsp","tsp",1);
CALL add_conversion_factor("oz","oz",1);
CALL add_conversion_factor("cup","tbsp",1/16);
CALL add_conversion_factor("tbsp","cup",16);
CALL add_conversion_factor("cup","tsp",1/48);
CALL add_conversion_factor("tsp","cup",48);
CALL add_conversion_factor("tbsp","tsp",1/3);
CALL add_conversion_factor("tsp","tbsp",3);


SELECT * FROM unitConversion;


/*This procedure adds an ingredient to the database using the following params 
name, desc, total servings, unit, serving size, cals, fat, carbs, prot, purchase cost*/
CALL add_ingredient("large eggs", "Organic Cage-Free Large Brown Eggs"
					,12,"each",1,70,5,0,6,3.99);

CALL add_ingredient("2% milk", "Ralphs 2% Reduced Fat Milk"
					,8,"cup",1,150,8,12,8,3.29);


CALL add_ingredient("butter", "Organic Valley Butter"
					,32,"tbsp",1,100,11,0,0,6.99);

CALL add_ingredient("avocado", "Organic Haas Avocado"
					,5,"each",0.2,50,4.5,3,1,2.49);

CALL add_ingredient("flour", "King Arthur All-Purpose Flour"
					,45,"cup",0.25,110,0,23,4,3.50);

CALL add_ingredient("baking soda", "Trader Joe's Baking Soda"
					,567,"tsp",1/8,0,0,0,0,1.40);
                    
CALL add_ingredient("challah bread", "Sun Flower Challah Bread"
					,18,"slice",1,130,3,21,4,4.49);
                    
CALL add_ingredient("chocolate chips", "Enjoy Life Chocolate Chips"
					,19,"tbsp",1,80,5,9,1,.99);
      

CALL add_ingredient("feta cheese", "Mt Vikos Feta Cheese"
					,6,"oz",1,60,7,0,4,4.99);

CALL add_ingredient("matzah", "Yehuda Matzah"
					,10,"slice",1,125,3.5,22,2,1.65);
                    
CALL add_ingredient("chicken thighs", "Mary's Organic Chicken Thighs"
					,4,"oz",4,150,1,0,24,11.91);
                    
CALL add_ingredient("potato", "Organic Yukon Gold Potato"
					,3,"each",1,110,0,26,3,2.49);

CALL add_ingredient("lemon", "Organic lemon"
					,1,"each",1,17,0.2,5.4,0.6,.95);
                    
CALL add_ingredient("carrot", "Organic carrot"
					,15,"each",1,41,0.2,9.6,.9,1.49);
                    
CALL add_ingredient("sugar", "Organic cane sugar"
					,1135,"tsp",1,15,0,4,0,9.79);
                    
CALL add_ingredient("cream", "Organic heavy whipping cream"
					,32,"tbsp",1,50,5,1,1,4.99);
	
CALL add_ingredient("water", "water"
					,1,"tbsp",1,0,0,0,0,0);

CALL add_ingredient("olive oil", "Organic Olive Oil"
					,32,"tbsp",1,119,13.5,0,0,8.25);
		
CALL add_ingredient("onion", "Organic Onion"
					,1,"each",1,60,0,16,1,.35);


SELECT * FROM ingredients;



/*Here we have an INSERT INTO with a recipe followed
 by a stored procedure to add its ingredients
 
 The ! on the insructions is for React.js to use in .split*/


/*Scrambled Eggs full starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating, recPhoto)
VALUES ("Scrambled Eggs"
		, "!1. Whisk eggs, milk, salt and pepper in medium bowl until blended.
        !2. Heat butter in a large nonstick skillet over medium heat until hot. Pour in 
			egg mixture. 
        !3. As eggs begin to set, gently pull the eggs across the pan with a spatula, 
			forming large soft curds. Continue cooking—pulling, lifting and folding 
            eggs—until thickened and no visible liquid egg remains.Remove from heat and 
            serve immediately."
        , 1
        ,2
        ,3
        ,"./scrambled-eggs.jpg");





/*S_P to add ingredients to a recipe
#recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Scrambled Eggs","large eggs","each",4);
CALL add_food_to_recipe("Scrambled Eggs","2% milk","cup",.25);
CALL add_food_to_recipe("Scrambled Eggs","butter","tsp",2);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Scrambled Eggs","breakfast");
CALL add_tag_to_recipe("Scrambled Eggs","vegetarian");
CALL add_tag_to_recipe("Scrambled Eggs","gluten-free");

/*Scrambled Eggs finished */




/*Avo toast starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating, recPhoto)
VALUES ("Avocado Toast"
		, "!1. Heat small frying pan over medium-high heat. 
			!2. Add butter to pan. Crack eggs directly into pan. Season with salt and pepper.
            !3. Toast bread while eggs are cooking. Once toasted, add smashed avocado on top.
            !4. Top avocado and toast with eggs cooked to your liking."
        , 1
        ,1
        ,3
        ,"./avo-toast.jpg");


/*S_P to add ingredients to a recipe
#recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Avocado Toast","large eggs","each",2);
CALL add_food_to_recipe("Avocado Toast","avocado","each",.5);
CALL add_food_to_recipe("Avocado Toast","butter","tbsp",1);
CALL add_food_to_recipe("Avocado Toast","challah bread","slice",1);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Avocado Toast","breakfast");
CALL add_tag_to_recipe("Avocado Toast","vegetarian");

/*avo toast finished */


/*Matzah Brei starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating, recPhoto)
VALUES ("Matzah Brei"
		, "!1. Heat medium frying pan over medium-high heat. 
			!2. Break matzah into large bite-size pieces in a bowl. Soak matzah in water for a minute then drain. Add eggs and feta cheese to bowl and mix well.
            !3. Add butter to the frying pan and pour matzah and egg mixture over it. Cook for about 5 minutes or until golden then flip with a spatula.
            !4. Cook for another 5 minutes or until golden brown and cooked through."
        , 1
        ,2
        ,3
        ,"./matzah-brei.jpg");


/*S_P to add ingredients to a recipe
#recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Matzah Brei","large eggs","each",4);
CALL add_food_to_recipe("Matzah Brei","matzah","slice",4);
CALL add_food_to_recipe("Matzah Brei","butter","tbsp",1);
CALL add_food_to_recipe("Matzah Brei","feta cheese","oz",1.5);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Matzah Brei","breakfast");
CALL add_tag_to_recipe("Matzah Brei","vegetarian");
CALL add_tag_to_recipe("Matzah Brei","passover");

/*Matzah Brei finished */


/*Matzah Crack starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Matzah Crack"
		, "!1. Pre heat oven to 350 degree F. Line a baking sheet with foil and parchment paper. Cover the tray with a 
				single layer of matzah. 
			!2. To make the toffee combine butter and sugar in a medium saucepan. Cook over medium heat, stirring with 
				a whisk until it boils. Cook for 3 minutes until foamy and thick then carefully pour the toffee over the 
				matzah.
            !3. Place sheet tray into over anf bake for 8 to 10 minutes or until toffee topping is bubbling. 
            Remove tray from oven and immediately top with chocolate chips. After a few minutes when the chips 
            are melted, spead it evenly and sprinkle a pinch of seas salt on top.
            !4. Refrigerate for about an hour to cool then cut into 2-inch squares. Store in the refrigerator."
        , 2
        ,20
        ,3);


/*S_P to add ingredients to a recipe
#recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Matzah Crack","matzah","slice",4);
CALL add_food_to_recipe("Matzah Crack","butter","cup",1);
CALL add_food_to_recipe("Matzah Crack","sugar","cup",1);
CALL add_food_to_recipe("Matzah Crack","chocolate chips","cup",2);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Matzah Crack","dessert");
CALL add_tag_to_recipe("Matzah Crack","vegetarian");
CALL add_tag_to_recipe("Matzah Crack","passover");

/*Matzah Crack finished */


/*Bread Pudding starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Bread Pudding"
		, "!1. Preheat oven to 350 degrees F.
			!2. Break bread into small pieces into an 8 inch square baking pan. Drizzle 
				melted butter over bread. 
            !3. In a medium mixing bowl, combine eggs, milk, sugar, cinnamon, and 
				vanilla. Beat until well mixed. Pour over bread, and lightly push down 
				with a fork until bread is covered and soaking up the egg mixture.
            !4. Bake in the preheated oven for 45 minutes, or until the top springs 
				back when lightly tapped."
        , 2
        ,8
        ,2);


/*S_P to add ingredients to a recipe
#recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Bread Pudding","challah bread","slice",6);
CALL add_food_to_recipe("Bread Pudding","butter","tbsp",2);
CALL add_food_to_recipe("Bread Pudding","large eggs","each",4);
CALL add_food_to_recipe("Bread Pudding","2% milk","cup",2);
CALL add_food_to_recipe("Bread Pudding","sugar","cup",.75);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Bread Pudding","dessert");



/*Bread Pudding finished */



/*Choco chip cookies starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Chocolate Chip Cookies"
		, "!1. Preheat oven to 350 degrees F.
			!2. Cream together the butter and sugar until smooth. Beat in the eggs one 
				at a time, then stir in the vanilla. Add baking soda and a pinch of salt. 
                Stir in flour, chocolate chips, and nuts. Drop by large spoonfuls onto 
                ungreased pans. 
            !3. Bake for about 10 minutes in the preheated oven, or until edges are 
				nicely browned."
        , 1
        ,24
        ,2);


/*S_P to add ingredients to a recipe
recipe, ingredient, unit, amount*/
CALL add_food_to_recipe("Chocolate Chip Cookies","butter","cup",1);
CALL add_food_to_recipe("Chocolate Chip Cookies","sugar","cup",1.5);
CALL add_food_to_recipe("Chocolate Chip Cookies","large eggs","each",2);
CALL add_food_to_recipe("Chocolate Chip Cookies","baking soda","tsp",1);
CALL add_food_to_recipe("Chocolate Chip Cookies","flour","cup",3);
CALL add_food_to_recipe("Chocolate Chip Cookies","chocolate chips","cup",2);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Chocolate Chip Cookies","dessert");

/*Chocolate Chip Cookies finished */


/*Pancakes starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Pancakes"
		, "!1. In a large bowl, sift together the flour, baking powder, sugar and a 
			pinch of salt. Make a well in the center and pour in the milk, egg and 
            melted butter; mix until smooth.
			!2. Heat a lightly oiled griddle or frying pan over medium high heat. Pour 
				or scoop the batter onto the griddle, using approximately 1/4 cup for 
                each pancake. Brown on both sides and serve hot."
        , 1
        ,8
        ,3);


/*S_P to add ingredients to a recipe
recipe, ingredient, unit, amount*/
CALL add_food_to_recipe("Pancakes","flour","cup",1.5);
CALL add_food_to_recipe("Pancakes","baking soda","tsp",3.5);
CALL add_food_to_recipe("Pancakes","sugar","tbsp",1);
CALL add_food_to_recipe("Pancakes","2% milk","cup",1.25);
CALL add_food_to_recipe("Pancakes","large eggs","each",1);
CALL add_food_to_recipe("Pancakes","butter","tbsp",3);


/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Pancakes","breakfast");
CALL add_tag_to_recipe("Pancakes","vegetarian");

/*Pancakes finished */


/*Crepes starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Crepes"
		, "!1. In a blender, combine all of the ingredients and pulse for 10 seconds. 
			Place the crepe batter in the refrigerator for 1 hour. This allows the 
            bubbles to subside so the crepes will be less likely to tear during 
            cooking. The batter will keep for up to 48 hours.
			!2. Heat a small non-stick pan. Add butter to coat. Pour 1 ounce of batter 
            into the center of the pan and swirl to spread evenly. Cook for 30 seconds 
            and flip. Cook for another 10 seconds and remove to the cutting board. 
            Lay them out flat so they can cool. Continue until all batter is gone. 
            After they have cooled you can stack them and store in sealable plastic 
            bags in the refrigerator for several days or in the freezer for up to 
            two months. When using frozen crepes, thaw on a rack before gently peeling 
            apart."
        , 2
        ,6
        ,3);


/*S_P to add ingredients to a recipe
#recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Crepes","large eggs","each",2);
CALL add_food_to_recipe("Crepes","2% milk","cup",.75);
CALL add_food_to_recipe("Crepes","water","cup",.5);
CALL add_food_to_recipe("Crepes","flour","cup",1);
CALL add_food_to_recipe("Crepes","butter","tbsp",3);


/*Ingredients to add tag to recipe*/ 
CALL add_tag_to_recipe("Crepes","dessert");
CALL add_tag_to_recipe("Crepes","breakfast");

/*Crepes finished */



/*Chocolate Mousse starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Chocolate Mousse"
		, "!1. Place the butter in a medium microwave-safe bowl. Break the chocolate 
			into small pieces directly into the bowl. Microwave it in 20-second 
            intervals, stirring between each bout of heat, until the chocolate is 
            about 75% melted. Stir, allowing the residual heat in the bowl to melt 
            the chocolate completely.
			!2. In the bowl of a stand mixer or electric hand mixer, beat the egg 
				whites on medium-high speed and beat until soft peaks form. Gradually 
                beat in 1/4 cup of the sugar and continue beating until stiff peaks 
                form (the peaks will stand straight up when the beaters are lifted 
                from the mixture). Using a large rubber spatula, fold the egg white 
                mixture into the chocolate mixture until uniform. Set aside.
			!3. In another bowl, beat the heavy cream on medium-high speed until it 
				begins to thicken up. Add the remaining 2 tablespoons of sugar and 
				continue beating until the cream holds medium peaks. Fold the whipped 
				cream into the chocolate mixture. Be sure it is fully incorporated but 
				don't mix any more than necessary. Divide the mousse between 6 individual 
				glasses, cover, and chill until set, at least 2 hours."
        , 3
        ,6
        ,3);


/*S_P to add ingredients to a recipe
recipe, ingredient, unit, amount*/
CALL add_food_to_recipe("Chocolate Mousse","butter","tbsp",3);
CALL add_food_to_recipe("Chocolate Mousse","chocolate chips","cup",.75);
CALL add_food_to_recipe("Chocolate Mousse","large eggs","each",3);
CALL add_food_to_recipe("Chocolate Mousse","sugar","tbsp",6);
CALL add_food_to_recipe("Chocolate Mousse","cream","cup",.5);



/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Chocolate Mousse","dessert");
CALL add_tag_to_recipe("Chocolate Mousse","passover");
CALL add_tag_to_recipe("Chocolate Mousse","gluten-free");

/*Chocolate Mousse finished */


/*Mashed Potatoes starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Mashed Potatoes"
		, "!1. Bring a pot of salted water to a boil. Add potatoes and cook until tender
				but still firm, about 15 minutes; drain.
			!2. In a small saucepan heat butter, milk and cream over low heat until 
				butter is melted. Using a potato masher or electric beater, slowly 
                blend milk mixture into potatoes until smooth and creamy. Season with 
                salt and pepper to taste."
        , 2
        ,4
        ,2);


/*S_P to add ingredients to a recipe
recipe, ingredient, unit, amount*/
CALL add_food_to_recipe("Mashed Potatoes","potato","each",10);
CALL add_food_to_recipe("Mashed Potatoes","butter","tbsp",3);
CALL add_food_to_recipe("Mashed Potatoes","2% milk","cup",.5);
CALL add_food_to_recipe("Mashed Potatoes","cream","cup",.5);



/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Mashed Potatoes","side");
CALL add_tag_to_recipe("Mashed Potatoes","passover");
CALL add_tag_to_recipe("Mashed Potatoes","gluten-free");

/*Mashed Potatoes finished */




/*Roasted Chicken Thighs starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Roasted Chicken Thighs"
		, "!1. In a bowl, toss chicken with 1 tablespoon of oil oil and the juice of 2 
        lemons; season with salt and pepper and marinate 1 hour (or up to a day).
			!2. Preheat oven to 375 degrees. 
            !3. In a roasting pan add quartered potatoes, onions and carrots. Toss with 1 
				tablespoon of olive oil, salt and pepper. Add chicken and roast 20 to 
                25 minutes; flip chicken and roast 10 more minutes."
        , 3
        ,2
        ,2);


/*S_P to add ingredients to a recipe
recipe, ingredient, unit, amount*/
CALL add_food_to_recipe("Roasted Chicken Thighs","chicken thighs","oz",18);
CALL add_food_to_recipe("Roasted Chicken Thighs","lemon","each",2);
CALL add_food_to_recipe("Roasted Chicken Thighs","carrot","each",3);
CALL add_food_to_recipe("Roasted Chicken Thighs","potato","each",2);
CALL add_food_to_recipe("Roasted Chicken Thighs","onion","each",1);
CALL add_food_to_recipe("Roasted Chicken Thighs","olive oil","tbsp",2);



/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Roasted Chicken Thighs","passover");
CALL add_tag_to_recipe("Roasted Chicken Thighs","gluten-free");

/*Roasted Chicken Thighs finished */



/*Latkes starts here*/
INSERT INTO recipe (recipeName, instructions, difficulty, servings, recipeRating)
VALUES ("Latkes"
		, "!1. Preheat oven to 250°F.
			!2. Peel potatoes and coarsely grate by hand, transferring to a large bowl of cold water as grated. Soak potatoes 1 to 2 minutes after last batch is added to water, then drain well in a colander.
            !3. Spread grated potatoes and onion on a kitchen towel and roll up jelly-roll style. Twist towel tightly to wring out as much liquid as possible. Transfer potato mixture to a bowl and stir in egg and salt.
            !4. Heat 1/4 cup oil in a 12-inch nonstick skillet over moderately high heat until hot but not smoking. Working in batches of 4 latkes, spoon 2 tablespoons potato mixture per latke into skillet, spreading into 3-inch rounds with a fork. Reduce heat to moderate and cook until undersides are browned, about 5 minutes. Turn latkes over and cook until undersides are browned, about 5 minutes more. Transfer to paper towels to drain and season with salt. Add more oil to skillet as needed. Keep latkes warm on a wire rack set in a shallow baking pan in oven."
        , 2
        ,4
        ,2);


/*S_P to add ingredients to a recipe
recipe, #ingredient, #unit, #amount*/
CALL add_food_to_recipe("Latkes","potato","each",6);
CALL add_food_to_recipe("Latkes","onion","each",.5);
CALL add_food_to_recipe("Latkes","large eggs","each",1);
CALL add_food_to_recipe("Latkes","flour","tsp",2);
CALL add_food_to_recipe("Latkes","olive oil","cup",.75);



/*Ingredients to add tag to recipe */
CALL add_tag_to_recipe("Latkes","Channukah");
CALL add_tag_to_recipe("Latkes","side");
CALL add_tag_to_recipe("Latkes","vegetarian");


/*Latkes finished */

SELECT * FROM recipe;
SELECT * FROM recipeIngredientList;





/*Answers to my five data questions-------------------------------*/



/*Which recipes are tagged as Passover?*/
SELECT recipe.recipeName, tags.tagName 
FROM recipe 
JOIN recTagList 
ON recipe.recipeID = recTagList.recipeID
JOIN tags 
ON recTagList.tagID = tags.tagID
WHERE tags.tagName = "passover";


/*Which recipes have the most ingredients? Order the recipes by ingredients*/
SELECT recipe.recipeName 
	, COUNT(recipeIngredientList.ingredientID) AS ingredient_count
FROM recipe
JOIN recipeIngredientList
ON recipeIngredientList.recipeID = recipe.recipeID
GROUP BY(recipe.recipeID)
ORDER BY ingredient_count DESC;


/*which recipes include chicken?*/
SELECT recipe.recipeID, recipe.recipeName
FROM recipe
JOIN recipeIngredientList
ON recipeIngredientList.recipeID = recipe.recipeID
JOIN ingredients
ON ingredients.ingredientID = recipeIngredientList.ingredientID
WHERE ingredients.foodName LIKE '%chick%';


/*What are the five highest protein recipes?*/
SELECT recipe.recipeName, recipe.ProteinPerServing
FROM recipe
ORDER BY recipe.ProteinPerServing DESC
LIMIT 5;


/*What are the hardest recipes? Order the recipes by difficulty*/
SELECT recipe.recipeName, recipe.difficulty
FROM recipe
ORDER BY recipe.difficulty DESC;







