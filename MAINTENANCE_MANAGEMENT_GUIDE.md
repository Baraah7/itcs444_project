# Maintenance Management System - User Guide

## Overview
The Maintenance Management System allows admins to track and manage equipment that needs maintenance or repair.

## How to Use

### 1. Mark Equipment for Maintenance (2 Ways)

#### Option A: From Equipment Management
1. Go to **Equipment Management**
2. Click the **3-dot menu** on any equipment
3. Select **"Mark for Maintenance"**
4. Enter maintenance notes/reason
5. Click **Confirm**

#### Option B: From Reservation Management
1. Go to **Reservation Management**
2. Find a rental with status **"Checked Out"**
3. Click **"Mark Returned"** button
4. After it's returned, click **"Needs Maintenance"** button
5. The rental will be marked for maintenance

### 2. View Items Under Maintenance
1. Go to **Maintenance Management** screen
2. View the **"Under Maintenance"** tab to see:
   - Equipment marked for maintenance
   - Rentals that need maintenance

### 3. Complete Maintenance
1. In the **"Under Maintenance"** tab
2. Click the **info icon** to view maintenance history
3. Click **"Complete"** button
4. Add completion notes (optional)
5. Equipment will be marked as available again

### 4. View All Equipment
1. Go to the **"All Equipment"** tab
2. See all equipment with their current status
3. Click the **build icon** to mark any equipment for maintenance

### 5. Debug View
- Click the **bug icon (🐛)** in the app bar
- See all rentals and their statuses
- Verify maintenance items are properly tracked

## Features

✅ Mark equipment for maintenance with notes
✅ Track maintenance history with timestamps
✅ View all items under maintenance in one place
✅ Complete maintenance and restore availability
✅ Automatic status synchronization
✅ Visual indicators (purple theme for maintenance)
✅ Debug screen for troubleshooting

## Workflow

```
Equipment/Rental → Mark for Maintenance → Under Maintenance → Complete → Available
```

## Status Flow for Rentals

```
Pending → Approved → Checked Out → Returned → Maintenance (optional) → Available
```

## Notes
- Maintenance logs are stored in Firestore `maintenance_logs` collection
- Equipment status is automatically updated
- Rentals marked as "maintenance" appear in the maintenance screen
- Use the debug screen if items don't appear as expected
