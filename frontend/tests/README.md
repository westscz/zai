# Visual Regression Testing

## Pierwsze uruchomienie - tworzenie baseline'ów

Przed pierwszym uruchomieniem testów upewnij się, że aplikacja działa w Docker Compose:

```bash
# W katalogu głównym projektu
make up

# Sprawdź czy wszystko działa
make health
```

Aplikacja powinna być dostępna na http://localhost:3000

Teraz utwórz baseline screenshots:

```bash
npm run test:visual:update
```

To stworzy folder `tests/ui-visual.spec.js-snapshots/` z referencyjnymi screenshotami.

## Uruchamianie testów

Po zmianach w kodzie, sprawdź czy nie zepsuło się UI:

```bash
npm run test:visual
```

Jeśli testy zawiodą:
- Otwórz raport: `npm run test:visual:report`
- Zobacz różnice między baseline a aktualnym stanem
- Jeśli zmiany są zamierzone, zaktualizuj baseline: `npm run test:visual:update`

## Dostępne komendy

- `npm run test:visual` - Uruchom testy wizualne
- `npm run test:visual:update` - Utwórz/zaktualizuj baseline screenshots
- `npm run test:visual:ui` - Uruchom testy w interaktywnym UI mode
- `npm run test:visual:report` - Otwórz raport z ostatniego uruchomienia

## Co testujemy

Testy sprawdzają widok publiczny (View Data):
- ✅ Pełny widok dashboardu z danymi
- ✅ Komponent MeasurementTable z danymi
- ✅ Komponent MeasurementChart (wykres)
- ✅ Filtry serii pomiarowych
- ✅ Tabela z widocznymi pomiarami
- ✅ Widok dla różnych rozdzielczości (1920x1080)

## Wskazówki

1. **Zawsze commituj baseline screenshots** do repozytorium (`tests/ui-visual.spec.js-snapshots/`)
2. **Przed commitowaniem zmian UI** uruchom `npm run test:visual`
3. **Jeśli zmieniasz UI celowo** - zaktualizuj baseline'y (`npm run test:visual:update`)
4. **Testy wymagają działającej aplikacji** - upewnij się że `make up` jest uruchomione
5. **Aplikacja musi mieć dane testowe** - baseline'y pokazują konkretne dane z bazy
