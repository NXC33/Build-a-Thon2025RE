# MeetMatch - AI Agent Instructions

## Project Overview
MeetMatch is a meeting scheduling system for educational institutions, specifically designed to facilitate student-teacher meetings. The application allows students to request meetings with teachers based on availability and subjects.

## Architecture

### Core Components
1. Backend Classes (`Backend/`)
   - `Account`: Base class for users with meetings and requests management
   - `Student` and `Teacher`: Specialized account types
   - `Meeting`: Meeting management with statuses (Pending/Confirmed)

2. Data Storage (`data/`)
   - `accounts/`: User account data
   - `availability/`: User availability schedules (JSON format)
   - `help/`: Support ticket storage

3. Helper Utilities (`helpers/`)
   - `account_utils.py`: Account data management
   - `storage.py`: Availability data persistence

4. Views (`views/`)
   - Bottle template files (.tpl) for web interface
   - Consistent styling using CSS variables for theming

## Key Patterns

### Meeting Management
- Meetings are tracked with statuses: "Pending", "Confirmed", "Cancelled"
- Time ranges use `start` and `end` in "HH:MM" format
- Week view uses Monday-Sunday with configurable hours (default 8:00-20:00)

### Data Models
```python
# Account proficiency structure
proficiency = {
    "Math": ("Pre-Calculus", "Calculus 1"),
    "Science": ("Chemistry", "AP Physics C")
}

# Availability JSON format
{
    "Mon": [{"start": "08:00", "end": "19:00"}],
    "Tue": [{"start": "08:00", "end": "19:00"}]
}
```

### Development Flow
1. Main application entry: `test.py` (contains routes and server setup)
2. Constants in `home_utils.py` control calendar view settings
3. Helper functions for data storage in `helpers/` directory

## Common Tasks

### Adding New Features
1. Backend changes:
   - Update relevant classes in `Backend/`
   - Add storage helpers if needed in `helpers/`
2. Frontend changes:
   - Add/modify template in `views/`
   - Use consistent styling (see `shell_top.tpl` for CSS variables)

### Testing
- Test user flows through web interface locally (port 8080)
- Validate data persistence in `data/` directory
- Check meeting handling through Student/Teacher interactions

## Integration Points
- Template inheritance: All pages extend `shell_top.tpl` and `shell_bottom.tpl`
- Client-side: JavaScript handles dynamic UI in availability and meeting requests
- Data flow: JSON files in `data/` directory for persistence

## Special Considerations
1. Time handling:
   - Use `datetime` for dates
   - Time in minutes since midnight for internal calculations
   - "HH:MM" format for user display

2. User roles:
   - Students: Include grade level and current courses
   - Teachers: Include title and teaching subjects

3. Theme support:
   - Dark/Light themes via CSS variables
   - Theme persisted in cookies