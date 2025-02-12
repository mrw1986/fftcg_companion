# Current Task

## Objective

Improve card sorting functionality and fix related issues

## Context

The card sorting system needed improvements to handle:

1. Crystal cards appearing in the correct order
2. Non-card items visibility in different sort modes
3. Secondary sorting by number for cost and power sorts

## Changes Made

### Card Repository

- Updated sorting logic to always place crystal cards at the end of the list
- Modified filtering logic to hide non-card items for number, cost, and power sorts
- Added secondary number sorting for cost and power sorts
- Improved crystal card handling for all sort types (name, number, cost, power)

### Code Organization

- Moved SortBottomSheet to dedicated widget file
- Updated cards_page.dart to use new SortBottomSheet widget
- Improved state management with Riverpod

## Current Status

- [x] Fixed crystal card sorting to always appear at end
- [x] Implemented proper non-card item filtering
- [x] Added secondary number sorting
- [x] Refactored code organization
- [x] Updated documentation
- [x] Improved sorting consistency across all sort types

## Next Steps

1. Monitor sorting performance with large datasets
2. Consider adding additional sorting options if needed
3. Add unit tests for sorting logic

## Related Tasks from Roadmap

- [x] Sort by name, number, cost, power
- [x] Handle crystal cards and sealed products properly
- [x] Advanced filtering system
