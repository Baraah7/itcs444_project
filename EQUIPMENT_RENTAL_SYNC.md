# Equipment and Rental Synchronization System

## Overview
This document explains how equipment reservations are created, managed, and synchronized with Firestore.

## System Flow

### 1. User Reserves Equipment
**Location**: `lib/screens/user/reservation_screen.dart`

When a user reserves equipment:
- User selects dates and quantity
- System calls `ReservationService.createRental()`
- A new rental document is created in Firestore `rentals` collection with status `pending`
- Equipment status is automatically synced via `EquipmentService.syncEquipmentWithRental()`

### 2. Admin Actions and Equipment Sync
**Location**: `lib/screens/admin/reservation_management.dart`

Admin can perform these actions, each syncing with equipment:

#### Approve Reservation
- Status changes: `pending` → `approved`
- Equipment: `availableQuantity` decreases
- Equipment status: Updates to `rented` if all units are reserved

#### Check Out Equipment
- Status changes: `approved` → `checked_out`
- Equipment: Quantity remains reserved
- User can now pick up the equipment

#### Mark as Returned
- Status changes: `checked_out` → `returned`
- Equipment: `availableQuantity` increases
- Equipment status: Changes to `available`
- Equipment availability: Set to `true`

#### Cancel Reservation
- Status changes: Any → `cancelled`
- Equipment: `availableQuantity` increases (releases reserved quantity)
- Equipment status: Changes to `available`
- Shown in reports page

#### Mark for Maintenance
- Status changes: `returned` → `maintenance`
- Equipment: Status changes to `maintenance`
- Equipment availability: Set to `false`
- Item moves to maintenance management page
- Shown in reports page

#### Mark Equipment Available (from Maintenance)
- Equipment status: `maintenance` → `available`
- Equipment availability: Set to `true`
- Item returns to equipment list

## Key Services

### EquipmentService
**Location**: `lib/services/equipment_service.dart`

```dart
// Syncs equipment status with rental changes
syncEquipmentWithRental(equipmentId, rentalStatus, quantity)

// Marks equipment as available
markEquipmentAvailable(equipmentId)

// Gets equipment by status
getEquipmentByStatus(status)

// Gets all maintenance equipment
getMaintenanceEquipment()
```

### ReservationService
**Location**: `lib/services/reservation_service.dart`

All rental status updates automatically call `EquipmentService.syncEquipmentWithRental()`:
- `createRental()` - Creates rental and syncs equipment
- `updateRentalStatus()` - Updates rental and syncs equipment
- `cancelRental()` - Cancels rental and releases equipment

### ReportsService
**Location**: `lib/services/reports_service.dart`

```dart
// Gets all rentals including cancelled and maintenance
getAllRentalsForReports()

// Gets only cancelled rentals
getCancelledRentals()

// Gets only maintenance rentals
getMaintenanceRentals()

// Gets completed rentals (returned, cancelled, maintenance)
getCompletedRentals()

// Gets rental statistics
getRentalStatistics()
```

## Firestore Collections

### rentals
```json
{
  "id": "rental_id",
  "userId": "user_id",
  "userFullName": "John Doe",
  "equipmentId": "equipment_id",
  "equipmentName": "Wheelchair",
  "itemType": "Wheelchair",
  "startDate": "2024-01-01T00:00:00.000Z",
  "endDate": "2024-01-08T00:00:00.000Z",
  "actualReturnDate": null,
  "totalCost": 70.0,
  "status": "pending|approved|checked_out|returned|cancelled|maintenance",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "adminNotes": "Optional notes",
  "quantity": 1
}
```

### equipment
```json
{
  "id": "equipment_id",
  "name": "Standard Wheelchair",
  "category": "Mobility",
  "type": "Wheelchair",
  "description": "...",
  "rentalPrice": 10.0,
  "availability": true,
  "condition": "Good",
  "quantity": 5,
  "availableQuantity": 3,
  "status": "available|rented|maintenance",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## Status Flow Diagram

```
User Reserves → [pending] → Admin Approves → [approved] → Admin Checks Out → [checked_out]
                    ↓                            ↓                               ↓
                [cancelled]                  [cancelled]                    [returned]
                    ↓                            ↓                               ↓
              Reports Page                 Reports Page                   [maintenance]
                                                                                 ↓
                                                                          Maintenance Page
                                                                                 ↓
                                                                          Reports Page
```

## Pages and Their Data

### Equipment List (User)
- Shows equipment with `status: 'available'` and `availability: true`
- Reflects real-time changes from admin actions

### My Reservations (User)
- Shows user's rentals with all statuses
- Real-time updates when admin changes status

### Reservation Management (Admin)
- Shows all rentals
- Can filter by status
- Actions update both rental and equipment

### Maintenance Management (Admin)
- Shows equipment with `status: 'maintenance'`
- Shows rentals with `status: 'maintenance'`
- Can mark equipment as available

### Reports Page (Admin)
- Shows all rentals including:
  - Cancelled rentals (`status: 'cancelled'`)
  - Maintenance rentals (`status: 'maintenance'`)
  - Returned rentals (`status: 'returned'`)
- Provides statistics and analytics

## Automatic Synchronization

All equipment status changes are automatic:

1. **User reserves** → Equipment quantity decreases
2. **Admin approves** → Equipment marked as reserved
3. **Admin cancels** → Equipment quantity increases
4. **User returns** → Equipment quantity increases, marked available
5. **Admin marks maintenance** → Equipment marked unavailable, moved to maintenance
6. **Admin marks available** → Equipment marked available, returns to list

No manual intervention needed - the system keeps everything in sync!
