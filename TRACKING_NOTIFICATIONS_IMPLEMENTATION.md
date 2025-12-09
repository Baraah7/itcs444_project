# Tracking and Notifications System Implementation

## Overview

This document describes the complete Tracking and Notifications System implemented for the rental management application.

## Features Implemented

### 1. Rental Tracking System

- **Track rental status and remaining duration** per item and per rental
- **Real-time monitoring** of active rentals
- **Progress tracking** with visual indicators
- **Rental history** for users and admins
- **Statistics dashboard** showing total, active, completed, and overdue rentals

### 2. Automatic Notifications

- **Rental reminders**: Sent 3 days before return date
- **Overdue alerts**: Sent when rental passes due date
- **Donation notifications**: Admins notified of new donation submissions
- **Maintenance alerts**: Admins notified of equipment requiring maintenance
- **Status updates**: Users notified when rental status changes (approved, picked up, returned)

### 3. User Features

- View current active rentals with countdown timers
- Access complete rental history
- Receive notifications for all rental-related events
- Track rental progress with visual progress bars

### 4. Admin Features

- Monitor all active rentals across all users
- View complete rental history for all users
- Receive notifications for new rentals, overdue items, donations, and maintenance
- Track system-wide rental statistics

## Files Created/Modified

### Models

- `lib/models/notification_model.dart` - Notification data structure

### Services

- `lib/services/notification_service.dart` - Handles sending and retrieving notifications
- `lib/services/tracking_service.dart` - Manages rental tracking and history
- `lib/services/background_notification_service.dart` - Automatic notification checks (runs every 6 hours)
- `lib/services/reservation_service.dart` - MODIFIED to send notifications on rental events

### Providers

- `lib/providers/notification_provider.dart` - State management for notifications
- `lib/providers/tracking_providers.dart` - State management for tracking

### Screens

- `lib/tracking/tracking_screen.dart` - User rental tracking screen
- `lib/notification_screen.dart/notification_screen.dart` - Notification display screen
- `lib/screens/admin/admin_tracking_screen.dart` - Admin tracking dashboard

### Widgets

- `lib/widgets/rental_tracking_card.dart` - Reusable rental display card with progress

### Main App

- `lib/main.dart` - MODIFIED to initialize providers and background service

## How It Works

### Notification Flow

1. **Rental Created**: User creates rental → Notification sent to user and admins
2. **Status Changed**: Admin updates status → User receives notification
3. **Background Checks**: Every 6 hours, system checks for:
   - Rentals due in 3 days → Send reminders
   - Overdue rentals → Send overdue alerts
   - Pending donations → Notify admins
   - Equipment in maintenance → Notify admins

### Tracking Flow

1. **Real-time Updates**: Uses Firestore streams for live data
2. **Status Monitoring**: Tracks rental progress and calculates remaining time
3. **History Access**: Provides complete rental history with filtering

## Usage Examples

### For Users

```dart
// View tracking screen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => TrackingScreen(),
));

// View notifications
Navigator.push(context, MaterialPageRoute(
  builder: (context) => NotificationScreen(),
));
```

### For Admins

```dart
// View all rentals tracking
Navigator.push(context, MaterialPageRoute(
  builder: (context) => AdminTrackingScreen(),
));
```

### Accessing Providers

```dart
// Get notification count
final notificationProvider = Provider.of<NotificationProvider>(context);
int unreadCount = notificationProvider.unreadCount;

// Get active rentals
final trackingProvider = Provider.of<TrackingProvider>(context);
List<Rental> activeRentals = trackingProvider.activeRentals;
```

## Notification Types

- `rental_reminder` - Upcoming return date reminder
- `overdue` - Rental is past due date
- `donation` - New donation submission
- `maintenance` - Equipment needs maintenance
- `approval` - Rental status change (approved, picked up, returned, cancelled)

## Database Structure

### Notifications Collection

```
notifications/
  {notificationId}/
    - id: string
    - userId: string
    - title: string
    - message: string
    - type: string
    - createdAt: timestamp
    - isRead: boolean
    - data: map (optional)
```

## Integration Points

### Existing Rental Model

The system uses the existing `Rental` model which already includes:

- `isOverdue` - Check if rental is overdue
- `daysRemaining` - Calculate days until due
- `progressPercentage` - Visual progress indicator
- `statusColor`, `statusIcon`, `statusText` - UI helpers

### Reservation Service Integration

The `ReservationService` now automatically sends notifications when:

- New rental is created
- Rental status is updated
- Rental is approved/rejected

## Background Service

The `BackgroundNotificationService` runs periodic checks every 6 hours to:

1. Check all active rentals for upcoming due dates
2. Check for overdue rentals
3. Check for pending donations
4. Check for equipment requiring maintenance

## Next Steps (Optional Enhancements)

1. Add push notifications using Firebase Cloud Messaging
2. Add email notifications
3. Add SMS notifications for critical alerts
4. Add notification preferences for users
5. Add notification scheduling for custom reminders
6. Add notification history archiving

## Testing

To test the system:

1. Create a rental as a user
2. Check notifications screen for confirmation
3. Update rental status as admin
4. Verify user receives status update notification
5. Wait for background service to run (or manually trigger)
6. Check for reminder/overdue notifications

## Notes

- Background service runs every 6 hours by default (configurable)
- All notifications are stored in Firestore
- Real-time updates use Firestore streams
- No external code was removed, only additions made
