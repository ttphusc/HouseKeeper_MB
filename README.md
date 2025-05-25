# House Keeper Mobile App

A mobile application for HouseKeeper, a home cleaning and service provider app. This project is built with Flutter.

## Features

- Browse and book various home cleaning services
- View featured staff and their ratings
- Learn about the benefits of using HomeHero
- User-friendly interface with a clean design
- Mobile-optimized experience

## Screenshots

The app includes:
- Home screen with banner carousel
- Service listings
- Featured staff section
- Benefits and process explanation

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- Android Studio or VSCode with Flutter extensions
- An emulator or physical device for testing

### Installation

1. Clone the repository to your local machine:
```bash
git clone <repository-url>
```

2. Navigate to the project directory:
```bash
cd HouseKeeper_MB-TranThanhPhuc/housekeeper
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

### Backend Configuration

The app connects to a backend API at `http://127.0.0.1:8000/api`. Make sure your backend server is running and accessible, or update the base URL in the `ApiService` class (`lib/services/api_service.dart`) to point to your actual API endpoint.

## API Endpoints Used

- `/nguoi-dung/get-Data-Dich-Vu` - Get service categories
- `/nguoi-dung/get-Data-Nhan-Vien-Noi-Bat` - Get featured staff
- `/nguoi-dung/get-Data-NhanVien-Flash-Sale` - Get flash sale staff
- `/nguoi-dung/get-chi-tiet-nhan-vien/{id}` - Get staff details

## Project Structure

- `lib/` - Contains all Dart code for the application
  - `main.dart` - Entry point of the application
  - `models/` - Data models
  - `screens/` - Application screens
  - `services/` - API and other services
  - `assets/` - Contains images and other static assets

## Dependencies

- dio: ^5.4.0 - HTTP client for API requests
- carousel_slider: ^4.2.1 - For image carousel
- cached_network_image: ^3.3.1 - For efficient image loading
- flutter_rating_bar: ^4.0.1 - For star ratings
- provider: ^6.1.1 - For state management
- shared_preferences: ^2.2.2 - For local storage

## Future Improvements

- Implement authentication/login flow
- Add service booking functionality
- Add service details screen
- Add staff details screen
- Add order history and tracking
- Implement chat with staff feature
- Add payment integration
