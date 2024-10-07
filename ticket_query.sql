-- 1)
SELECT Venues.VenueName, Venues.VenueAddress, Events.EventName, Events.EventStart, Events.EventEnd, TicketInfo.TicketType, TicketInfo.TicketPrice, TicketInfo.AvailableTickets
FROM Venues
JOIN Events ON Venues.VenueID = Events.VenueID
JOIN TicketInfo ON Events.EventID = TicketInfo.EventID
WHERE Events.EventName = 'Exeter Food Festival';

-- 2)
SELECT Events.EventName, Events.EventStart, Events.EventEnd, Events.EventDescription
FROM Events
WHERE EventStart BETWEEN '2023-07-1' AND '2023-07-10';

-- 3)
SELECT TicketInfo.TicketType, TicketInfo.AvailableTickets, TicketInfo.TicketPrice
From TicketInfo
WHERE TicketType = 'Bronze';

-- 4)
SELECT Customers.fName, Customers.lName, SUM(PurchaseTickets.TicketQuantity) AS totalGoldTickets
FROM Customers
JOIN Bookings ON Customers.CustomerID = Bookings.CustomerID
JOIN PurchaseTickets ON Bookings.BookingID = PurchaseTickets.BookingID
JOIN TicketInfo ON PurchaseTickets.TicketInfoID = TicketInfo.TicketInfoID
WHERE TicketInfo.TicketType = 'Gold'
GROUP BY Customers.fName, Customers.lName;

-- 5)
SELECT EventName, TicketsSold
FROM Events
ORDER BY TicketsSold DESC;

-- 6)
SELECT 
    Customers.fName, 
    Customers.lName, 
    Events.EventName, 
    Bookings.BookingID,
    Bookings.BookingTime,
    Bookings.ReceiveMethod, 
    Bookings.CancelStatus, 
    PurchaseTickets.TicketType, 
    PurchaseTickets.TicketQuantity, 
    Bookings.BookingPrice
FROM Bookings
JOIN Customers ON Bookings.CustomerID = Customers.CustomerID
JOIN PurchaseTickets ON Bookings.BookingID = PurchaseTickets.BookingID
JOIN TicketInfo ON PurchaseTickets.TicketInfoID = TicketInfo.TicketInfoID
JOIN Events ON TicketInfo.EventID = Events.EventID
WHERE Bookings.BookingID = 1;


-- 7)
SELECT EventID, EventName, EventIncome
FROM Events
JOIN (
    SELECT MAX(EventIncome) AS max_income
    FROM Events
) maxIncome ON Events.EventIncome = maxIncome.max_income;