# Tracker Add-on Enhancements: Library Pagination & User List Sync Plan

> **Status**: Draft / Planned for Next Session  
> **Target Repositories**: `AnymeX` (Engine) & `AnymeX-Addon-Services` (Manifests & Schema)  
> **Note**: Do not commit/push until reviewed and approved.

---

## 1. Problem Statements & Motivations

### Problem A: Library Truncation & Lack of Pagination
Currently, when AnymeX syncs a user's library from a Tracker Add-on (e.g., Kitsu or Shikimori via `AddonService.fetchLibrary()`), it performs a **single HTTP request** using the URL configured in the manifest:
- **Kitsu** was configured with `/users/{userId}/library-entries?filter[kind]={type}&include={type}&page[limit]=50`. Only the first 50 items are returned; if a user has 150 items, the remaining 100 are missing.
- **Shikimori** was configured without an explicit limit, defaulting to 50 items.
- `AddonService.fetchLibrary()` executes a single `_client.get()` and does not follow pagination links (`links.next`) or page counters.

### Problem B: Cannot Add Items to User List / Silent Sync Failure
When a user opens an anime/manga details screen and sets its status (e.g., "Add to List" / "Watching"), the following failure occurs:
1. **Missing `create_entry` Endpoint**:
   - Services like Kitsu and Shikimori require `POST` to create a new library entry, and `PATCH` to update an existing one.
   - The current Tracker Add-on specification only defines `update_entry`. There is no `create_entry` endpoint in the schema, manifest, or engine.
2. **Media ID vs. Library Entry ID Mismatch**:
   - `MediaDetailsController.updateListEntry`, `PlayerController`, and `ReaderController` all pass `params.listId = media.id` (Media ID, e.g., Kitsu Anime ID `1234`).
   - However, `update_entry` expects `{entryId}` (the user's library record ID, e.g., `987654` on Kitsu or `55555` on Shikimori).
   - `AddonService` directly replaces `{entryId}` with `params.listId` without checking if the media is already in `animeList`/`mangaList` to retrieve its `mediaListId`.
3. **Silent Failure & Reverting on Refresh**:
   - In `AddonService.updateListEntry()`, non-2xx HTTP responses (404 Not Found / 422 Unprocessable) are silently ignored and do not throw.
   - The UI optimistically sets `mediaStatus.value = status` and displays *"List entry updated successfully!"*.
   - When the user refreshes or reopens the page, `fetchLibrary()` runs. Because nothing was ever saved on the remote site, the UI resets back to "not added" and stats revert.

---

## 2. API Analysis & Capabilities

### A. Kitsu API (`https://kitsu.io/api/edge`)

#### 1. Library Fetching & Pagination
- **JSON:API Compound Document**: Returns `data`, `included`, and `links`.
- **Page Size Limits**:
  - Default: 10 items.
  - Maximum allowed for `library-entries`: **500 items** (`page[limit]=500`).
  - Requesting > 500 returns HTTP 400.
- **Pagination**: If `links.next` is present and non-null, request next page until `links.next == null`.

#### 2. Creating & Updating Library Entries
- **Create Entry (`POST /library-entries`)**:
  - Headers: `Accept: application/vnd.api+json`, `Content-Type: application/vnd.api+json`
  - Body:
    ```json
    {
      "data": {
        "type": "libraryEntries",
        "attributes": {
          "status": "{status}",
          "progress": {progress}
        },
        "relationships": {
          "{type}": {
            "data": {
              "type": "{type}",
              "id": "{mediaId}"
            }
          },
          "user": {
            "data": {
              "type": "users",
              "id": "{userId}"
            }
          }
        }
      }
    }
    ```
- **Update Entry (`PATCH /library-entries/{entryId}`)**:
  - Headers: `Content-Type: application/vnd.api+json`
  - Body:
    ```json
    {
      "data": {
        "id": "{entryId}",
        "type": "libraryEntries",
        "attributes": {
          "status": "{status}",
          "progress": {progress},
          "ratingTwenty": "{scoreTwenty}"
        }
      }
    }
    ```
- **Delete Entry (`DELETE /library-entries/{entryId}`)**

---

### B. Shikimori API (`https://shikimori.one/api/v2`)

#### 1. Library Fetching & Pagination
- Endpoint: `/v2/user_rates?user_id={userId}&target_type={targetType}`
- Default: 50 items.
- Maximum allowed `limit`: **5,000 items** (`&limit=5000`), allowing retrieval of the full library in a single request.

#### 2. Creating & Updating Library Entries
- **Create Entry (`POST /v2/user_rates`)**:
  - Headers: `Content-Type: application/json`, `User-Agent: AnymeX-Client`
  - Body:
    ```json
    {
      "user_rate": {
        "user_id": "{userId}",
        "target_id": "{mediaId}",
        "target_type": "{targetType}",
        "status": "{status}",
        "episodes": "{progress}",
        "score": "{score}"
      }
    }
    ```
- **Update Entry (`PATCH /v2/user_rates/{entryId}`)**:
  - Body:
    ```json
    {
      "user_rate": {
        "status": "{status}",
        "episodes": "{progress}",
        "score": "{score}"
      }
    }
    ```
- **Delete Entry (`DELETE /v2/user_rates/{entryId}`)**

---

## 3. Architecture & Implementation Plan

### Part 1: Engine Updates (`AnymeX`)

#### 1. `lib/controllers/tracker_addon/addon_manifest.dart`
- Add `createEntry` to `EndpointsConfig`:
  ```dart
  class EndpointsConfig {
    final List<HomeSectionConfig> homeSections;
    final EndpointConfig? search;
    final EndpointConfig? details;
    final EndpointConfig? userProfile;
    final EndpointConfig? userLibrary;
    final EndpointConfig? createEntry;
    final EndpointConfig? updateEntry;
    final EndpointConfig? deleteEntry;
    final EndpointConfig? calendar;
    ...
  }
  ```
- Update `EndpointsConfig.fromJson` and `toJson` to serialize/deserialize `create_entry`.

#### 2. `lib/controllers/tracker_addon/addon_service.dart`

##### A. Paginated Library Fetching:
Implement `_fetchPaginatedLibrary(String initialUrl, {required bool isAnime})`:
- Fetch pages sequentially while `nextUrl != null` and `pageCount < maxPages` (safety cap 10).
- For each page, parse `items` and `included`.
- Check `decoded['links']?['next']` (JSON:API standard) for automatic next-page URL.
- Accumulate and map all items to `animeList` / `mangaList`.

##### B. Smart Add / Update Entry Resolution:
Refactor `updateListEntry(UpdateListEntryParams params)`:
1. Identify if item exists in `animeList` or `mangaList`:
   ```dart
   final list = params.isAnime ? animeList : mangaList;
   final existing = list.firstWhereOrNull((m) =>
       m.id == params.listId || m.mediaListId == params.listId);
   ```
2. **If `existing != null` (Already in Library)**:
   - Use `manifest.endpoints.updateEntry`.
   - Substitute `{entryId}` with `existing.mediaListId` (NOT `media.id`).
   - If `updateEntry` uses integer rating/twenty scale (e.g. Kitsu `ratingTwenty`), calculate score appropriately.
   - Send `PATCH` / `PUT`.
3. **If `existing == null` (Adding New Entry)**:
   - Use `manifest.endpoints.createEntry`.
   - Provide placeholders:
     - `{userId}`: `profileData.value.id ?? ''`
     - `{mediaId}`: `params.listId`
     - `{type}`: `params.isAnime ? 'anime' : 'manga'`
     - `{targetType}`: `params.isAnime ? 'Anime' : 'Manga'`
     - `{status}`: remote mapped status
     - `{progress}`: `params.progress.toString()`
     - `{score}`: score string
   - Send `POST`.
4. **Error Handling**:
   - Check `resp.statusCode >= 200 && resp.statusCode < 300`.
   - If not successful, **throw an Exception** with the status code and body so `MediaDetailsController`'s error snackbar displays, rather than silently pretending it succeeded.
   - On success, trigger `await fetchLibrary()`.

##### C. Delete Entry Resolution:
In `deleteListEntry(String listId, {bool isAnime = true})`:
- Check if `listId` is a `mediaId`; if so, lookup `existing.mediaListId` and interpolate `{entryId}`.
- Send `DELETE`.
- On success, trigger `await fetchLibrary()`.

---

### Part 2: Specification & Manifest Updates (`AnymeX-Addon-Services`)

#### 1. `schema.json`
- Add `create_entry` definition under `endpoints.properties`:
  ```json
  "create_entry": {
    "$ref": "#/definitions/endpoint",
    "description": "Endpoint to add a new media to the user's library (supports {userId}, {mediaId}, {type}, {targetType}, {status}, {progress}, {score})."
  }
  ```
- Document available placeholders in `SPECIFICATION.md`.

#### 2. `services/kitsu.json`
- **Library URL**: Update batch limit to `page[limit]=500`:
  ```
  /users/{userId}/library-entries?filter[kind]={type}&include={type}&page[limit]=500
  ```
- **Add `create_entry`**:
  ```json
  "create_entry": {
    "url": "/library-entries",
    "method": "POST",
    "body_template": {
      "data": {
        "type": "libraryEntries",
        "attributes": {
          "status": "{status}",
          "progress": "{progress}"
        },
        "relationships": {
          "{type}": {
            "data": {
              "type": "{type}",
              "id": "{mediaId}"
            }
          },
          "user": {
            "data": {
              "type": "users",
              "id": "{userId}"
            }
          }
        }
      }
    }
  }
  ```
- Bump version to `1.0.3`.

#### 3. `services/shikimori.json`
- **Library URL**: Update batch limit to `&limit=5000`:
  ```
  /v2/user_rates?user_id={userId}&target_type={targetType}&limit=5000
  ```
- **Add `create_entry`**:
  ```json
  "create_entry": {
    "url": "/v2/user_rates",
    "method": "POST",
    "body_template": {
      "user_rate": {
        "user_id": "{userId}",
        "target_id": "{mediaId}",
        "target_type": "{targetType}",
        "status": "{status}",
        "episodes": "{progress}",
        "score": "{score}"
      }
    }
  }
  ```
- Bump version to `1.0.1`.

---

## 4. Verification & Testing Checklist

- [ ] **Pagination Test (Kitsu)**: Log in with an account having > 50 library entries. Verify that all entries (51+) load into the Anime List and count badges.
- [ ] **Pagination Test (Shikimori)**: Verify that large libraries load completely in 1 request via `limit=5000`.
- [ ] **Add to List Test (Kitsu)**: Open an anime not currently in the user's Kitsu library. Change status to "Watching" (progress 1).
  - Verify HTTP 201 Created is sent to `/library-entries`.
  - Verify the entry appears on kitsu.io website.
  - Refresh AnymeX and confirm the item stays in the watchlist.
- [ ] **Update List Test (Kitsu)**: Update an existing item's episode progress or status.
  - Verify PATCH request is sent to `/library-entries/{entryId}` with correct `mediaListId`.
  - Verify updated progress reflects on kitsu.io website.
- [ ] **Add to List Test (Shikimori)**: Add an anime to Shikimori watchlist. Verify it creates the rate on shikimori.one and persists after refresh.
- [ ] **Delete Entry Test**: Remove an item from the list modal; verify it gets deleted on both remote site and AnymeX.
- [ ] **Static Analysis**: Run `flutter analyze --no-fatal-infos` on `AnymeX` to ensure 0 errors.
