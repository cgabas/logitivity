# Huawei Game Service for Godot

This add-on provides Huawei ID game sign-in, achievements, and leaderboard calls through a Godot 4 Android v2 plugin. Non-Android exports continue to run; `HuaweiGameService.is_available()` reports whether the native bridge is present.

## GDScript API

Use the `HuaweiGameService` autoload:

- `sign_in()`; listen to `sign_in_completed(success, player_id)`.
- `unlock_achievement(id)` and `add_achievement_steps(id, steps)`.
- `show_achievements()`.
- `submit_score(leaderboard_id, score)` and `show_leaderboard(leaderboard_id)`.
- Listen to `operation_completed(operation, success, details)` for outcomes/errors.

Achievement IDs are created in AppGallery Connect and must be passed by the game when achievement events are wired up. Set `LEADERBOARD_ID` in `script/huawei_game_service.gd` to show the leaderboard action in the in-game pause menu.

## Android setup

1. In AppGallery Connect, create an Android **Game** app using the exact Android package name you intend to export. Enable Game Service and Account Kit, then add the SHA-256 fingerprint for the signing key used for the build. Set `package/unique_name` in the Android preset to that same package name.
2. Download that app's `agconnect-services.json` and place it in the Android app module. In the custom Android Gradle template, configure Huawei's Maven repository, add the AppGallery Connect Gradle plugin, and apply `com.huawei.agconnect` in the app module. Never commit private signing keys or the downloaded config file.
3. Install JDK 17, Godot's Android build template, and the Android SDK. In the Android export preset, enable **Use Gradle Build**. The project's existing export preset is local/untracked and was left untouched.
4. Build this Android library from this directory with Gradle 8.11.1 (`:plugin:assembleDebug` and `:plugin:assembleRelease`). The resulting AARs are copied under `bin/debug` and `bin/release` and are loaded by the editor export plug-in.
5. Enable the **Huawei Game Service** editor plug-in in Project Settings > Plugins. Export and test on a Huawei device with HMS Core and a signed-in GameCenter account.
6. Create achievements and leaderboards in AppGallery Connect, then call the GDScript methods with their IDs from the relevant game events.

The Game SDK is pinned to `6.13.0.300` because Huawei removed achievement and leaderboard APIs from `6.14.0.300`. The plugin targets the project's Godot 4.7 Android plugin v2 API.



