# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a mobile gaming platform project for turn-based board games (Dominoes and Chess). The repository contains a comprehensive prompt pack system designed for creating a complete engineering specification and implementation plan.

## Development Environment

- **Python Version**: >=3.12 (as specified in pyproject.toml)
- **Package Manager**: uv (uv.lock present)
- **Project Structure**: Python project with modular prompt-based development workflow

## Key Commands

### Environment Setup


### Development Workflow
The project uses a unique modular prompt-pack approach:
- Use ChatGPT for planning and documentation generation (Modules 0-12)
- Use Claude for implementation and coding (Kickoff + Implementation modules)

## Architecture

### Current State
- Minimal Python application (`main.py`) with basic "Hello World" functionality
- Comprehensive prompt pack system in `vibe_gaming_app_prompt_pack_chat_gpt_claude_modular.md`

### Planned Architecture (from prompt pack)
- **Backend**: Go (Gin or Fiber framework)
- **Mobile App**: Flutter with Riverpod state management
- **Database**: PostgreSQL with Redis for caching
- **Real-time**: WebSockets with JSON protocol
- **Event Bus**: NATS
- **Authentication**: JWT with refresh tokens
- **Deployment**: Kubernetes with Helm charts

### Target Tech Stack
- Go backend with game engine plugins for Dominoes and Chess
- Flutter mobile app with offline/reconnection handling
- Kubernetes deployment with observability (OpenTelemetry, Prometheus, Grafana)
- GDPR-compliant data handling

## Development Process

1. **Planning Phase (ChatGPT)**: Generate specifications using modules 0-12 from the prompt pack
2. **Implementation Phase (Claude)**: Execute coding tasks following the generated specifications
3. **Modular Approach**: Each module produces a single focused output file

## Key Files

- `main.py`: Current minimal Python application entry point
- `pyproject.toml`: Python project configuration
- `vibe_gaming_app_prompt_pack_chat_gpt_claude_modular.md`: Complete development workflow and prompt specifications
- `uv.lock`: Dependency lock file

## Project Scope

The project aims to build a mobile gaming platform supporting:
- Turn-based board games (starting with Dominoes and Chess)
- Real-time multiplayer with matchmaking
- User accounts and game lobbies
- Cross-platform mobile app
- Scalable backend infrastructure
- Modern DevOps practices with Kubernetes deployment

## Implementation Strategy

Follow the modular prompt pack approach where ChatGPT generates planning documents and Claude implements the actual code based on those specifications. The target is a production-ready gaming platform with modern architecture and deployment practices.