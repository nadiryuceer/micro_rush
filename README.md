# Micro Rush

A Godot 4.4 implementation of a Micro Machines V4-inspired racing game with miniature vehicles and chaotic multiplayer action.

## Overview

Micro Rush transforms a car physics demo into a complete top-down racing game featuring:
- **7cm toy vehicles** with realistic physics
- **Dynamic camera system** with orthographic tracking
- **Menu system** with race mode selection
- **Data-driven vehicle system** with JSON configuration
- **Factory pattern architecture** for clean scene management

## World Scale

- **1 Godot unit = 1 meter** (real-world scale)
- **Vehicle dimensions**: 0.07m length, 0.04-0.05m width, 0.02-0.03m height
- **Speed range**: 2.0-4.0 m/s for toy vehicles
- **Track size**: TBD

## Architecture

### Core Systems
- **GameManager**: Main scene controller and menu instantiation
- **GameFactory**: Static factory for creating race components
- **RaceSceneController**: Manages individual race sessions
- **VehicleDatabase**: Loads and manages vehicle configurations

### Menu Flow
```
Main Menu → Race Mode → Map Selection → Race Scene
```

### Data Structure
```
data/
├── vehicles/
│   ├── individual_vehicles/ (JSON configs)
│   └── vehicle_database.json
```

## Controls

- **W/↑**: Accelerate
- **S/↓**: Brake/Reverse  
- **A/←**: Steer Left
- **D/→**: Steer Right
- **Space**: Boost

## Features

### ✅ Implemented
- **Vehicle Physics**: Realistic toy car physics with acceleration, steering, and grip
- **Dynamic Camera**: Orthographic camera that tracks player vehicles
- **Menu System**: Main menu → Race mode → Map selection flow
- **Game Factory**: Stateless factory for creating race scenes
- **Vehicle Database**: JSON-based vehicle configuration system
- **Race Scene Controller**: Manages race state and player tracking

### 🔄 In Progress
- **Complete Track Design**: Kitchen environment with proper layout and boundaries
- **Race Management System**: Race state management and flow control

### 📋 Planned
- AI opponents
- Power-ups and combat mechanics
- Lap counting and position tracking
- Multiple track environments
- UI/HUD system
- Audio system
- Progression/unlock system
- Local multiplayer support (up to 4 players)
- Online multiplayer potential

## Development

Built with Godot 4.4 using Forward Plus rendering. Follows clean architecture principles with:
- Factory pattern for scene creation
- Data-driven vehicle system
- Separation of concerns between game logic and presentation

## Acknowledgments

This project is being developed with assistance from AI coding tools for architecture design and implementation.

### Assets
- **Vehicle Models**: Kenney Car Kit (https://kenney.nl/assets/car-kit)

## License

This project is open source and available under the MIT License. 
	   
	   
