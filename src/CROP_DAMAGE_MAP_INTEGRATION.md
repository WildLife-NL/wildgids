# Crop Damage Report Map Integration - Implementation Guide

## Overview
This document outlines the implementation of map-based area selection for crop damage reports with conditional form fields based on damage type.

## Requirements
1. **Map-based Area Selection**: Draw affected area using polygon drawing tool
2. **GPS Recording**: Record affected area via live GPS tracking
3. **Conditional Fields**:
   - **Livestock damage**: Requires "amount" field (e.g., "5 goats")
   - **Crop/Grain damage**: Requires "area" field (shown on map)
4. **Area Calculation**: Auto-calculate hectares from drawn polygon

## Architecture

### Models Created
1. **PolygonArea** (`lib/models/beta_models/polygon_area_model.dart`)
   - Stores polygon points (lat/lng coordinates)
   - Calculates area in square meters and hectares
   - Supports both 'polygon' and 'gps_recording' types

2. **BelongingDamageReport** (updated)
   - Added `polygonArea`: PolygonArea?
   - Added `damageCategory`: String? ('livestock' or 'crops')

### Screens Created
1. **AreaSelectionMap** (`lib/screens/belonging/area_selection_map.dart`)
   - Interactive map for polygon drawing
   - GPS recording functionality
   - Point visualization with numbering
   - Area calculation display
   - Undo/Clear/Confirm actions

## Implementation Steps

### Step 1: Update BelongingDamageReportProvider
Add damage type and polygon area state management:

```dart
class BelongingDamageReportProvider extends ChangeNotifier {
  String damageCategory = 'crops'; // or 'livestock'
  PolygonArea? selectedArea;
  int? livestockAmount;
  
  void setDamageCategory(String category) {
    damageCategory = category;
    notifyListeners();
  }
  
  void setSelectedArea(PolygonArea area) {
    selectedArea = area;
    // Auto-set impactedArea based on polygon calculation
    impactedArea = area.getAreaInHectares();
    notifyListeners();
  }
  
  void setLivestockAmount(int amount) {
    livestockAmount = amount;
    notifyListeners();
  }
}
```

### Step 2: Create Conditional Form Widget
Create a new screen/form section that shows:

**For Livestock Damage:**
- Damage category selector (dropdown or radio)
- Animal type selector
- Amount field (number input)
- Date/location selection

**For Crop/Grain Damage:**
- Damage category selector
- Crop type selector
- Map area selection button (opens AreaSelectionMap)
- Display selected area in hectares
- Date/location selection

### Step 3: Update Validation Logic
```dart
bool validateCropDamageReport(BelongingDamageReportProvider provider) {
  if (provider.damageCategory == 'crops') {
    // Require polygon area for crops
    if (provider.selectedArea == null || provider.selectedArea!.points.length < 3) {
      showError('Selecteer een gebied op de kaart');
      return false;
    }
    // Validate area is set
    if (provider.impactedArea <= 0) {
      showError('Gebied moet groter zijn dan 0');
      return false;
    }
  } else if (provider.damageCategory == 'livestock') {
    // Require livestock amount
    if (provider.livestockAmount == null || provider.livestockAmount! <= 0) {
      showError('Voer het aantal dieren in');
      return false;
    }
  }
  return true;
}
```

### Step 4: Update Report Submission
When submitting, use appropriate impactedAreaType:

```dart
Map<String, dynamic> createDamageReportPayload() {
  if (damageCategory == 'crops') {
    return {
      'impactType': 'hectare', // or 'square-meters'
      'impactValue': selectedArea!.getAreaInHectares(),
      'polygonArea': selectedArea!.toJson(),
    };
  } else {
    return {
      'impactType': 'units', // animals
      'impactValue': livestockAmount,
      'damageCategory': 'livestock',
    };
  }
}
```

## UI Flow Diagram

```
BelongingDamagesScreen
  ↓
Choose Damage Category
  ├─ Livestock
  │  ├─ Select Animal Type
  │  ├─ Enter Amount (5 goats)
  │  └─ Select Location/Date
  │
  └─ Crops/Grain
     ├─ Select Crop Type
     ├─ Open Map for Area Selection
     │  ├─ Option 1: Draw Polygon
     │  │  └─ Click points on map → Calculate area
     │  └─ Option 2: GPS Recording
     │     └─ Auto-record path → Calculate area
     ├─ Display: "Area: 2.5 hectares"
     └─ Select Location/Date
  ↓
Submit Report
```

## Files Modified/Created

**Created:**
- `lib/models/beta_models/polygon_area_model.dart`
- `lib/screens/belonging/area_selection_map.dart`

**Modified:**
- `lib/models/beta_models/belonging_damage_report_model.dart` (added fields)
- `lib/screens/belonging/belonging_damages_screen.dart` (needs updates)
- `lib/providers/belonging_damage_report_provider.dart` (needs updates)

## Key Features

### PolygonArea Model
- Calculates area using Shoelace formula
- Supports both polygon drawing and GPS recording
- Converts to hectares/square meters
- Finds center point of polygon

### AreaSelectionMap Widget
- Tap-to-draw polygon interface
- GPS streaming integration
- Point numbering and visualization
- Real-time area calculation
- Undo/Clear/Confirm actions
- Visual feedback for drawn areas

### Conditional Validation
- Crops require: selectedArea with ≥3 points
- Livestock require: amount > 0
- Display appropriate error messages

## API Integration

When submitting:
1. Calculate area from polygon or GPS track
2. Include `polygonArea` in payload (optional)
3. Set `impactType` based on damage type:
   - Crops: "hectare" or "square-meters"
   - Livestock: "units"
4. Set `impactValue` to calculated amount

## Testing Scenarios

1. **Draw Polygon**
   - Click 3+ points on map
   - Verify area calculation
   - Undo last point
   - Confirm area selection

2. **GPS Recording**
   - Start GPS recording
   - Move 5+ meters
   - Stop GPS recording
   - Verify area calculation

3. **Form Validation**
   - Livestock: Missing amount → Error
   - Crops: No area selected → Error
   - Both: Valid submission → Success

4. **Edge Cases**
   - Draw polygon with <3 points
   - Cancel area selection
   - Clear drawn area and restart
   - GPS disabled device

## Future Enhancements

- [ ] Multiple polygon areas per report
- [ ] Import shapefile/GeoJSON boundaries
- [ ] Satellite imagery background toggle
- [ ] Area comparison with historical data
- [ ] Damage severity mapping
- [ ] Photo evidence attachment to area
