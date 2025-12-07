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

