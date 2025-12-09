SELECT workshop.*
  FROM workshop
  JOIN festival USING (FestivalId)
 WHERE Difficulty = 'difficult'
   AND EXTRACT(YEAR FROM BeginningDate) = 2025;

SELECT performer.Name AS Performer
     , festival.Name AS Festival
	 , stage.Name AS Stage
	 , performance.BeginningTime AS StartTime
  FROM performance
  JOIN festival USING (festivalID)
  JOIN performer USING (performerId)
  JOIN stage USING (stageId)
 WHERE NumberOfVisitors > 10000;

SELECT *
  FROM festival
 WHERE EXTRACT(YEAR FROM BeginningDate) = 2025
   AND EXTRACT(YEAR FROM EndDate) = 2025;

SELECT *
  FROM workshop
 WHERE Difficulty = 'difficult';

SELECT *
  FROM workshop
 WHERE DURATION LIKE '4h %'
    OR DURATION = '5h';

SELECT *
  FROM workshop
 WHERE RequiresKnowledge = 'true';

SELECT *
  FROM mentor
 WHERE YearsOfExperience > 10;

SELECT *
  FROM mentor
 WHERE EXTRACT(YEAR FROM DateOfBirth) < 1985;

SELECT *
  FROM visitor
 WHERE City = 'Split';

SELECT *
  FROM visitor
 WHERE Email LIKE '%@gmail.com';

SELECT * 
  FROM visitor
 WHERE CURRENT_DATE - INTERVAL '25 years' < DateOfBirth;

SELECT *
  FROM ticket
 WHERE Price > 120;

SELECT *
  FROM ticket
 WHERE Type = 'VIP';

SELECT *
  FROM ticket 
 WHERE Validity = 'whole festival';

SELECT *
  FROM staff
 WHERE HasSafetyTraining = 'true';



 
 