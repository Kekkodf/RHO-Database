-- Database Creation
CREATE DATABASE rho_database OWNER POSTGRES ENCODING = 'UTF8';

-- Schema Creation
DROP SCHEMA IF EXISTS rhoResearch CASCADE ;
CREATE SCHEMA rhoResearch;

-- Domain Definition
CREATE DOMAIN rhoResearch.passwd AS VARCHAR(254)
    CONSTRAINT properpassword CHECK (((VALUE)::text ~* '[A-Za-z0-9._%!]{8,}'));

CREATE DOMAIN rhoResearch.email AS VARCHAR(254)
    CONSTRAINT properemail CHECK (((VALUE)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'));

CREATE DOMAIN rhoResearch.phone AS VARCHAR(13)
    CONSTRAINT properphone CHECK (((VALUE)::text ~* '^[+][0-9]{1,3} [0-9]{1,3} [0-9]{6,12}$'));

CREATE DOMAIN rhoResearch.ICDOCode AS VARCHAR(8)
    CONSTRAINT properICDOCode CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.UIGID AS UUID
    CONSTRAINT properUIGID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.StudyGroupID AS VARCHAR(50)
    CONSTRAINT properStudyGroupID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.ResearchID AS VARCHAR(50)
    CONSTRAINT properResearchID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.ResID AS VARCHAR(50)
    CONSTRAINT properResID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.MAID AS VARCHAR(50)
    CONSTRAINT properMAID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.CSID AS VARCHAR(50)
    CONSTRAINT properCSID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

CREATE DOMAIN rhoResearch.StorageID AS VARCHAR(50)
    CONSTRAINT properStorageID CHECK (((VALUE)::text ~* '^[A-Za-z0-9]+$'));

-- Data types Creation
CREATE TYPE gendertype AS ENUM (
    'Male',
    'Female'
);

-- Tables Creation

-- Doctor
CREATE TABLE rhoResearch.Doctor (
    ID TEXT PRIMARY KEY,
    Name TEXT NOT NULL,
    Surname TEXT NOT NULL,
    Email rhoResearch.email NOT NULL,
    Password rhoResearch.passwd NOT NULL,
    PhoneNumber rhoResearch.phone NOT NULL
);

-- Medical Appointment
CREATE TABLE rhoResearch.MedicalAppointment (
    MAID rhoResearch.MAID PRIMARY KEY,
    Date DATE NOT NULL
);

-- Patient
CREATE TABLE rhoResearch.Patient (
    PatientID UUID PRIMARY KEY,
    Name CHARACTER VARYING(50) NOT NULL,
    Surname CHARACTER VARYING(50) NOT NULL,
    Sex gendertype NOT NULL,
    ClinicalHistory TEXT,
    FiscalCode CHARACTER VARYING(16),
    Status BOOLEAN NOT NULL,
    Weight SMALLINT NOT NULL,
    Height SMALLINT NOT NULL,
    DateOfBirth DATE NOT NULL
);

-- Research Personnel
CREATE TABLE rhoResearch.ResearchPersonnel (
    ID rhoResearch.ResID PRIMARY KEY,
    Name CHARACTER VARYING(50) NOT NULL,
    Surname CHARACTER VARYING(50) NOT NULL,
    Email rhoResearch.email NOT NULL,
    PhoneNumber rhoResearch.phone NOT NULL,
    Password rhoResearch.passwd NOT NULL,
    Role BOOLEAN NOT NULL
);

-- Location
CREATE TABLE rhoResearch.Location (
    StorageID rhoResearch.StorageID PRIMARY KEY,
    Room TEXT NOT NULL,
    Capacity INTEGER NOT NULL,
    Kind TEXT NOT NULL
);

-- Group
CREATE TABLE rhoResearch.Group (
    StudyGroupID rhoResearch.StudyGroupID PRIMARY KEY,
    KindOfSamples TEXT NOT NULL,
    NumberOfSamples INTEGER NOT NULL
);

-- Clinical Study
CREATE TABLE rhoResearch.ClinicalStudy (
    CSID rhoResearch.CSID PRIMARY KEY,
    Date DATE NOT NULL,
    Description TEXT
);

--Research Procedure
CREATE TABLE rhoResearch.ResearchProcedure (
    ResearchID rhoResearch.ResearchID PRIMARY KEY,
    Name TEXT NOT NULL,
    Description TEXT NOT NULL,
    NeedForAnonymization BOOLEAN NOT NULL
);

-- Research Team
CREATE TABLE rhoResearch.ResearchTeam (
    Name CHARACTER VARYING(50) PRIMARY KEY,
    NumberOfMembers SMALLINT NOT NULL,
    Creator CHARACTER VARYING(50) NOT NULL
);

-- Sample
CREATE TABLE rhoResearch.Sample (
    UIGID rhoResearch.UIGID PRIMARY KEY,
    Type TEXT NOT NULL,
    AvailabilityStatus BOOLEAN NOT NULL,
    MAID rhoResearch.MAID NOT NULL,
    StorageID rhoResearch.StorageID NOT NULL,
    FOREIGN KEY (MAID) REFERENCES rhoResearch.MedicalAppointment(MAID),
    FOREIGN KEY (StorageID) REFERENCES rhoResearch.Location(StorageID)
);

-- Belongs
CREATE TABLE rhoResearch.Belongs (
    UIGID rhoResearch.UIGID NOT NULL,
    StudyGroupID rhoResearch.StudyGroupID NOT NULL,
    PRIMARY KEY (UIGID, StudyGroupID),
    FOREIGN KEY (UIGID) REFERENCES rhoResearch.Sample(UIGID),
    FOREIGN KEY (StudyGroupID) REFERENCES rhoResearch.Group(StudyGroupID)
);

-- Consent
CREATE TABLE rhoResearch.Consent (
    PatientID UUID NOT NULL,
    CSID rhoResearch.CSID NOT NULL,
    ConsensusStatus BOOLEAN NOT NULL,
    Purpose TEXT NOT NULL,
    Duration DATE NOT NULL,
    PRIMARY KEY (PatientID, CSID),
    FOREIGN KEY (PatientID) REFERENCES rhoResearch.Patient(PatientID),
    FOREIGN KEY (CSID) REFERENCES rhoResearch.ClinicalStudy(CSID)
);

-- Defines
CREATE TABLE rhoResearch.Defines (
    Name CHARACTER VARYING(50) NOT NULL,
    CSID rhoResearch.CSID NOT NULL,
    ResearchID rhoResearch.ResearchID NOT NULL,
    PRIMARY KEY (Name, CSID, ResearchID),
    FOREIGN KEY (Name) REFERENCES rhoResearch.ResearchTeam(Name),
    FOREIGN KEY (CSID) REFERENCES rhoResearch.ClinicalStudy(CSID),
    FOREIGN KEY (ResearchID) REFERENCES rhoResearch.ResearchPersonnel(ID)
);

-- Performs
CREATE TABLE rhoResearch.Performs (
    DoctorID TEXT NOT NULL,
    MAID rhoResearch.MAID NOT NULL,
    PatientID UUID NOT NULL,
    PRIMARY KEY (DoctorID, MAID, PatientID),
    FOREIGN KEY (DoctorID) REFERENCES rhoResearch.Doctor(ID),
    FOREIGN KEY (MAID) REFERENCES rhoResearch.MedicalAppointment(MAID),
    FOREIGN KEY (PatientID) REFERENCES rhoResearch.Patient(PatientID)
);

-- Results
CREATE TABLE rhoResearch.Results (
    ICDOCode rhoResearch.ICDOCode NOT NULL,
    Mutation INTEGER NOT NULL,
    PutativeCopyNumberAlterations DOUBLE PRECISION NOT NULL,
    ModelAccuracy DOUBLE PRECISION,
    ModelLoss DOUBLE PRECISION,
    CSID rhoResearch.CSID NOT NULL,
    PRIMARY KEY (ICDOCode, CSID),
    FOREIGN KEY (CSID) REFERENCES rhoResearch.ClinicalStudy(CSID)
);
-- Undergoes
CREATE TABLE rhoResearch.Undergoes (
    StudyGroupID rhoResearch.StudyGroupID NOT NULL,
    CSID rhoResearch.CSID NOT NULL,
    PRIMARY KEY (CSID, StudyGroupID),
    FOREIGN KEY (StudyGroupID) REFERENCES rhoResearch.Group(StudyGroupID),
    FOREIGN KEY (CSID) REFERENCES rhoResearch.ClinicalStudy(CSID)
);
-- Works-in
CREATE TABLE rhoResearch.WorksIn (
    ResID rhoResearch.ResID NOT NULL,
    Name CHARACTER VARYING(50) NOT NULL,
    PRIMARY KEY (ResID, Name),
    FOREIGN KEY (ResID) REFERENCES rhoResearch.ResearchPersonnel(ID),
    FOREIGN KEY (Name) REFERENCES rhoResearch.ResearchTeam(Name)
);
