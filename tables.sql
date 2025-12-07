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

CREATE FUNCTION validPerformance()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (
		SELECT 1 FROM performance p
        WHERE p.StageId = NEW.StageId
          AND p.PerformanceId <> NEW.PerformanceId
          AND NEW.StartTime < p.EndTime
          AND NEW.EndTime > p.StartTime
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



