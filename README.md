[![CI](https://github.com/Abhishekv87bit/kinetic-forge-studio/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhishekv87bit/kinetic-forge-studio/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-18-61DAFB)](https://react.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688)](https://fastapi.tiangolo.com/)

# Kinetic Forge Studio

AI-powered kinetic sculpture design studio. Design, simulate, and export mechanical art with Claude, Gemini, CadQuery, and Three.js.

```mermaid
graph LR
    A[React + Three.js<br/>Frontend] -->|REST API| B[FastAPI<br/>Backend]
    B --> C[CadQuery<br/>Engine]
    B --> D[Claude API<br/>AI Chat]
    B --> E[Gemini API<br/>Photo Analysis]
    C --> F[STEP / STL<br/>Export]
    D --> C
    style A fill:#61DAFB,color:#000
    style B fill:#009688,color:#fff
    style C fill:#FF6B6B,color:#fff
    style D fill:#7C3AED,color:#fff
    style E fill:#4285F4,color:#fff
    style F fill:#96CEB4,color:#000
```

## What This Does

Kinetic Forge Studio is a full-stack web application that lets you design kinetic sculptures through natural language conversation with AI. Describe what you want, and the AI generates parametric 3D models using CadQuery, renders them in a Three.js viewport, and exports fabrication-ready STEP files.

**Key features:**
- **AI Chat Interface** — Describe sculptures in plain English, get parametric 3D models
- **Dual AI Engines** — Claude for design reasoning, Gemini for photo-to-model analysis
- **Real-time 3D Viewport** — Three.js/React Three Fiber with orbit controls
- **CadQuery Engine** — Python-based parametric CAD with VLAD validation
- **Export Pipeline** — STEP, STL, and OBJ export for fabrication
- **Component Library** — Reusable parametric parts (gears, lattices, mechanisms)

## Built With

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, TypeScript, Three.js / R3F, Vite, Tailwind CSS |
| Backend | FastAPI, Python 3.12, Pydantic v2 |
| AI | Claude API (Anthropic), Gemini API (Google) |
| CAD | CadQuery 2.x, VLAD Validator |
| Database | ChromaDB (vector search), SQLite |
| Infrastructure | Docker, GitHub Actions |

## Getting Started

### Docker (Recommended)

```bash
cp .env.example .env
# Add your API keys to .env
docker compose up
```

### Manual Setup

```bash
# Backend
cd backend
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend
cd frontend
npm install
npm run dev
```

## Project Structure

```
├── backend/
│   ├── app/
│   │   ├── engines/       # CadQuery CAD engine
│   │   ├── orchestrator/  # AI chat agent
│   │   ├── importers/     # Photo analysis (Gemini)
│   │   ├── routes/        # FastAPI endpoints
│   │   ├── db/            # Database + component library
│   │   └── middleware/     # Rate limiting, guardrails, observability
│   └── tests/
├── frontend/
│   ├── src/
│   │   ├── components/    # React components
│   │   └── ...
│   └── package.json
├── docker-compose.yml
└── .env.example
```

## License

[MIT](LICENSE)
