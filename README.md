# 💰 Penni - Personal Finance Tracker

<div align="center">

![Penni Logo](assets/images/logo.png)

**A modern, intuitive expense tracking app built with Flutter to help you manage your finances efficiently** 📱💸

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

</div>

## 🌟 Features

### 📊 **Dashboard & Analytics**
- **Real-time financial overview** with spending summaries
- **Interactive pie charts** showing expense distribution by category
- **Recent transactions** quick view
- **Monthly budget tracking** with visual progress indicators

### 💳 **Transaction Management**
- **Add income and expenses** with detailed categorization
- **12 predefined categories**: Food 🍕, Transport 🚌, Shopping 🛍️, Bills 📄, Health 🏥, Travel ✈️, Entertainment 🎬, Groceries 🛒, Education 📚, Home 🏠, Lend/Borrow 🤝, Others 📦
- **Transaction history** with filtering and search capabilities
- **Edit and delete** transactions with swipe gestures

### 📈 **Budget Planning**
- **Monthly budget setting** and tracking
- **Budget vs actual spending** comparison
- **Visual progress indicators** for budget adherence
- **Budget alerts** and notifications

### 👤 **User Management**
- **Firebase Authentication** with email/password
- **User profile management** with photo upload via Cloudinary
- **Secure data storage** with Firebase Firestore
- **Dark/Light theme** support with system preference detection

### 🔔 **Smart Notifications**
- **Local notifications** for budget alerts
- **Spending reminders** and financial tips
- **Customizable notification preferences**

### 🎨 **Modern UI/UX**
- **Material Design 3** with beautiful animations
- **Responsive design** for all screen sizes
- **Floating sidebar** navigation
- **Bottom navigation** with smooth transitions
- **Custom splash screen** and app icons

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.8.1 or higher) 📱
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase project** setup 🔥
- **Cloudinary account** for image storage ☁️

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/money-tracker-app.git
   cd money-tracker-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** 🔥
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `google-services.json` and place it in `android/app/`
   - Run `flutterfire configure` to generate `firebase_options.dart`

4. **Cloudinary Setup** ☁️
   - Create a Cloudinary account at [Cloudinary](https://cloudinary.com/)
   - Update `lib/config/cloudinary_config.dart` with your credentials

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Screenshots

<div align="center">

| Dashboard | Add Transaction | History | Summary |
|-----------|----------------|---------|---------|
| 📊 Real-time overview | 💰 Quick expense entry | 📋 Transaction list | 📈 Analytics & insights |

</div>

## 🏗️ Project Structure

```
lib/
├── 📁 config/           # App configuration files
│   ├── categories.dart      # Expense categories
│   └── cloudinary_config.dart
├── 📁 core/             # Core app functionality
│   └── theme/               # Theme management
├── 📁 models/           # Data models
│   ├── budget.dart          # Budget model
│   ├── transaction.dart     # Transaction model
│   └── user_profile.dart    # User profile model
├── 📁 screens/          # UI screens
│   ├── auth/               # Authentication screens
│   ├── main_app/           # Main app screens
│   ├── profile/            # Profile management
│   └── settings/           # App settings
├── 📁 services/         # Backend services
│   ├── firebase_service.dart
│   ├── cloudinary_service.dart
│   └── notification_service.dart
├── 📁 utils/            # Utility functions
└── 📁 widgets/          # Reusable UI components
```

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.8.1+ 📱
- **Backend**: Firebase (Auth, Firestore, App Check) 🔥
- **State Management**: Provider 🎯
- **Image Storage**: Cloudinary ☁️
- **Charts**: FL Chart, Pie Chart 📊
- **Notifications**: Flutter Local Notifications 🔔
- **UI Components**: Material Design 3 🎨
- **Icons**: Material Icons, Custom icons 🎭

## 📦 Dependencies

### Core Dependencies
- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `cloud_firestore` - NoSQL database
- `provider` - State management
- `google_fonts` - Typography

### UI & Charts
- `fl_chart` - Beautiful charts and graphs
- `pie_chart` - Pie chart visualization
- `flutter_slidable` - Swipe actions
- `month_year_picker` - Date selection

### Services
- `cloudinary_url_gen` - Image upload and management
- `flutter_local_notifications` - Local notifications
- `flutter_secure_storage` - Secure data storage
- `image_picker` - Image selection

## 🔧 Configuration

### Firebase Configuration
1. Enable Authentication with Email/Password
2. Create Firestore database in production mode
3. Enable Firebase App Check for security
4. Configure security rules for Firestore

### Cloudinary Configuration
1. Create a Cloudinary account
2. Get your Cloud Name, API Key, and API Secret
3. Update the configuration in `lib/config/cloudinary_config.dart`

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository** 🍴
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request** 🚀

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase Team** for the robust backend services
- **Material Design** for the beautiful UI guidelines
- **Open source community** for the amazing packages

## 📞 Support

If you have any questions or need help, please:

- 📧 **Email**: your.email@example.com
- 🐛 **Report Issues**: [GitHub Issues](https://github.com/yourusername/money-tracker-app/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/money-tracker-app/discussions)

---

<div align="center">

**Made with ❤️ and Flutter**

⭐ **Star this repository if you found it helpful!** ⭐

</div>