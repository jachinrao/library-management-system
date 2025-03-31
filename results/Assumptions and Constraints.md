## Assumptions

### 1. Student Table

Email addresses are unique, ensuring that each student can be identified by their email address.

`StudentType` can either be 'Registered' or 'Non-Registered', determining their access privileges, such as the number of books they can borrow.

### 2. Card Table

A student may have multiple cards, but a `Card` is always associated with one student.

`Status` ensures that only active cards can be used to borrow books.

The card is linked to the `Student` table using a foreign key, ensuring referential integrity.

`CardType` is associated to each resource such as books, rooms and computers.

### 3. Book Table

The `Language` column assumes that only two-letter ISO language codes are used (e.g., 'en' for English).

`ISBN` is also used as a foreign key in the `Copy` table to relate books to copies.

### 4. Copy Table

A book can have multiple copies, each with a unique `Barcode`.

The `PurchaseDate` is set to `NULL` when not specified and defaults to the current date before insertion.

Copies are stored in different rack numbers, making it possible to identify where each copy is physically located.

### 5. Loan Table

Each loan is linked to a specific card and copy (book), and the `ReturnDate` is set to `NULL` while the book is still on loan.

`BorrowDate` and `DueDate` are automatically set when a loan is created. The `DueDate` is set as $14$ days after the `BorrowDate`.

The `ReturnDate` is set when the book is returned, and the loan is closed.

### 6. Triggers

- **Set the Purchase Date**: A trigger is used to automatically set the `PurchaseDate` to the current date when a copy is inserted, if it is not provided.
- **Set BorrowDate and DueDate**: A trigger is used to ensure that when a loan is inserted, if the `BorrowDate` is not provided, it is set to the current date, and the `DueDate` is calculated automatically as $14$ days from the `BorrowDate`.
- **CheckStudentType**: This trigger limits the number of books a student can borrow based on their `StudentType`. Registered students can borrow up to $5$ books, and non-registered students can borrow only $1$.
- **CheckCardStatus**: This trigger ensures that a student can only borrow a book if their card is `Active`. An inactive card will prevent borrowing.
- **PreventDoubleBorrowing**: This trigger ensures that a book (or copy) cannot be borrowed multiple times without being returned first.



## Constraints

### 1. Primary Keys

`StudentID`, `CardID`, `ISBN`, `Barcode`, and `LoanID` are all primary keys in their respective tables, ensuring that each record is unique.

### 2. Foreign Keys

- The `Card` table references `StudentID`, ensuring that each card is associated with a valid student.

- The `Copy` table references `ISBN`, ensuring that each copy belongs to an existing book.

- The `Loan` table references both `CardID` and `Barcode`, ensuring that each loan is linked to a valid student card and book copy.

### 3. Value Constraints

The `Phone` column in the `Student` table is checked to ensure it follows the format `+372...`.

The `Language` column in the `Book` table is checked to ensure it follows the two-letter language code format (e.g., 'en' for English).

The number of pages is greater than $0$.

`ReturnDate` in the `Loan` table should not be earlier than `BorrowDate`.

### 4. Data Integrity

- **Cascade Delete and Update**: Foreign keys are set with `ON DELETE CASCADE` and `ON UPDATE CASCADE`, meaning that if a student or a book is deleted or updated, the corresponding records in the related tables will also be deleted or updated.

- **Triggers**: Multiple triggers ensure that data is inserted correctly and adheres to the business logic, such as automatically setting dates and ensuring no violations of business rules (e.g., exceeding borrowing limits, inactive cards).

### 5. Not Null

Certain fields like `BorrowDate` and `DueDate` are defined as `NOT NULL`, ensuring that these fields cannot have empty or undefined values.

### 6. Domain Constraints

The value of `Student.StudentType` is restricted to either `Registered` or `Non-Registered`.

The value of `Card.Status` is restricted to either `Active` or `Inactive` .

The value of `Card.CardType` is restricted within `Book`, `Room` and `Computer`.

### 7. Unique Constrains

`Student.Email` is set to be unique.



