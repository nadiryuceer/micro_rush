# NMMI Project Structure Reorganization

## Recommended Folder Structure

```
nmmi/
├── scenes/                    # Main scene files
│   ├── main.tscn             # Main game scene
│   ├── menus/                # Menu scenes
│   │   ├── main_menu.tscn
│   │   ├── track_select.tscn
│   │   ├── vehicle_select.tscn
│   │   └── results.tscn
│   ├── game/                 # Game-related scenes
│   │   ├── race_scene.tscn   # Main racing scene
│   │   └── hud.tscn          # HUD overlay
│   └── ui/                   # UI component scenes
│       ├── countdown.tscn
│       ├── position_display.tscn
│       └── minimap.tscn
│
├── scripts/                   # All GDScript files
│   ├── core/                 # Core game systems
│   │   ├── game_manager.gd
│   │   ├── race_manager.gd
│   │   └── save_manager.gd
│   ├── vehicles/             # Vehicle-related scripts
│   │   ├── vehicle_controller.gd
│   │   ├── ai_controller.gd
│   │   ├── vehicle_factory.gd
│   │   └── vehicle_data.gd
│   ├── camera/               # Camera systems
│   │   ├── camera_manager.gd
│   │   └── pack_camera.gd
│   ├── ui/                   # UI scripts
│   │   ├── hud_manager.gd
│   │   ├── menu_manager.gd
│   │   └── minimap.gd
│   ├── game_modes/           # Race mode implementations
│   │   ├── elimination_mode.gd
│   │   ├── time_trial_mode.gd
│   │   └── lap_race_mode.gd
│   ├── power_ups/            # Power-up system
│   │   ├── power_up_manager.gd
│   │   ├── power_up.gd
│   │   └── power_up_types/
│   ├── audio/                # Audio system
│   │   ├── audio_manager.gd
│   │   └── sound_effects.gd
│   ├── multiplayer/          # Multiplayer systems
│   │   ├── multiplayer_manager.gd
│   │   └── network_sync.gd
│   └── utils/                # Utility scripts
│       ├── math_utils.gd
│       ├── file_utils.gd
│       └── debug_utils.gd
│
├── data/                     # Game data and configuration
│   ├── vehicles/             # Vehicle data files
│   │   ├── vehicle_database.json
│   │   └── individual_vehicles/
│   │       ├── sports_car.json
│   │       ├── jeep.json
│   │       ├── muscle_car.json
│   │       └── ...
│   ├── tracks/               # Track data
│   │   ├── track_database.json
│   │   └── individual_tracks/
│   │       ├── kitchen.json
│   │       ├── bathroom.json
│   │       └── ...
│   ├── game_config/          # Game configuration
│   │   ├── race_settings.json
│   │   ├── difficulty_settings.json
│   │   └── control_settings.json
│   └── player_data/          # Player progress (generated)
│       ├── save_data.json
│       └── achievements.json
│
├── assets/                   # All art and media assets
│   ├── models/               # 3D models
│   │   ├── vehicles/
│   │   │   ├── sports_cars/
│   │   │   ├── jeeps/
│   │   │   ├── muscle_cars/
│   │   │   ├── trucks/
│   │   │   └── common/       # Shared parts (wheels, etc.)
│   │   ├── tracks/
│   │   │   ├── kitchen/
│   │   │   ├── bathroom/
│   │   │   ├── garage/
│   │   │   ├── garden/
│   │   │   └── attic/
│   │   ├── power_ups/
│   │   └── ui/
│   ├── textures/             # 2D textures
│   │   ├── vehicles/
│   │   ├── tracks/
│   │   ├── ui/
│   │   └── effects/
│   ├── materials/            # Godot materials
│   │   ├── vehicles/
│   │   ├── tracks/
│   │   └── ui/
│   ├── audio/                # Audio files
│   │   ├── sfx/              # Sound effects
│   │   │   ├── engines/
│   │   │   ├── collisions/
│   │   │   ├── power_ups/
│   │   │   └── ui/
│   │   └── music/            # Background music
│   │       ├── menu/
│   │       ├── racing/
│   │       └── results/
│   └── fonts/                # Font files
│       └── ui_fonts/
│
├── resources/                # Godot resource files
│   ├── vehicles/             # Vehicle resources
│   │   ├── vehicle_data.tres
│   │   └── vehicle_stats.tres
│   ├── tracks/               # Track resources
│   │   └── track_data.tres
│   ├── power_ups/            # Power-up resources
│   │   └── power_up_data.tres
│   └── ui/                   # UI resources
│       └── theme.tres
│
├── templates/                # Template scenes and scripts
│   ├── vehicles/
│   │   ├── vehicle_base.tscn
│   │   └── ai_vehicle_base.tscn
│   ├── tracks/
│   │   ├── track_base.tscn
│   │   └── checkpoint.tscn
│   └── ui/
│       └── button_template.tscn
│
├── tools/                    # Development and utility tools
│   ├── asset_importer.gd     # Asset processing tool
│   ├── vehicle_validator.gd  # Vehicle data validator
│   ├── track_builder.gd      # Track creation tool
│   └── debug_menu.gd        # In-game debug tools
│
├── tests/                    # Test scenes and scripts
│   ├── unit_tests/
│   │   ├── test_vehicle_controller.gd
│   │   ├── test_race_manager.gd
│   │   └── test_ai_controller.gd
│   ├── integration_tests/
│   │   ├── test_full_race.gd
│   │   └── test_multiplayer.gd
│   └── performance_tests/
│       └── test_many_vehicles.gd
│
└── docs/                     # Documentation
    ├── api/                  # API documentation
    ├── tutorials/            # Development tutorials
    ├── asset_guidelines.md   # Asset creation guidelines
    └── coding_standards.md  # Coding standards
```

## Migration Plan

### Phase 1: Core Structure
1. Create new folder structure
2. Move existing files to appropriate locations
3. Update script paths and scene references
4. Test basic functionality

### Phase 2: Data Organization
1. Create data-driven vehicle system files
2. Move asset files to organized structure
3. Create resource templates
4. Update import paths

### Phase 3: Development Tools
1. Set up development tools
2. Create test framework
3. Add documentation
4. Validate workflow

## Benefits of This Structure

### Scalability
- **Clear separation** of concerns
- **Easy to add** new vehicles, tracks, features
- **Modular design** supports team development
- **Logical grouping** for efficient navigation

### Maintainability
- **Consistent naming** conventions
- **Standardized locations** for file types
- **Clear dependencies** between modules
- **Easy refactoring** with organized structure

### Development Workflow
- **Template-based** asset creation
- **Data-driven** configuration
- **Automated testing** framework
- **Tool support** for common tasks

### Performance
- **Optimized asset loading** with organized folders
- **Efficient resource management**
- **Clear separation** of runtime vs. editor resources
- **Scalable asset pipeline**
