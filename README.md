# Equipment Checkout Management System

A Flutter app for a university department administrator to manage equipment,
register borrowers, record checkouts, process returns, and review checkout
history. All data is stored locally in SQLite using the `sqflite` package and
persists after the app is closed and reopened.

## Features

- **Equipment:** add, edit, delete, search by name, and filter by category and
  availability. Availability is calculated from checkout records.
- **Borrowers:** register, edit, delete, and search borrowers, with a detail
  screen showing contact info, current checkouts, and past checkouts.
- **Checkouts:** assign available equipment to a borrower with a checkout date
  and due date, and mark equipment as returned.
- **History (bonus):** all checkouts with All, Active, Returned, and Overdue
  filters. Overdue is determined automatically from the stored due date.

## Business rules

- Equipment that is checked out cannot be checked out again.
- The due date must be later than the checkout date.
- Equipment and borrowers with checkout history cannot be deleted.
- Returning an item keeps the checkout in the history.
- Required fields and email format are validated, with clear error messages.

## Project structure

```
lib/
  main.dart
  database/    SQLite setup and all queries (db_helper.dart)
  models/      Equipment, Borrower, Checkout
  screens/     Equipment, Borrowers, Checkouts, History, and form screens
  widgets/     Reusable status chip, empty state, and checkout card
  utils/       Date formatting, validation, and shared helpers
```

## How to run

This app uses `sqflite`, so run it on an Android emulator or device
(it does not run in Chrome).

1. Install Flutter and start an Android emulator.
2. In the project folder, run:

   ```
   flutter pub get
   flutter devices
   flutter run -d <emulator-id>
   ```

   For example: `flutter run -d emulator-5554`

Sample equipment and borrowers are added the first time the app runs so the
workflow can be tested right away.