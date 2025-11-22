#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 3cm),
  numbering: "1",
  number-align: center,
)

#set text(
  font: "New Computer Modern",
  size: 11pt,
  lang: "pl",
)

#set par(
  justify: true,
  leading: 0.65em,
)

#set heading(numbering: "1.1")

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  set text(size: 18pt, weight: "bold")
  block(above: 1.5em, below: 1em, it)
}

#show heading.where(level: 2): it => {
  set text(size: 14pt, weight: "bold")
  block(above: 1.2em, below: 0.8em, it)
}

#show heading.where(level: 3): it => {
  set text(size: 12pt, weight: "bold")
  block(above: 1em, below: 0.6em, it)
}

#show raw.where(block: true): it => {
  set block(
    fill: luma(245),
    inset: 10pt,
    radius: 4pt,
    width: 100%,
  )
  set text(font: "DejaVu Sans Mono", size: 9pt)
  it
}

#show raw.where(block: false): it => {
  set text(font: "DejaVu Sans Mono", size: 9.5pt)
  box(
    fill: luma(245),
    inset: (x: 3pt, y: 0pt),
    outset: (y: 3pt),
    radius: 2pt,
    it
  )
}

#align(center)[
  #v(4cm)
  #text(size: 28pt, weight: "bold")[
    measures
  ]

  #v(1cm)
  #text(size: 16pt)[
    Dokumentacja techniczna
  ]

  #v(2cm)
  #text(size: 12pt)[
    System zarządzania pomiarami
  ]

  #v(1fr)
  #text(size: 12pt)[
    Jarosław Piszczała
  ]

  #v(1cm)
  #text(size: 11pt)[
    #datetime.today().display("[day].[month].[year]")
  ]
]

#pagebreak()

#outline(
  title: "Spis treści",
  indent: auto,
)

#pagebreak()

= Uruchomienie aplikacji lokalnie

== Wymagania

- *Docker* 20.10+
- *Docker Compose* 2.0+
- *Git*

== Wersje wykorzystanych narzędzi

=== Backend

- Python 3.11
- FastAPI 0.109+
- PostgreSQL 16
- SQLAlchemy 2.0+

=== Frontend

- Node.js 20
- Vue.js 3.4+
- Vite 5.0+
- Tailwind CSS 3.4+

== Instalacja i uruchomienie

*Wyłącz uruchomione kontenery*

```bash
make down-all
```

*Uruchom aplikację za pomocą Docker Compose:*

```bash
make up
```

*Sprawdź status serwisów:*

```bash
make status
```

*Otwórz aplikację w przeglądarce:*
  - Frontend: `http://localhost:3001`
  - Backend API: `http://localhost:8001`
  - Dokumentacja API (Swagger): `http://localhost:8001/docs`

== Dane logowania

#block(
  fill: luma(250),
  inset: 15pt,
  radius: 4pt,
  width: 100%,
)[
  *Administrator:*
  - Login: `admin`
  - Hasło: `admin123`

  #v(0.5em)

  *Użytkownik (tylko odczyt):*
  - Login: `user`
  - Hasło: `user123`
]

= Adresy URL aplikacji

== Produkcja

- Frontend: #raw("http://measures-app-qi6wn1-136b8d-91-98-152-189.traefik.me")
- Backend: #raw("http://measures-app-qi6wn1-d55542-91-98-152-189.traefik.me")
- Swagger UI: #raw("http://measures-app-qi6wn1-d55542-91-98-152-189.traefik.me/docs")

== Lokalna

- Frontend: `http://localhost:3001`
- Backend API: `http://localhost:8001`
- Swagger UI: `http://localhost:8001/docs`

= Struktura bazy danych

== Diagram ERD

#figure(
  caption: "Diagram związków encji (ERD)",
  {
    set text(font: "DejaVu Sans Mono", size: 9pt)

    block(width: 100%, align(center)[
      #stack(
        dir: ttb,
        spacing: 2em,

        block(
          stroke: black + 1pt,
          width: 200pt,
          inset: 10pt,
        )[
          #align(center)[*users*]
          #line(length: 100%, stroke: black + 0.5pt)
          #v(0.3em)
          #text(size: 8.5pt)[
            id (PK)\
            username\
            email\
            hashed_password\
            is_admin\
            created_at
          ]
        ],

        v(1em),

        block(
          stroke: black + 1pt,
          width: 200pt,
          inset: 10pt,
        )[
          #align(center)[*series*]
          #line(length: 100%, stroke: black + 0.5pt)
          #v(0.3em)
          #text(size: 8.5pt)[
            id (PK)\
            name\
            description\
            min_value\
            max_value\
            color\
            unit\
            created_at\
            created_by (FK) → users.id
          ]
        ],

        v(1em),

        block(
          stroke: black + 1pt,
          width: 200pt,
          inset: 10pt,
        )[
          #align(center)[*measurements*]
          #line(length: 100%, stroke: black + 0.5pt)
          #v(0.3em)
          #text(size: 8.5pt)[
            id (PK)\
            series_id (FK) → series.id\
            value\
            timestamp\
            created_by (FK) → users.id
          ]
        ],
      )
    ])
  }
)

== Opis tabel

=== Tabela `users` -- Użytkownicy systemu

#table(
  columns: (auto, 1fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: (left, left),

  [*Kolumna*], [*Opis*],
  [`id`], [Klucz główny (INTEGER)],
  [`username`], [Unikalna nazwa użytkownika (STRING 50)],
  [`email`], [Unikalny adres email (STRING 100)],
  [`hashed_password`], [Zahashowane hasło bcrypt (STRING 255)],
  [`is_admin`], [Flaga administratora (BOOLEAN)],
  [`created_at`], [Data utworzenia konta (DATETIME)],
)

=== Tabela `series` -- Serie pomiarowe

#table(
  columns: (auto, 1fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: (left, left),

  [*Kolumna*], [*Opis*],
  [`id`], [Klucz główny (INTEGER)],
  [`name`], [Nazwa serii, np. "Temperature Sensor 1" (STRING 100)],
  [`description`], [Opis serii (STRING 500, opcjonalny)],
  [`min_value`], [Minimalna wartość zakresu (FLOAT)],
  [`max_value`], [Maksymalna wartość zakresu (FLOAT)],
  [`color`], [Kolor wykresu w formacie hex (STRING 7, np. "\#3B82F6")],
  [`unit`], [Jednostka miary (STRING 20, np. "°C", "%", "hPa")],
  [`created_at`], [Data utworzenia (DATETIME)],
  [`created_by`], [Klucz obcy do users.id (INTEGER, FK)],
)

=== Tabela `measurements` -- Pomiary

#table(
  columns: (auto, 1fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: (left, left),

  [*Kolumna*], [*Opis*],
  [`id`], [Klucz główny (INTEGER)],
  [`series_id`], [Klucz obcy do series.id (INTEGER, FK)],
  [`value`], [Wartość pomiaru (FLOAT)],
  [`timestamp`], [Czas pomiaru (DATETIME)],
  [`created_by`], [Klucz obcy do users.id (INTEGER, FK, opcjonalny)],
)

== Relacje

+ *users → series (1:N)*
  - Jeden użytkownik może utworzyć wiele serii
  - `series.created_by` → `users.id`

+ *users → measurements (1:N)*
  - Jeden użytkownik może utworzyć wiele pomiarów
  - `measurements.created_by` → `users.id`

+ *series → measurements (1:N)*
  - Jedna seria zawiera wiele pomiarów
  - `measurements.series_id` → `series.id`
  - Kaskadowe usuwanie: usunięcie serii usuwa wszystkie powiązane pomiary

= Opis kodu aplikacji

== Backend (`/backend`)

=== Pliki kluczowe

==== `main.py` -- Główny plik aplikacji FastAPI

- Konfiguracja aplikacji i CORS
- Rejestracja routerów (auth, series, measurements)
- Endpoint `/api/health` - sprawdzanie stanu aplikacji i połączenia z bazą

==== `database.py` -- Konfiguracja bazy danych

- Połączenie SQLAlchemy z PostgreSQL
- Session management (`get_db()`)

==== `models.py` -- Modele ORM

- `User` - model użytkownika
- `Series` - model serii pomiarowej
- `Measurement` - model pojedynczego pomiaru
- Definicje relacji między tabelami

==== `schemas.py` -- Schematy Pydantic

- Walidacja danych wejściowych/wyjściowych API
- `UserCreate`, `UserResponse` - schematy użytkownika
- `SeriesCreate`, `SeriesUpdate`, `SeriesResponse` - schematy serii
- `MeasurementCreate`, `MeasurementResponse` - schematy pomiarów

==== `auth.py` -- Uwierzytelnianie

- `hash_password()` - hashowanie hasła bcrypt
- `verify_password()` - weryfikacja hasła
- `create_access_token()` - generowanie JWT token
- `get_current_user()` - dekodowanie i walidacja tokenu

==== `dependencies.py` -- Zależności FastAPI

- `get_current_user()` - dependency do autoryzacji
- `get_current_admin_user()` - dependency wymagający uprawnień admina

=== Routery (`/backend/routers`)

- `auth.py` - Endpoint uwierzytelniania
- `series.py` - Zarządzanie seriami
- `measurements.py` - Zarządzanie pomiarami

== Frontend (`/frontend`)

=== Struktura katalogów

==== `/src/main.js` -- Punkt wejścia aplikacji

- Inicjalizacja Vue.js
- Konfiguracja routera i Pinia store

==== `/src/router/index.js` -- Konfiguracja Vue Router

- Definicja tras aplikacji
- Guard nawigacyjny (przekierowanie admina na dashboard)

=== Stores (`/src/stores`)

==== `auth.js` -- Store uwierzytelniania (Pinia)

- Zarządzanie stanem logowania użytkownika
- `login()`, `logout()`, `checkAuth()`
- Przechowywanie JWT tokenu w localStorage

==== `data.js` -- Store danych pomiarowych (Pinia)

- Pobieranie i cache'owanie serii i pomiarów
- `fetchSeries()`, `fetchMeasurements()`
- CRUD operacje: `createSeries()`, `updateSeries()`, `deleteSeries()`
- Filtrowanie danych po zakresie czasu

=== Komponenty (`/src/components`)

==== `Navigation.vue` -- Główna nawigacja

- Menu z linkami (Home, Admin Dashboard)
- Wyświetlanie stanu zalogowania
- Przyciski Login/Logout

==== `SeriesFilter.vue` -- Filtry serii pomiarowych

- Checkboxy do wyboru wyświetlanych serii
- Przyciski "Select All" / "Deselect All"
- Synchronizacja z store'em danych

==== `MeasurementChart.vue` -- Wykres pomiarów

- Integracja z Chart.js (vue-chartjs)
- Wykres liniowy z osią czasu (time-series)
- Przyciski filtrowania zakresu (24h, 7d, 30d, All)
- Interaktywny zoom i pan

==== `MeasurementTable.vue` -- Tabela pomiarów

- Wyświetlanie pomiarów w formie tabelarycznej
- Paginacja (50 rekordów na stronę)
- Kolorowe oznaczenia serii
- Przyciski Edit/Delete (tylko dla admina)

==== `SeriesManagement.vue` -- Zarządzanie seriami (admin)

- Tabela wszystkich serii
- Modal do tworzenia/edycji serii
- Walidacja formularza (zakres min/max, kolor hex)
- Usuwanie serii z potwierdzeniem

=== Widoki (`/src/views`)

==== `HomeView.vue` -- Strona główna (publiczna)

- Przycisk "Print Report"
- SeriesFilter + MeasurementChart + MeasurementTable
- Dostępna bez logowania

==== `DashboardView.vue` -- Panel admina

- SeriesManagement - zarządzanie seriami
- MeasurementManagement - dodawanie/edycja pomiarów
- Dostępny tylko dla zalogowanych adminów

==== `LoginView.vue` -- Strona logowania

- Formularz username + password
- Walidacja i obsługa błędów
- Przekierowanie po udanym logowaniu

==== `RegisterView.vue` -- Strona rejestracji

- Formularz rejestracji (username, email, password)
- Walidacja danych
- Automatyczne logowanie po rejestracji

==== `ProfileView.vue` -- Profil użytkownika

- Wyświetlanie danych użytkownika
- Zmiana hasła i emaila
- Usunięcie konta

=== Konfiguracja

==== `/database/init.sql` -- Inicjalizacja bazy

- Tworzenie tabel (users, series, measurements)
- Tworzenie indeksów dla wydajności

==== `/database/seed_data.sql` -- Dane testowe

- 2 użytkowników (admin, user)
- 3 serie pomiarowe (Temperature, Humidity, Pressure)
- ~500 pomiarów (169 per seria)

= Zrzuty ekranu

== Strona główna - widok publiczny

#figure(
  image("screenshots/home-page.png", width: 100%),
  caption: [Publiczny dostęp do wykresów i danych pomiarowych bez konieczności logowania. Tabela z paginacją pokazująca wszystkie pomiary z kolorowym oznaczeniem serii.]
)

== Interaktywny wykres z filtrami

#figure(
  image("screenshots/chart-filters.png", width: 100%),
  caption: [Wykres Chart.js z możliwością wyboru zakresu czasu (24h, 7d, 30d, All) i filtrowania serii.]
)

== Panel logowania

#figure(
  image("screenshots/login-page.png", width: 100%),
  caption: [Formularz logowania z walidacją i obsługą błędów.]
)

== Panel admina - zarządzanie seriami

#figure(
  image("screenshots/admin-series.png", width: 100%),
  caption: [Tworzenie, edycja i usuwanie serii pomiarowych (tylko dla admina).]
)

== Tworzenie/edycja serii

#figure(
  image("screenshots/create-series.png", width: 100%),
  caption: [Formularz z walidacją do definiowania nowej serii (nazwa, zakres, kolor, jednostka).]
)

== Tworzenie/edycja pomiarów

#figure(
  image("screenshots/create-measurements.png", width: 100%),
  caption: [Panel zarządzania pomiarami w interfejsie admina.]
)

== Profil użytkownika

#figure(
  image("screenshots/user-profile.png", width: 100%),
  caption: [Wyświetlanie informacji o użytkowniku, zmiana hasła i emaila.]
)

== Widok do druku

#figure(
  image("screenshots/print-view-1.png", width: 100%),
  caption: [Widok do druku - część 1]
)

#figure(
  image("screenshots/print-view-2.png", width: 100%),
  caption: [Widok do druku - część 2]
)

#figure(
  image("screenshots/print-view-3.png", width: 100%),
  caption: [Widok do druku - część 3. Przygotowany do druku raport z pomiarami (ukryte elementy UI, wszystkie dane widoczne).]
)

== Dokumentacja API (Swagger)

#figure(
  image("screenshots/swagger-api.png", width: 100%),
  caption: [Interaktywna dokumentacja API z możliwością testowania endpointów.]
)
