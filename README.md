# Vue.js + FastAPI + Tailwind CSS Project

Projekt składa się z dwóch części:
- **Backend**: FastAPI (Python)
- **Frontend**: Vue.js 3 + Tailwind CSS v3

## Wymagania

- Docker
- Docker Compose

## Uruchomienie projektu

### Szybki start

Uruchom wszystkie serwisy za pomocą jednej komendy:

```bash
docker-compose up --build
```

### Dostęp do aplikacji

Po uruchomieniu:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Backend Docs**: http://localhost:8000/docs (automatyczna dokumentacja FastAPI)

### Zatrzymanie

```bash
docker-compose down
```

## Struktura projektu

```
.
├── backend/
│   ├── main.py              # Główny plik FastAPI
│   ├── requirements.txt     # Zależności Python
│   └── Dockerfile          # Konfiguracja Docker dla backendu
├── frontend/
│   ├── src/
│   │   ├── App.vue         # Główny komponent Vue
│   │   ├── main.js         # Entry point
│   │   └── style.css       # Tailwind CSS
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── Dockerfile          # Konfiguracja Docker dla frontendu
└── docker-compose.yml      # Orkiestracja serwisów

```

## Rozwój projektu

### Backend

Dodaj nowe endpointy w `backend/main.py`:

```python
@app.get("/api/custom")
async def custom_endpoint():
    return {"data": "your data"}
```

### Frontend

Komponenty Vue znajdują się w `frontend/src/`.
Tailwind CSS jest skonfigurowany i gotowy do użycia.

## Czyszczenie

Aby usunąć wszystkie kontenery i wolumeny:

```bash
docker-compose down -v
```
