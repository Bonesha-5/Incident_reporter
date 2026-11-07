# ALU Incident Reporter

A Flutter mobile app for African Leadership University where students report campus problems (water, electricity, facilities, furniture, sanitation, safety, internet) and campus staff track them to resolution.

**Demo video:** https://youtu.be/gd8bi5Mfz5M
**Technical report:** see the PDF submitted on the course page

## Features

**Students**
- Register with an ALU email (`@alustudent.com` / `@alueducation.com`) and verify it
- Report an issue: category (or "Other"), title, description, campus location, urgency, optional photo, optional anonymity
- Browse all campus reports with search, category and status filters, and sorting
- Follow a report's live progress timeline with staff notes
- Tap **Me too** instead of reporting the same problem twice
- Edit or delete own reports while they are still "Submitted"
- Notifications: bell badge, notifications list, and a live pop-up banner
- Light, dark or phone theme, remembered after logout

**Staff**
- Dashboard with counts by status and a list ordered by urgency and number of students affected
- Update a report's status with a message to students
- See the real name behind anonymous reports

## Tech stack

| Part | Technology |
| --- | --- |
| App | Flutter (Dart), Material 3 |
| State management | Provider |
| Login | Firebase Authentication |
| Database | Cloud Firestore (with security rules) |
| Photo storage | Supabase Storage |

## Architecture

```
Screens and widgets  →  Providers (state)  →  Services  →  Firebase / Supabase
        ↑ rebuild on notifyListeners      ↑ live Firestore streams
```

```
lib/
  main.dart, app.dart   start-up, providers, themes, notification banner
  config/               Supabase settings
  core/                 constants, theme, validators, formatters
  models/               AppUser, Incident, IncidentUpdate, AppNotification
  services/             auth, incident, notification, storage
  providers/            theme, auth, incident, notification
  screens/              auth, home, report, reports, staff, profile, notifications
  widgets/              reusable components
test/                   unit tests
firestore.rules         Firestore security rules
```

## Getting started

### Requirements
- Flutter SDK (stable channel)
- An Android phone with USB debugging, an emulator, or Chrome

### Run the app
```bash
git clone [your repository link]
cd alu_incident_reporter
flutter pub get
cp env.example.json env.json      # on Windows: copy env.example.json env.json
flutter run --dart-define-from-file=env.json
```

### Using your own backend (optional)
The repository is already connected to the project's Firebase and Supabase. To use your own:
1. Create a Firebase project, enable **Email/Password** sign-in and **Cloud Firestore**, then run `flutterfire configure`.
2. Paste the contents of `firestore.rules` into **Firestore → Rules** and publish.
3. Create a Supabase project with a **public** bucket called `incident-photos` (images, max 5 MB) and an INSERT policy for the `anon` role, then put your project URL and anon key in `lib/config/supabase_config.dart`.

## Roles

Every new account is a **student**. To make someone **staff**, open **Firestore → users → their document** and change `role` from `student` to `staff`. Users cannot change their own role; the security rules block it.

**Test staff account:** `env.json` (not committed) can list extra emails allowed to register, for testing staff without an `@alueducation.com` address. In production, this list is empty. See `env.example.json`.

## Security

`firestore.rules` ensures that:
- Only signed-in users with verified emails can read data
- Students can edit or delete only their own reports, and only while "Submitted"
- Only staff can change a status or create notifications
- Anonymous reports store no name on the report itself
- Each user can read only their own notifications and profile

## Testing

```bash
flutter test
```
Unit tests cover form validation, the data models and date formatting. End-to-end tests were run manually on an Android phone (student) and Chrome (staff) at the same time; see the technical report.

## Known limitations
- No push notifications while the app is closed (needs Cloud Functions on the paid Firebase plan)
- Supabase uploads use the public anonymous role, limited to images up to 5 MB
- Search and filtering run on the device, which suits a single campus

## Author
[Your full name], BSc Software Engineering, African Leadership University