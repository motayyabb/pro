# TaskTrack - Task Management Mobile App

**TaskTrack** is a task management mobile application built with **Flutter**. This app helps users manage their tasks efficiently by providing features such as adding, editing, deleting, marking tasks as completed, generating PDF reports, and receiving notifications. It also supports theme customization (dark/light mode) and integrates local storage (SQLite) to save task data.

---

## Features

- **Home Screen**: View all tasks and interact with each one (edit, delete, mark as completed).
- **Add Task Screen**: Add new tasks with a title, description, and due date.
- **Edit Task Screen**: Modify details of an existing task.
- **Completed Tasks Screen**: View and manage tasks that have been marked as completed.
- **Settings Screen**: Change between dark and light modes and manage notifications.
- **Notification System**: Get reminders or alerts about tasks.
- **PDF Report**: Generate a PDF report of all tasks and share or print them.

---

| **Screen**               | **Screenshot**                             | **Screen**               | **Screenshot**                             |
|--------------------------|--------------------------------------------|--------------------------|--------------------------------------------|
| **Home Screen**           | ![Home Screen](https://github.com/user-attachments/assets/e4de2584-ee36-433f-b90b-fed06637ad3a) | **Add Task Screen**       | ![Add Task Screen](https://github.com/user-attachments/assets/e3aff5e3-82d6-4672-b05b-5d4cc08627d4) |
| **Completed Tasks Screen**| ![Completed Tasks Screen](https://github.com/user-attachments/assets/56b5edc8-dbb8-4220-86f3-39a9ba6b9cca) | **Edit Task Screen**      | ![Edit Task Screen](https://github.com/user-attachments/assets/c012d2de-86be-4b2c-ad5d-903860210bcd) |
| **Settings Screen**       | ![Settings Screen](https://github.com/user-attachments/assets/b4f059e8-1841-49fb-b9d8-d54f8d994d7d) | **Notification Settings** | ![Notification Settings](https://github.com/user-attachments/assets/98235a5f-1d28-41b4-99e8-71221e7023be) |
| **Enable Notifications**  | ![Enable Notifications](https://github.com/user-attachments/assets/e349f39a-d70c-4c6b-9894-2202b0a2bd2b) | **PDF Saver**            | ![PDF Saver](https://github.com/user-attachments/assets/0de54f23-fb9a-41d3-bae0-d5fcfababf3f) |





---
## Video Demo
![1000098246](https://github.com/user-attachments/assets/10f2fe03-2309-40b6-a9e8-4f4378779917)
---
## Dependencies

This project uses the following dependencies:

- **flutter**: SDK for building cross-platform mobile apps.
- **sqflite**: SQLite database management for local data storage (null-safe version).
- **path_provider**: Helps to retrieve the correct file path for storing SQLite databases.
- **flutter_spinkit**: Spinner animations for loading indicators (check if null-safe).
- **cupertino_icons**: Provides Cupertino (iOS-style) icons for the app.
- **carousel_slider**: Used for carousel widgets (null-safe version).
- **flutter_local_notifications**: Allows for local notifications to notify the user of tasks and reminders.
- **provider**: State management solution for managing state throughout the app (e.g., dark mode).
- **permission_handler**: Manages app permissions for tasks like notifications and storage access.
- **pdf**: Provides PDF generation capabilities for tasks and reports.
- **printing**: Used to print the generated PDFs.

### Example `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.4.0  # SQLite for database management (null-safe version)
  path_provider: ^2.1.5  # To get the correct path for storing the SQLite file
  flutter_spinkit: ^5.1.0  # Spinner animations (check if null-safe)
  cupertino_icons: ^1.0.0  # Cupertino icons for iOS-like design
  carousel_slider: ^4.0.0  # For carousel widget (null-safe version)
  flutter_local_notifications: ^17.2.4 # For local notifications
  provider: ^6.1.2  # For state management, if needed in the future (useful for managing dark mode state)
  permission_handler: ^10.2.0
  pdf: ^3.6.0
  printing: ^5.5.0
---
## Installation Instructions

### Prerequisites

To run this app, you need the following:
- **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Included with the Flutter installation.
- **Android Studio** or **Visual Studio Code**: Preferred IDE for Flutter development.
- **An Android or iOS device** or emulator to run the app.

### Steps to Run the App

1. **Clone the Repository**

   Clone the project to your local machine:
   ```bash
   git clone https://github.com/motayyabb/tasktrack.git
