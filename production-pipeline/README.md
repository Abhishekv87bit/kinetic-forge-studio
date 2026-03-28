# Production Pipeline

Project-agnostic templates and tools for shipping AI-enabled apps to production.

## Structure

```
production-pipeline/
  templates/        # Dockerfile, CI/CD, docker-compose templates
  tools/            # Scripts that apply templates to any project
  docs/             # Learning resources, architecture notes
  examples/         # Example configs for reference
```

## Usage

```bash
# Apply pipeline to any project
py -3.12 tools/apply_pipeline.py <project-path> --stack fastapi-vite

# Verify pipeline is working
py -3.12 tools/verify_pipeline.py <project-path>
```

## Bible

Gap tracking lives in: `C:/Users/abhis/.claude/projects/d--Claude-local/memory/projects/production-pipeline-bible.yaml`

Interactive plan: `D:/Claude local/ai-agent-mastery-plan/index.html`
