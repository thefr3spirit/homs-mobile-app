# Hotel Management System - Mobile App

A comprehensive Flutter mobile application for hotel management, featuring real-time booking management, customer tracking, payment processing, and analytics.

## Features

### 🏨 Core Management
- **Dashboard**: Real-time overview of hotel operations with daily summaries
- **Bookings**: Create, manage, and track guest bookings
- **Customers**: Complete customer database with pending balance tracking
- **Rooms**: Room inventory management and availability tracking
- **Payments**: Payment recording and transaction history

### 📊 Analytics & Reports
- **Revenue Analytics**: Daily, weekly, monthly revenue insights
- **Occupancy Analytics**: Room occupancy rates and trends
- **Pending Balances**: Track customers with outstanding payments

### 🔐 Security
- JWT-based authentication
- Role-based access control
- Secure token storage using flutter_secure_storage

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget with setState
- **Networking**: HTTP package
- **Secure Storage**: flutter_secure_storage
- **UI Components**: Material Design 3

## Backend Integration

This app connects to the [HoMS Backend API](https://github.com/thefr3spirit/homs-backend) hosted at:
- Production: `https://homs-backend-txs8.onrender.com`

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio or VS Code with Flutter extensions
- iOS development: Xcode (for iOS builds)
- Android development: Android SDK

### Installation

1. Clone the repository:
```bash
git clone https://github.com/thefr3spirit/homs-mobile-app.git
cd homs-mobile-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure the API endpoint (if needed):
Edit `lib/services/api_service.dart` to update the base URL:
```dart
static const String baseUrl = 'https://your-backend-url.com';
```

4. Run the app:
```bash
flutter run
```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── booking.dart
│   ├── customer.dart
│   ├── payment.dart
│   ├── room.dart
│   └── user.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── bookings_screen.dart
│   ├── customers_screen.dart
│   ├── payments_screen.dart
│   ├── rooms_screen.dart
│   ├── pending_balances_screen.dart
│   └── analytics_screen.dart
└── services/                 # Business logic
    ├── api_service.dart      # HTTP client
    ├── auth_service.dart     # Authentication
    └── cache_service.dart    # Local caching
```

## API Endpoints Used

- `POST /auth/login` - User authentication
- `GET /daily-summary` - Dashboard summary
- `GET /bookings` - List bookings
- `GET /customers` - List customers
- `GET /customer-balances` - Pending balances
- `GET /payments` - Payment history
- `GET /rooms` - Room inventory
- And more...

## Features in Detail

### Dashboard
- Today's revenue, bookings, and occupancy
- Quick access to all major features
- Pending balances overview
- Real-time updates

### Booking Management
- Create new bookings with guest details
- Track check-in/check-out dates
- Monitor payment status
- Calculate total amounts with room rates

### Customer Balance Tracking
- View all customers with pending balances
- Real-time balance calculations
- Payment history per customer
- Contact information access

### Analytics
- Revenue trends visualization
- Occupancy rate tracking
- Historical data analysis
- Export capabilities (planned)

## Authentication

The app uses JWT (JSON Web Tokens) for authentication:
1. Users log in with email/password
2. Backend returns JWT token
3. Token stored securely using flutter_secure_storage
4. Token included in all API requests via Authorization header
5. Auto-logout on token expiration

## Development

### Running Tests
```bash
flutter test
```

### Code Formatting
```bash
flutter format lib/
```

### Analyze Code
```bash
flutter analyze
```

## Configuration

### API Service
Update the base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-backend-url.com';
```

### App Icon
Replace icons in:
- `android/app/src/main/res/mipmap-*/`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Troubleshooting

### 401 Authentication Error
- Log out and log back in
- Check token expiration
- Verify backend is running

### Network Errors
- Check internet connection
- Verify backend URL is correct
- Check firewall settings

### Build Issues
- Run `flutter clean`
- Delete `pubspec.lock` and run `flutter pub get`
- Update Flutter SDK: `flutter upgrade`

## Recent Updates (Feb 2026)

- ✅ Fixed pending balance calculations
- ✅ Added emergency contact field support
- ✅ Improved authentication error handling
- ✅ Enhanced dashboard navigation
- ✅ Updated app icon to hotel theme
- ✅ Added logout functionality for auth errors
- ✅ Migrated customer ID from int to UUID/String

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is proprietary software for Lemi Hotel.

## Support

For support, email beofr3spirit@gmail.com or open an issue in the repository.

## Related Projects

- [HoMS Backend](https://github.com/thefr3spirit/homs-backend) - FastAPI backend service

---

**Version**: 1.0.0  
**Last Updated**: February 25, 2026  
**Developed by**: @thefr3spirit
