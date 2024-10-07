-- 1)
UPDATE TicketInfo
SET AvailableTickets = AvailableTickets+100
WHERE TicketType = 'Adult' 
	AND EventID = 1;
    
SELECT * FROM TicketInfo;

-- 2)
INSERT INTO Bookings (ReceiveMethod, CustomerID, CardID, EventID, VoucherCode)
VALUES ('Email', 1, 1, @exfood_id, 'FOOD10');
SET @icoopbooking_id := LAST_INSERT_ID();

INSERT INTO PurchaseTickets (TicketType, TicketQuantity, TicketInfoID, BookingID)
VALUES ('Adult', 2, 1,  @icoopbooking_id);

INSERT INTO PurchaseTickets (TicketType, TicketQuantity, TicketInfoID, BookingID)
VALUES ('Child', 1, 2, @icoopbooking_id);

SELECT * FROM PurchaseTickets;

-- 3)
UPDATE Bookings
SET CancelStatus = 'TRUE'
WHERE BookingID = 1;
SELECT * FROM Bookings;

-- 4)
INSERT INTO Vouchers (VoucherCode, Discount, EventID)
VALUES ('SUMMER20', 0.20, 2);
SELECT * FROM Vouchers;
