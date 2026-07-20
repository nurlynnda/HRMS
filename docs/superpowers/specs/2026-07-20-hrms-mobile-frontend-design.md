# HRMS Mobile App — Frontend Design

Date: 2026-07-20
Status: Approved

## Summary

Build the frontend (visual/interactive layer only, no real backend) of a mobile
HRMS (Human Resources Management System) app for employees, in Dart/Flutter.
The UI design already exists as an exported HTML mockup
(`Copy of Modern HRMS Mobile App/HRMS Mobile App.dc.html`) built with Claude's
design tool. This spec translates that mockup into a Flutter project structure
and defines the build plan.

Backend integration, real authentication, and real face recognition are
explicitly out of scope for this phase — data is hardcoded/fake, and
"face check-in" uses the phone's own biometric unlock rather than actual
face-recognition AI.

## Source design reference

Original HTML export: `C:\Users\CMT-Lynnda\Downloads\Copy of Modern HRMS Mobile App\HRMS Mobile App.dc.html`

Design tokens observed in the export (carry these into Flutter's theme):
- Primary font: "Plus Jakarta Sans" (fallback: Manrope, Figtree)
- Primary accent color: `#10B981` (green), with darker `#059669` for gradients
- Background: `#F1F5F9` (light slate)
- Text: `#0f172a` (near-black), secondary text `#64748b` / `#94a3b8`
- Card style: white background, `border-radius: 14–22px`, soft drop shadow
- Currency: Malaysian Ringgit ("RM"), consistent with the tms-v2 Malaysia context

## Screens (from the mockup)

Grouped by the bottom navigation tab they belong to:

**Login / auth overlay**
- Login (email + password, "Sign in with Face ID" button)

**Home tab**
- Home dashboard: greeting, clock-in status card, quick actions (Attendance,
  Leave, Claims, Payslip), weekly attendance hours chart, leave balance
  summary (donut + list), announcements list

**Attendance tab**
- Attendance main: today's clock in/out (circular progress ring), clock
  in/out button, weekly bar chart + stats, recent entries
- Attendance History (sub-page): filter chips, stats summary, full record list
- Face Check-in overlay: camera-preview visual with scan animation
  (scanning → verifying → success states) — shared by clock-in and login

**Leave tab**
- Leave main: upcoming holiday banner, team leave calendar, "who's away this
  week" list, "my requests" list
- Leave Balance (sub-page): per-leave-type balance cards with progress bars
- Leave History (sub-page): filter chips + record list, empty state
- Leave Request — type picker (sub-page)
- Leave Request Form (sub-page): leave category variant, duration (full/half
  day etc.), date-range calendar picker, MC (medical certificate) photo
  upload, submit
- Leave Request Detail (sub-page): view a single request, status, reason
- Leave Request Done (confirmation)

**Me tab (profile)**
- Me main: profile summary, links to sub-pages
- Personal Information (sub-page)
- Documents (sub-page)
- Settings (sub-page)

**Claims (reached via Home quick action)**
- Claims main: list of claims
- Claim Entitlements/Balance (sub-page)
- Claim Form (sub-page): amount, receipt photo, project selection, over-limit
  warning
- Claim Detail (sub-page)
- Claim Done (confirmation)

**Payslip (reached via Home quick action)**
- Payslip main: list of past payslips
- Payslip Detail (sub-page): earnings, deductions, net pay, "Download PDF"

## Architecture

**Language/framework:** Dart + Flutter, targeting Android first (iOS later —
requires a Mac to test properly).

**Folder structure** (feature-based):

```
lib/
  main.dart              # app entry point
  app.dart                # navigation shell + theme wiring
  models/                 # data shapes: Employee, LeaveRequest, Claim, Payslip, AttendanceRecord...
  data/
    fake_data.dart         # hardcoded fake data matching the mockup's example content
  state/
    app_state.dart         # shared app state (auth, clock-in status, leave/claims/payslip data)
  screens/
    login/
    home/
    attendance/
    leave/
    profile/               # "Me" tab
    claims/
    payslip/
  widgets/                 # shared reusable pieces (stat tile, balance card, chip, etc.)
  theme/
    app_theme.dart         # colors, fonts, spacing from the design tokens above
```

**Navigation:**
- Bottom tab bar (Home / Attendance / Leave / Me) using `IndexedStack` so each
  tab preserves its own navigation history when switching tabs.
- Drill-in sub-pages within a tab use standard push navigation (back button
  behavior matches the mockup's back arrows).
- Full-screen overlays (Login, Face Check-in) render on top of the tab shell,
  matching the mockup's `position:absolute;inset:0` overlay pattern.

**State management:** `Provider` package. A single `AppState`
(`ChangeNotifier`) holds cross-screen data (login status, clock-in status,
leave balances/requests, claims, payslips) loaded from `fake_data.dart` at
startup. Screens read from `AppState` via `Provider`/`Consumer` and call
methods on it (e.g. `appState.clockIn()`, `appState.submitLeaveRequest(...)`)
to make changes; dependent screens redraw automatically.

**Face check-in / login biometric:** Use the `local_auth` package to invoke
the phone's built-in Face ID / fingerprint unlock, confirming "this is the
employee's phone" rather than doing real face-recognition matching. The
mockup's camera-scan visual (scanning/verifying/success animation) is kept
purely as UI, layered on top of the real biometric prompt result.

**Data:** All data is hardcoded in `data/fake_data.dart`, structured to match
what the real backend would eventually return, so swapping in real API calls
later doesn't require changing screen code — only the data-loading layer.

## Build order (phased)

1. Foundation — project setup, theme matching design tokens, bottom-nav shell
   with placeholder tab screens
2. Home tab
3. Attendance tab (incl. face check-in overlay)
4. Leave tab (incl. request flow, calendar, history)
5. Me tab (profile, personal info, documents, settings)
6. Claims (list, entitlements, form, detail, confirmation)
7. Payslip (list, detail)
8. Login screen + wiring as app entry gate; final visual polish pass against
   the mockup

Each phase is verified by running the app and comparing it against the
mockup before moving to the next phase.

## Testing approach

Frontend-only, fake-data build for a Flutter beginner: verification is
primarily manual/visual (run the app after each phase, compare to the
mockup) rather than automated tests. Automated widget/unit tests can be
layered in later once screens exist and real backend integration begins.

## Out of scope (this phase)

- Real backend / API integration
- Real authentication (JWT, sessions, etc.)
- Real face-recognition matching
- iOS-specific testing (Android first)
- Push notifications, offline sync, or any data persistence beyond in-memory
  fake data
