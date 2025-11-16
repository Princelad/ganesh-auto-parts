# Ganesh Auto Parts

A comprehensive Flutter-based application for managing auto parts inventory, sales, purchases, and customer relationships with offline-first capabilities and real-time synchronization.

## 🚀 Features

- **Inventory Management**: Track parts, categories, stock levels, and locations
- **Sales & Invoicing**: Create invoices, manage payments, and track sales history
- **Purchase Management**: Handle purchase orders and supplier relationships
- **Customer Management**: Maintain customer records and transaction history
- **Offline-First**: Full functionality without internet connectivity
- **Real-time Sync**: Automatic synchronization when online
- **Multi-platform**: Supports Android, Web, and other platforms

## 📋 Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- Dart SDK (included with Flutter)
- Android Studio / VS Code with Flutter extensions
- Git

## 🛠️ Installation

1. **Clone the repository:**

   ```zsh
   git clone https://github.com/yourusername/ganesh_auto_parts.git
   cd ganesh_auto_parts
   ```

2. **Install dependencies:**

   ```zsh
   flutter pub get
   ```

3. **Run the application:**

   ```zsh
   flutter run
   ```

   For specific platforms:

   ```zsh
   flutter run -d android    # For Android
   flutter run -d chrome     # For Web
   ```

## 📁 Project Structure

```
lib/
├── main.dart              # Application entry point
├── core/                  # Core functionality
│   ├── constants/        # App-wide constants
│   ├── utils/           # Utility functions
│   └── theme/           # App theme configuration
├── data/                 # Data layer
│   ├── models/          # Data models
│   ├── repositories/    # Repository implementations
│   └── services/        # API and local services
├── domain/              # Business logic layer
│   ├── entities/        # Domain entities
│   └── repositories/    # Repository interfaces
└── presentation/        # UI layer
    ├── screens/         # Application screens
    ├── widgets/         # Reusable widgets
    └── providers/       # State management
```

## 🏗️ Architecture

This project follows Clean Architecture principles with:

- **Presentation Layer**: UI components and state management
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Data sources and repository implementations

State management is handled using Provider/Riverpod for reactive updates.

## 🔄 Offline-First & Sync

The application uses an offline-first approach:

- All data is stored locally using SQLite/Hive
- Changes are queued for synchronization
- Automatic sync when connection is available
- Conflict resolution for concurrent updates

## 🧪 Testing

Run tests with:

```zsh
flutter test                    # Unit tests
flutter test integration_test/  # Integration tests
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For issues and questions, please open an issue in the GitHub repository.

## 🙏 Acknowledgments

Built with [Flutter](https://flutter.dev/) - Google's UI toolkit for building beautiful, natively compiled applications.
