CREATE TABLE festival (
	FestivalId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	City VARCHAR(100) NOT NULL,
	Capacity INT, 
	BeginningDate DATE,
	EndDate DATE, 
	Status VARCHAR(30),
	HasCamp BOOL DEFAULT FALSE
);

ALTER TABLE festival
	ADD CONSTRAINT CapacityIsPositive CHECK (capacity > 0),
	ADD CONSTRAINT ValidDates CHECK (EndDate >= BeginningDate), 
	ADD CONSTRAINT ValidStatus CHECK(Status IN ('planned', 'active', 'finished'));

CREATE TABLE stage(
	StageId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Location VARCHAR(100),
	Capacity INT, 
	IsCovered BOOL,
	FestivalId INT REFERENCES festival(FestivalId)
);

ALTER TABLE stage
	ADD CONSTRAINT ValidLocation CHECK (Location IN ('main', 'forrest', 'beach')), 
	ADD CONSTRAINT CapacityIsPositive CHECK (capacity > 0);

CREATE TABLE performer(
	PerformerId SERIAL PRIMARY KEY, 
	Name VARCHAR(100) NOT NULL, 
	PerformerType VARCHAR(100),
	Country VARCHAR(100),
	Genre VARCHAR(100),
	NumberOfMembers INT,
	IsActive BOOL
);

ALTER TABLE performer 
	ADD CONSTRAINT ValidPerformerType CHECK (PerformerType IN ('band', 'DJ', 'solo')),
	ADD CONSTRAINT PositiveNumberOfMembers CHECK (NumberOfMembers > 0);

CREATE TABLE performerAtFestival (
	FestivalId INT REFERENCES festival(FestivalId), 
	PerformerId INT REFERENCES performer(PerformerId)
);

CREATE TABLE performance (
	BeginningTime TIMESTAMP NOT NULL,
	EndTime TIMESTAMP NOT NULL,
	NumberOfVisitors INT,
	FestivalId INT REFERENCES festival(FestivalId),
	StageId INT REFERENCES stage(StageId),
	PerformerId INT REFERENCES performer(performerId)
);

ALTER TABLE performance
	ADD COLUMN PerformanceId SERIAL PRIMARY KEY;

CREATE FUNCTION validPerformance()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (
		SELECT 1 FROM performance p
        WHERE p.StageId = NEW.StageId OR p.PerformerId = NEW.PerformerId
          AND p.PerformanceId <> NEW.PerformanceId
          AND NEW.BeginningTime < p.EndTime
          AND NEW.EndTime > p.BeginningTime
    ) THEN
        RAISE EXCEPTION 'Overlaping performances';
    END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trgValidPerformance
BEFORE INSERT ON performance
FOR EACH ROW
EXECUTE FUNCTION validPerformance();

CREATE TABLE ticket(
	TicketId SERIAL PRIMARY KEY,
	Type VARCHAR(100),
	Price DECIMAL(10, 2),
	Description VARCHAR(200),
	Validity VARCHAR(100),
	FestivalId INT REFERENCES festival(FestivalId)
);

ALTER TABLE ticket
	ADD CONSTRAINT ValidType CHECK(Type IN('daily', 'whole festival', 'VIP', 'camp')),
	ADD CONSTRAINT PositivePrice CHECK(Price > 0),
	ADD CONSTRAINT Validity CHECK(Validity IN ('daily', 'whole festival'));

CREATE TABLE visitor(
	VisitorId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Surname VARCHAR(100) NOT NULL,
	DateOfBirth DATE,
	City VARCHAR(100),
	Email VARCHAR(100) UNIQUE,
	Country VARCHAR(100)
);

CREATE TABLE purchase(
	PurchaseId SERIAL PRIMARY KEY,
	PurchaseDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
	TotalAmount NUMERIC,
	VisitorId INT REFERENCES visitor(VisitorId), 
	FestivalId INT REFERENCES festival(FestivalId)
);

CREATE TABLE purchaseItem(
	PurchaseItemId SERIAL PRIMARY KEY,
	Quantity INT NOT NULL,
	UnitPrice NUMERIC,
	TotalPrice NUMERIC,
	TicketId INT REFERENCES ticket(TicketId),
	PurchaseId INT REFERENCES purchase(PurchaseId)
);

ALTER TABLE purchaseItem
	ADD CONSTRAINT ValidQuantity CHECK(Quantity > 0);

CREATE TABLE workshop(
	WorkshopId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Difficulty VARCHAR(100),
	Capacity INT,
	Duration VARCHAR(20),
	RequiresKnowledge BOOL DEFAULT FALSE,
	FestivalId INT REFERENCES festival(FestivalId)
);

ALTER TABLE workshop
	ADD CONSTRAINT ValidDifficulty CHECK(Difficulty IN('beginner', 'intermediate', 'difficult')),
	ADD CONSTRAINT VaslidCapacity CHECK(Capacity > 0);

CREATE TABLE mentor(
	MentorId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Surname VARCHAR(100) NOT NULL,
	DateOfBirth DATE,
	FieldOfWork VARCHAR(200),
	YearsOfExperience INT
);

ALTER TABLE mentor
	ADD CONSTRAINT MentorOver18 CHECK(CURRENT_DATE - 18 >= DateOfBirth),
	ADD CONSTRAINT YearsOfExperienceOver2 CHECK(YearsOfExperience > 2);

ALTER TABLE workshop
	ADD COLUMN MentorId INT REFERENCES mentor(MentorId);

CREATE TABLE workshopApplication(
	Status VARCHAR(100),
	TimeOfApplication TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	VisitorId INT REFERENCES visitor(VisitorId),
	WorkshopId INT REFERENCES workshop(WorkshopId)
);

ALTER TABLE workshopApplication
	ADD CONSTRAINT ValidStatus CHECK(Status IN('registered', 'canceled', 'attended'));

CREATE FUNCTION checkWorkshopCapacity()
RETURNS TRIGGER AS $$
DECLARE
	MaxCapacity INT;
	CurrentCapacity INT;
BEGIN
	SELECT Capacity INTO MaxCapacity
	FROM workshop
	WHERE WorkshopId = NEW.WorkshopId;

	SELECT COUNT(*) INTO CurrentCapacity
	FROM workshopApplication
	WHERE workshopApplication.WorkshopId = NEW.WorkshopId
	  AND Status = 'registered';

	IF CurrentCapacity >= MaxCapacity
	THEN 
		RAISE EXCEPTION 'Workshop is full';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trgCheckWorkshopCapacity
BEFORE INSERT ON workshopApplication
FOR EACH ROW
EXECUTE FUNCTION checkWorkshopCapacity();

CREATE TABLE staff(
	StaffId SERIAL PRIMARY KEY,
	Name VARCHAR(100) NOT NULL,
	Surname VARCHAR(100) NOT NULL,
	DateOfBirth DATE,
	Role VARCHAR(100),
	Contact VARCHAR(100),
	HasSafetyTraining BOOL DEFAULT TRUE
);

ALTER TABLE staff
	ADD CONSTRAINT ValidRole CHECK(Role IN('organizer', 'tehnician', 'security', 'volunteer'));

CREATE FUNCTION checkSecurityGuardAge()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (SELECT 1 FROM staff
	            WHERE Role = 'security'
				AND CURRENT_DATE - 21 < DateOfBirth)
	THEN 
		RAISE EXCEPTION 'Security must be over 21.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trgCheckSecurityGuardAge
BEFORE INSERT ON staff
FOR EACH ROW
EXECUTE FUNCTION checkSecurityGuardAge();

CREATE TABLE staffAtFestival(
	FestivalId INT REFERENCES festival(FestivalId),
	StaffId INT REFERENCES staff(StaffId)
);

CREATE FUNCTION OverlappingFestivals()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (
		SELECT 1 FROM staffAtFestival
		  JOIN festival USING(FestivalId)
         WHERE StaffId = NEW.StaffId
		   AND (
			f.BeginningDate < NEW.BeginningDate AND
            f.EndDate > NEW.EndDate
		   ) 
    ) THEN
        RAISE EXCEPTION 'Staff member has overlaping festivals';
    END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trgOverlappingFestivals
BEFORE INSERT ON staffAtFestival
FOR EACH ROW
EXECUTE FUNCTION OverlappingFestivals();

CREATE TABLE membershipCard(
	CardId SERIAL PRIMARY KEY,
	ActivationDate DATE DEFAULT CURRENT_DATE,
	Status VARCHAR(100),
	VisitorId INT REFERENCES visitor(VisitorId)
);

ALTER TABLE membershipCard
	ADD CONSTRAINT ValidStatus CHECK(Status IN('active', 'expired'));

CREATE OR REPLACE FUNCTION checkForMembership()
RETURNS TRIGGER AS $$
DECLARE 
	NumberOfFestivals INT;
	TotalSpent NUMERIC;
BEGIN
	SELECT COUNT(DISTINCT FestivalId) INTO NumberOfFestivals
	  FROM purchase
	 WHERE VisitorId = NEW.VisitorId;


	 SELECT SUM(purchaseItem.TotalPrice) INTO TotalSpent
	   FROM purchase
	   JOIN purchaseItem USING(PurchaseId)
	  WHERE VisitorId = NEW.VisitorId;
	  
	IF NumberOfFestivals < 3 OR TotalSpent <= 600 
	THEN
		RAISE EXCEPTION 'Visitor is not suitable for membership card';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trgCheckForMembership
BEFORE INSERT ON membershipCard
FOR EACH ROW
EXECUTE FUNCTION CheckForMembership();