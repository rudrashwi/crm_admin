# CRM Admin Application

A professional, fully responsive CRM Admin application built with Flutter. Designed for high-level business management with a focus on aesthetics, formal UI, and robust logic.

## Features

- **Authentication**: Admin registration with real-time username availability check and suggestions.
- **Dashboard**: Comprehensive analytics with real-time stats and lead trends using `fl_chart`.
- **User Management**: Create, view, terminate, and reactivate Employees and Sub-Admins.
- **Lead Management**: Full CRUD operations for leads, including assignment to employees.
- **Responsive UI**: Adaptive layouts for different screen sizes.
- **State Management**: Powered by `Provider` for efficient and scalable state handling.
- **Networking**: Robust API integration using `Dio` with centralized logging.

## Directory Structure

```
lib/
├── core/               # Core utilities, constants, and API configuration
│   ├── api/            # API Client and Endpoints
│   ├── constants/      # App colors, strings, and styles
│   └── utils/          # Logger, PrefManager, and Responsive helpers
├── data/               # Data layer
│   ├── models/         # Data models (Auth, Leads, Dashboard, etc.)
│   └── repositories/   # API Repository implementations
├── logic/              # Business logic layer
│   └── providers/      # State management using Provider
└── ui/                 # Presentation layer
    ├── screens/        # App screens (Auth, Dashboard, Leads, etc.)
    ├── theme/          # App theme configuration
    └── widgets/        # Reusable UI components
```

## Setup Instructions

1. **Dependencies**: Run `flutter pub get` to install all required packages.
2. **Environment**: Ensure you have Flutter SDK installed (v3.0.0 or higher).
3. **Run**: Use `flutter run` to start the application.

## Logging

The application uses the `logger` package for readable and detailed logs. API requests, responses, and errors are automatically logged with:
- Request Method and Path
- Headers and Payload
- Response Status and Data
- Error Messages and Stack Traces

## API Integration

All API calls are centralized in the `data/repositories` layer. The `ApiClient` in `core/api` handles automatic injection of:
- `Authorization` Bearer Token
- `X-Tenant-Id` Header
- `X-User-Id` Header (where required)

---
Developed with ❤️ by Antigravity
