DROP DATABASE IF EXISTS databaseCA;
CREATE DATABASE IF NOT EXISTS databaseCA;
USE databaseCA;

CREATE TABLE IF NOT EXISTS Venues (
    VenueID INT AUTO_INCREMENT PRIMARY KEY,
    VenueName VARCHAR(50),
    VenueAddress VARCHAR(100),
    UNIQUE (VenueName, VenueAddress)
);

CREATE TABLE IF NOT EXISTS Events (
    EventID INT AUTO_INCREMENT PRIMARY KEY,
    EventName VARCHAR(50),
    EventStart DATETIME,
    EventEnd DATETIME,
    EventDescription VARCHAR(200),
    TicketsSold INT,
    EventIncome DECIMAL(10,2),
    VenueID INT,
    UNIQUE (EventName, EventStart, EventEnd),
    CONSTRAINT FOREIGN KEY (VenueID) 
        REFERENCES Venues(VenueID) 
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS TicketInfo (
    TicketInfoID INT AUTO_INCREMENT PRIMARY KEY,
    TicketType VARCHAR(100),
    TicketPrice VARCHAR(10),
    AvailableTickets INT,
    EventID INT,
    UNIQUE (TicketType, EventID),
    CONSTRAINT FOREIGN KEY (EventID)
        REFERENCES Events(EventID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    fName VARCHAR(50),
    lName VARCHAR(50),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(50),
    UNIQUE (Email, PhoneNumber)
);

CREATE TABLE IF NOT EXISTS Vouchers (
    VoucherCode VARCHAR(50) UNIQUE PRIMARY KEY,
    Discount DECIMAL(5, 2),
    EventID INT NOT NULL,
    CONSTRAINT FOREIGN KEY (EventID)
        REFERENCES Events(EventID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS PaymentInfo (
    CardID INT AUTO_INCREMENT PRIMARY KEY,
    CardType VARCHAR(10),
    CardNumber VARCHAR(20),
    SecurityCode INT,
    ExpiryDate VARCHAR(10),
    CustomerID INT NOT NULL,
    UNIQUE (CardNumber, SecurityCode, ExpiryDate),
    CONSTRAINT FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Bookings (
    BookingID INT AUTO_INCREMENT PRIMARY KEY,
    BookingTime DATETIME,
    BookingPrice DECIMAL(10,2),
    CancelStatus VARCHAR(10) DEFAULT 'FALSE',
    ReceiveMethod VARCHAR(20),
    CustomerID INT NOT NULL,
    CardID INT NOT NULL,
    EventID INT,
    VoucherCode VARCHAR(50),
    UNIQUE (BookingTime, BookingPrice, CustomerID, EventID),
    CONSTRAINT FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (CardID)
        REFERENCES PaymentInfo(CardID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (EventID)
        REFERENCES Events(EventID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (VoucherCode)
        REFERENCES Vouchers(VoucherCode)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS PurchaseTickets (
    PurchaseTicketID INT AUTO_INCREMENT PRIMARY KEY,
    TicketType VARCHAR(100),
    TicketQuantity INT,
    TicketInfoID INT NOT NULL,
    BookingID INT NOT NULL,
    UNIQUE(TicketType, TicketQuantity, TicketInfoID),
    CONSTRAINT FOREIGN KEY (TicketInfoID)
        REFERENCES TicketInfo(TicketInfoID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FOREIGN KEY (BookingID)
        REFERENCES Bookings(BookingID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Calculate Booking Time
DELIMITER //

CREATE TRIGGER CalcBookingTime
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    SET NEW.BookingTime = NOW();
END//

DELIMITER ;

-- Calculate Booking Price
DELIMITER //

CREATE TRIGGER CalcTotalPrice AFTER INSERT ON PurchaseTickets
FOR EACH ROW
BEGIN
    DECLARE totalPrice DECIMAL(10,2);
    DECLARE vouchDiscount DECIMAL(5,2);

    -- base total calculation
    SELECT SUM(TicketInfo.TicketPrice * PurchaseTickets.TicketQuantity) INTO totalPrice
    FROM PurchaseTickets
    JOIN TicketInfo ON PurchaseTickets.TicketInfoID = TicketInfo.TicketInfoID
    WHERE PurchaseTickets.BookingID = NEW.BookingID;

    -- get discount if eventid matches
    SELECT Vouchers.Discount INTO vouchDiscount
    FROM Vouchers
    JOIN Events ON Vouchers.EventID = Events.EventID
    JOIN TicketInfo ON Events.EventID = TicketInfo.EventID
    WHERE TicketInfo.TicketInfoID = NEW.TicketInfoID
      AND Vouchers.VoucherCode = (SELECT VoucherCode FROM Bookings WHERE BookingID = NEW.BookingID);

    -- apply discount if data is received
    IF vouchDiscount IS NOT NULL THEN
        SET totalPrice = totalPrice * (1 - vouchDiscount);
    END IF;

    UPDATE Bookings
    SET BookingPrice = totalPrice
    WHERE BookingID = NEW.BookingID;
END//

DELIMITER ;


-- Calculate tickets sold per event
DELIMITER //

CREATE TRIGGER CalcTicketsSold AFTER INSERT ON PurchaseTickets
FOR EACH ROW
BEGIN
    DECLARE event_id INT;
    
    SELECT EventID INTO event_id
    FROM TicketInfo
    WHERE TicketInfoID = NEW.TicketInfoID;
    
    SELECT SUM(TicketQuantity) INTO @sold_tickets
    FROM PurchaseTickets
    WHERE TicketInfoID IN (SELECT TicketInfoID FROM TicketInfo WHERE EventID = event_id);
    
    UPDATE Events
    SET TicketsSold = @sold_tickets
    WHERE EventID = event_id;
END//

DELIMITER ;


-- Calculate EventIncome
DELIMITER //

CREATE TRIGGER CalcEventIncome AFTER INSERT ON PurchaseTickets
FOR EACH ROW
BEGIN
    DECLARE totalInc DECIMAL(10, 2);

    SELECT SUM(BookingPrice) INTO totalInc
    FROM Bookings
    WHERE EventID = (
        SELECT EventID
        FROM Bookings
        WHERE BookingID = NEW.BookingID
    );

    UPDATE Events
    SET EventIncome = totalInc
    WHERE EventID = (
        SELECT EventID
        FROM Bookings
        WHERE BookingID = NEW.BookingID
    );
END//

DELIMITER ;





-- Decrease AvailableTickets based on TicketType
DELIMITER //

CREATE TRIGGER LowerTickets AFTER INSERT ON PurchaseTickets
FOR EACH ROW
BEGIN
    DECLARE tiID INT;
    
    SELECT TicketInfoID INTO tiID
    FROM TicketInfo
    WHERE TicketType = NEW.TicketType;

    UPDATE TicketInfo
    SET AvailableTickets = AvailableTickets - NEW.TicketQuantity
    WHERE TicketInfoID = tiID;
END//

DELIMITER ;







INSERT INTO Customers (fName, lName, Email, PhoneNumber)
VALUES ('Ian', 'Cooper', 'icooper@gmail.com', '07564381956');
SET @icooper_id := LAST_INSERT_ID();
INSERT INTO PaymentInfo (CardType, CardNumber, SecurityCode, ExpiryDate, CustomerID)
VALUES ('MasterCard', '4321 3483 2342 2346', 321, '12/28', @icooper_id);
SET @icooper_card := LAST_INSERT_ID();

INSERT INTO Customers (fName, lName, Email, PhoneNumber)
VALUES ('Joe', 'Smiths', 'jsmiths@gmail.com', '07454748488');
SET @jsmiths_id := LAST_INSERT_ID();
INSERT INTO PaymentInfo (CardType, CardNumber, SecurityCode, ExpiryDate, CustomerID)
VALUES ('Visa', '1234 5678 9012 3456', 123, '10/25', @jsmiths_id);
SET @jsmiths_card := LAST_INSERT_ID();


INSERT INTO Venues (VenueName, VenueAddress) 
VALUES ('Exeter Festival Gardens', '32 Sidwell Street');
SET @exgardens_id := LAST_INSERT_ID();
INSERT INTO Events (EventName, EventStart, EventEnd, EventDescription, TicketsSold, EventIncome, VenueID) 
VALUES ('Exeter Food Festival', '2023-07-03 09:00:00', '2023-07-04 18:00:00', 'Food Festival held in Exeter!', 0, 0, @exgardens_id);
SET @exfood_id := LAST_INSERT_ID();
INSERT INTO TicketInfo (TicketType, TicketPrice, AvailableTickets, EventID) 
VALUES ('Adult', 5, 300, @exfood_id);
INSERT INTO TicketInfo (TicketType, TicketPrice, AvailableTickets, EventID) 
VALUES ('Child', 2, 100, @exfood_id);
INSERT INTO Vouchers (VoucherCode, Discount, EventID) 
VALUES ('FOOD10', 0.10, @exfood_id);


INSERT INTO Venues (VenueName, VenueAddress) 
VALUES ('Exmouth Music Arena', '212 Jennings Street');
SET @exarena_id := LAST_INSERT_ID();
INSERT INTO Events (EventName, EventStart, EventEnd, EventDescription, TicketsSold, EventIncome, VenueID) 
VALUES ('Exmouth Music Festival 2023', '2023-07-05 12:00:00', '2023-07-08 22:00:00', 'Music Festival held in Exmouth come listen!', 0, 0, @exarena_id);
SET @exmusic_id := LAST_INSERT_ID();
INSERT INTO TicketInfo (TicketType, TicketPrice, AvailableTickets, EventID) 
VALUES ('Gold', 10, 50, @exmusic_id);
SET @gold_id := LAST_INSERT_ID();
INSERT INTO TicketInfo (TicketType, TicketPrice, AvailableTickets, EventID) 
VALUES ('Silver', 7, 150, @exmusic_id);
INSERT INTO TicketInfo (TicketType, TicketPrice, AvailableTickets, EventID) 
VALUES ('Bronze', 4, 350, @exmusic_id);
SET @bronze_id := LAST_INSERT_ID();
INSERT INTO Vouchers (VoucherCode, Discount, EventID) 
VALUES ('FUN2023', 0.15, @exmusic_id);
INSERT INTO Vouchers (VoucherCode, Discount, EventID) 
VALUES ('MUSIC10', 0.10, @exmusic_id);

INSERT INTO Bookings (ReceiveMethod, CustomerID, CardID, EventID, VoucherCode)
VALUES ('Email', @jsmiths_id, @jsmiths_card, @exmusic_id, 'MUSIC10');
SET @booking1_id := LAST_INSERT_ID();

INSERT INTO PurchaseTickets (TicketType, TicketQuantity, TicketInfoID, BookingID)
VALUES ('Bronze', 2, @bronze_id, @booking1_id);
SET @jsticket_id := LAST_INSERT_ID();

INSERT INTO PurchaseTickets (TicketType, TicketQuantity, TicketInfoID, BookingID)
VALUES ('Gold', 3, @gold_id, @booking1_id);
SET @jsticket_id := LAST_INSERT_ID();