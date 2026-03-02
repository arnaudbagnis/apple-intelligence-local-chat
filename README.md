# LocalChat

> [!WARNING]
> **Experimental Project**: This is an experimental, local-first chat application currently in active development.

LocalChat is an innovative, local-first chat application for macOS built with SwiftUI and SwiftData. It integrates native on-device AI capabilities using Apple's `FoundationModels` framework, ensuring privacy and fast responses without relying on external cloud APIs.

## Key Features

- **On-Device AI**: Leverages Apple's `FoundationModels` for intelligent, local-first conversations.
- **Advanced Agent Orchestration**: Features a sophisticated `AgentOrchestrator` that manages complex tasks through a multi-step reasoning pipeline.
- **Hidden Reasoning Pipeline**: 
  - **Draft**: Initial response generation.
  - **Critique**: Self-evaluation and refinement of the draft.
  - **Final Answer**: Polished output presented to the user.
- **Tool Calling & Sandbox**: Equip the agent with tools (like terminal execution) strictly governed by a secure sandbox environment (`AgentSecurity`).
- **Human-in-the-Loop (HITL)**: Crucial actions proposed by the agent require explicit user confirmation before execution, ensuring safety and control.
- **Persistent Storage**: Utilizes `SwiftData` for fast and reliable storage of conversations and messages.
- **Modern UI**: Built entirely with SwiftUI, offering a clean, responsive, and native macOS experience.

## Architecture

The application is structured into the following main components:
- **UI / Views**: SwiftUI views providing the interactive conversational interface.
- **ViewModels**: Manage view states and bridge the UI with underlying models and services.
- **Models**: `SwiftData` models defining the data schema (`Conversation`, `Message`).
- **Agents**: Core intelligence layer containing:
  - `AgentOrchestrator`: Orchestrates the planning, reasoning, and tool execution phases.
  - `AgentSecurity`: Enforces security policies (e.g., blocking forbidden commands).
  - `InternalPrompts`: Manages the prompts used during different phases of reasoning.
- **Services**: Interfaces with underlying APIs, including the `FoundationModelsClient` for AI interactions.

## Deployment & CI/CD

The project includes a GitHub Actions workflow (`deploy.yml`) that automates the building and packaging of the application into a `.dmg` file upon tagging a new release.

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for development)

## Getting Started

1. Clone the repository.
2. Open `LocalChat.xcodeproj` in Xcode.
3. Build and run the `LocalChat` scheme on your local Mac.
