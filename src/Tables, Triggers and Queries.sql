CREATE DATABASE Project2;
USE Project2;

DROP TABLE Loan;
DROP TABLE Copy;
DROP TABLE Book;
DROP TABLE Card;
DROP TABLE Student;

CREATE TABLE IF NOT EXISTS Student(
	StudentID INT AUTO_INCREMENT PRIMARY KEY,
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	Email VARCHAR(100) UNIQUE NOT NULL,
	Phone VARCHAR(20) NOT NULL CHECK (Phone LIKE '+372%'),
	Address VARCHAR(100),
	StudentType ENUM('Registered', 'Non-Registered') NOT NULL DEFAULT 'Non-Registered'
);

CREATE TABLE IF NOT EXISTS Card(
	CardID INT AUTO_INCREMENT PRIMARY KEY,
	ActivationDate DATE,
	Status ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active',
	StudentID INT NOT NULL,
	CardType ENUM('Book', 'Room', 'Computer') Not Null Default 'Book',
	FOREIGN KEY (StudentID) REFERENCES Student(StudentID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS Book(
	ISBN VARCHAR(30) PRIMARY KEY,
	Language CHAR(2) NOT NULL CHECK (Language REGEXP '^[a-zA-Z]{2}$'),
	Title VARCHAR(200) NOT NULL,
	Pages INT CHECK (Pages > 0),
	PublicationYear INT,
	Subject VARCHAR(100),
	Author VARCHAR(100) NOT NULL,
	Publisher VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Copy(
	Barcode VARCHAR(20) PRIMARY KEY,
	Price DECIMAL(8,2),
	PurchaseDate DATE,
	RackNumber VARCHAR(10) NOT NULL,
	ISBN VARCHAR(30) NOT NULL,
	Language Char(2) NOT NULL CHECK (Language REGEXP '^[a-zA-Z]{2}$'),
	FOREIGN KEY (ISBN) REFERENCES Book(ISBN) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS Loan(
	LoanID INT AUTO_INCREMENT PRIMARY KEY,
	BorrowDate DATE NOT NULL,
	DueDate DATE NOT NULL,
	ReturnDate DATE,
	Barcode VARCHAR(20) NOT NULL,
	CardID INT NOT NULL,
	FOREIGN KEY (CardID) REFERENCES Card(CardID) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (Barcode) REFERENCES Copy(Barcode) ON DELETE CASCADE ON UPDATE CASCADE
);


ALTER TABLE Loan ADD CONSTRAINT chk_ReturnDate CHECK (ReturnDate >= BorrowDate);

-- Set the purchase date to the current date when it's NULL
DELIMITER $$
CREATE TRIGGER SetPurchaseDate BEFORE INSERT ON Copy
FOR EACH ROW
BEGIN
    -- Check if PurchaseDate is NULL, and if so, set it to the current date
    IF NEW.PurchaseDate IS NULL THEN
        SET NEW.PurchaseDate = CURDATE();
    END IF;
END;
$$
DELIMITER ;

$$
DELIMITER ;

-- Set BorrowDate and DueDate
DELIMITER $$
CREATE TRIGGER SetBorrowAndDueDate BEFORE INSERT ON Loan
FOR EACH ROW
BEGIN
    -- If BorrowDate is NULL, set it to the current date
    IF NEW.BorrowDate IS NULL THEN
        SET NEW.BorrowDate = CURDATE();
    END IF;

    -- Set the DueDate to BorrowDate + 14 days
    SET NEW.DueDate = DATE_ADD(NEW.BorrowDate, INTERVAL 14 DAY);
END;
$$
DELIMITER ;


-- Limit borrowing based on StudentType
DELIMITER $$ 
CREATE TRIGGER CheckStudentType BEFORE INSERT ON Loan
FOR EACH ROW
BEGIN
    DECLARE studentType ENUM('Registered', 'Non-Registered');
    DECLARE currentLoanCount INT;
    DECLARE maxAllowedLoans INT;

    -- Get the student's type and their total active loan count across all cards
    SELECT Student.StudentType,
           COUNT(Loan.LoanID)  -- Total active loans for the student
    INTO studentType, currentLoanCount
    FROM Student
    INNER JOIN Card ON Student.StudentID = Card.StudentID
    LEFT JOIN Loan ON Card.CardID = Loan.CardID
    WHERE Student.StudentID = (
        SELECT StudentID FROM Card WHERE CardID = NEW.CardID
    ) AND Loan.ReturnDate IS NULL -- Only count active (non-returned) loans
    GROUP BY Student.StudentType;
   
    -- Set the maximum allowed loans based on student type
    IF studentType = 'Registered' THEN
        SET maxAllowedLoans = 5;
    ELSEIF studentType = 'Non-Registered' THEN
        SET maxAllowedLoans = 1;
    END IF;

    -- Check if the current loan count exceeds the allowed limit
    IF currentLoanCount >= maxAllowedLoans THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loan limit exceeded for this student type.';
    END IF;
END;
$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER CheckCardStatus BEFORE INSERT ON Loan
FOR EACH ROW
BEGIN
    DECLARE cardStatus ENUM('Active', 'Inactive');

    -- Retrieve the status of the card being used for the loan
    SELECT Status
    INTO cardStatus
    FROM Card
    WHERE CardID = NEW.CardID;

    -- Check if the card status is Inactive
    IF cardStatus = 'Inactive' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loan cannot be created because the card status is Inactive.';
    END IF;
END;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER PreventDoubleBorrowing BEFORE INSERT ON Loan
FOR EACH ROW
BEGIN
    DECLARE activeLoanCount INT;
    -- Check if there is an active loan for the same book (Barcode) that has not been returned
    SELECT COUNT(*)
    INTO activeLoanCount
    FROM Loan
    WHERE Barcode = NEW.Barcode AND ReturnDate IS NULL;
    -- If an active loan exists, raise an error
    IF activeLoanCount > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This book is already borrowed and not returned.';
    END IF;
END;
$$
DELIMITER ;


# Populate all the tables

INSERT INTO Student (FirstName, LastName, Email, Phone, Address, StudentType)
VALUES 
('John', 'Doe', 'john.doe@ut.ee', '+37212345678', '123 Main St', 'Registered'),
('Jane', 'Smith', 'jane.smith@ut.ee', '+37223456789', '456 Elm St', 'Non-Registered'),
('Michael', 'Brown', 'michael.brown@gmail.com', '+37234567890', '789 Oak St', 'Registered'),
('Emma', 'Johnson', 'emma.johnson@gmail.com', '+37245678901', '101 Pine St', 'Non-Registered');

INSERT INTO Card (ActivationDate, Status, StudentID)
VALUES 
(CURDATE(), 'Active', 1),
(CURDATE(), 'Inactive', 2),
(CURDATE(), 'Active', 3),
(CURDATE(), 'Active', 4),
(CURDATE(), 'Active', 1);


INSERT INTO Book (ISBN, Language, Title, Pages, PublicationYear, Subject, Author, Publisher)
VALUES
('978-3-16-148410-0', 'en', 'Introduction to Computer Science', 500, 2020, 'Computer Science', 'John Doe', 'TechPress'),
('978-1-4028-9462-6', 'en', 'Advanced Programming', 400, 2021, 'Programming', 'Jane Smith', 'CodeMaster'),
('978-0-12-809839-1', 'DE', 'Data Structures and Algorithms', 300, 2019, 'Algorithms', 'Michael Brown', 'AlgoTech');

INSERT INTO Copy (Barcode, Price, RackNumber, ISBN, Language)
VALUES 
('B0001', 25.00, 'R1', '978-3-16-148410-0', 'EN'),
('B0002', 25.00, 'R1', '978-3-16-148410-0', 'EN'),
('B0003', 30.00, 'R2', '978-1-4028-9462-6', 'EE'),
('B0004', 30.00, 'R2', '978-1-4028-9462-6', 'EE'),
('B0005', 30.00, 'R2', '978-1-4028-9462-6', 'EN'),
('B0006', 35.00, 'R3', '978-0-12-809839-1', 'EN'),
('B0007', 35.00, 'R3', '978-0-12-809839-1', 'JP'),
('B0008', 35.00, 'R3', '978-0-12-809839-1', 'EN'),
('B0009', 35.00, 'R3', '978-0-12-809839-1', 'FR'),
('B00010', 35.00, 'R3', '978-0-12-809839-1', 'EN');

INSERT INTO Loan (Barcode, CardID) VALUES ('B0001', 3);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0002', 1);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0003', 1);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0004', 1);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0005', 1);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0006', 5);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0007', 4);
INSERT INTO Loan (Barcode, CardID) VALUES ('B0007', 3); -- This book has been borrowed.
INSERT INTO Loan (Barcode, CardID) VALUES ('B0008', 5); -- Exceed the limitation.
INSERT INTO Loan (Barcode, CardID) VALUES ('B0009', 2); -- Student doesn't have access to books.
UPDATE Loan
SET ReturnDate = DATE_ADD(BorrowDate, INTERVAL 7 DAY)
WHERE LoanID IN (1, 5);
UPDATE Loan
SET ReturnDate = DATE_ADD(BorrowDate, INTERVAL 16 DAY)
WHERE LoanID IN (2, 3, 7);
INSERT INTO Loan (Barcode, CardID, BorrowDate) VALUES ('B00010', 3, '2024-09-15');

# Query
-- All StudentID that borrowed '978-3-16-148410-0'
SELECT DISTINCT Student.StudentID
FROM Student
INNER JOIN Card ON Student.StudentID = Card.StudentID
INNER JOIN Loan ON Card.CardID = Loan.CardID
INNER JOIN Copy ON Loan.Barcode = Copy.Barcode
INNER JOIN Book ON Copy.ISBN = Book.ISBN
WHERE Book.ISBN = '978-3-16-148410-0';

-- Retrieve all ISBNs of books borrowed by a student whose StudentID is 1
SELECT DISTINCT Book.ISBN
FROM Book
INNER JOIN Copy ON Book.ISBN = Copy.ISBN
INNER JOIN Loan ON Copy.Barcode = Loan.Barcode
INNER JOIN Card ON Loan.CardID = Card.CardID
WHERE Card.StudentID = 1;

-- Display the copies of books whose due dates have passed
SELECT 
    Copy.Barcode,
    Book.ISBN,
    Book.Title,
    Loan.DueDate
FROM 
    Loan
INNER JOIN Copy ON Loan.Barcode = Copy.Barcode
INNER JOIN Book ON Copy.ISBN = Book.ISBN
WHERE 
    Loan.DueDate < CURDATE() AND 
    Loan.ReturnDate IS NULL;

-- Display the number of remaining copies of the book with ISBN '978-0-12-809839-1'
SELECT
    (SELECT COUNT(*) FROM Copy WHERE ISBN = '978-0-12-809839-1') - 
    (SELECT COUNT(*) FROM Loan WHERE Barcode IN (SELECT Barcode FROM Copy WHERE ISBN = '978-0-12-809839-1') AND ReturnDate IS NULL) AS RemainingCopies;



