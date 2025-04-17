<h1 align="center">VorteX Meet Me</h1>
<p align="center"><a href="#project-description">Project Description</a> - <a href="#key-features">Key Features</a> - <a href="#technology-stack">Tech Stack</a> - <a href="#requirements">Requirements</a></p>

## Project Description

This is my first script for FiveM, called "vx\_meetme" — a project I created based on ideas and needs I personally encountered while playing and developing for the platform.

The goal of this script is to improve player interactions by offering a simple and structured way for players to meet, recognize, and manage relationships in-game.

## Key Features

*   **Interaction Requests**: Players can send meeting requests to others, which can be accepted or rejected.
*   **Contact Management**: Players can keep a list of known individuals and manage their contacts.
*   **Customizable Settings**: Interaction messages, automatic replies, and interaction ranges can be adjusted.
*   **Localization Support**: Supports multiple languages, including English and Spanish.
*   **QBCore Integration**: Uses QBCore for player data and server callbacks.
*   **Database Integration**: Contacts and settings are saved for persistence.

## Tech Stack

*   **Lua** — Main scripting language for the client and server logic.
*   **FiveM** — Multiplayer modification framework for GTA V.
*   **QBCore Framework** — Server-side framework for player management, callbacks, and events.
*   **MySQL / MariaDB** — Database for storing contacts and player settings.
*   **Multilingual Support** — Designed for easy localization (English / Spanish).

## Requirements

*   **QBCore** — Main framework used for player data management, events, and server-client communication.
*   **Ox Target** — Targeting system that allows creating interaction zones for players in the world.
*   **Ox Lib** — Utility library that simplifies client-server communication, UI elements, notifications, and more.