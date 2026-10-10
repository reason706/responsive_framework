# Recipes

Complete, runnable examples in `apps/gallery/lib/recipes.dart`. Each is
widget-tested and demonstrates public-API-only composition.

| Recipe | File | What it proves |
|---|---|---|
| Registration form | `RegistrationFormRecipe` | Validate/save/reset, error summary, state retained across theme/width changes |
| Settings form | `SettingsFormRecipe` | Switches, selects, sliders with live preview |
| Event scheduling | `EventSchedulingRecipe` | Date/time pickers → attendee multi-select → confirm dialog with busy lock → toast result |
| Dashboard | `DashboardRecipe` | Bottom nav (phone) → rail (medium) → sidebar (desktop), one selection model |
| Master-detail | `MasterDetailRecipe` | List + detail, selection survives responsive transitions |
| Data page | `DataPageRecipe` | Searchable/paginated table, row actions reachable on phones |

Expected behavior for each is asserted in `apps/gallery/test/recipes_test.dart`.

The [pilot apps](pilots/friction-log.md) rebuild three of these as
standalone applications to validate the framework outside the gallery.
