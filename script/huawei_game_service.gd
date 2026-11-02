extends Node

signal sign_in_completed(success: bool, player_id: String)
signal operation_completed(operation: String, success: bool, details: String)

const PLUGIN_SINGLETON := "HuaweiGameService"
const LEADERBOARD_ID := ""
var _native_plugin: Object

func _ready() -> void:
    if OS.has_feature("android") and Engine.has_singleton(PLUGIN_SINGLETON):
        _native_plugin = Engine.get_singleton(PLUGIN_SINGLETON)
        _native_plugin.connect("sign_in_completed", _on_native_sign_in_completed)
        _native_plugin.connect("operation_completed", _on_native_operation_completed)

func is_available() -> bool:
    return _native_plugin != null

func is_signed_in() -> bool:
    if not is_available():
        return false
    return _native_plugin.call("isSignedIn")

func sign_in() -> void:
    if not _require_plugin("sign_in"):
        return
    _native_plugin.call("signIn")

func unlock_achievement(achievement_id: String) -> void:
    if not _require_plugin("unlock_achievement"):
        return
    _native_plugin.call("unlockAchievement", achievement_id)

func add_achievement_steps(achievement_id: String, steps: int = 1) -> void:
    if not _require_plugin("add_achievement_steps"):
        return
    _native_plugin.call("addAchievementSteps", achievement_id, steps)

func show_achievements() -> void:
    if not _require_plugin("show_achievements"):
        return
    _native_plugin.call("showAchievements")

func submit_score(leaderboard_id: String, score: int) -> void:
    if not _require_plugin("submit_score"):
        return
    _native_plugin.call("submitScore", leaderboard_id, score)

func show_default_leaderboard() -> void:
    if LEADERBOARD_ID.is_empty():
        operation_completed.emit("show_leaderboard", false, "Set LEADERBOARD_ID after creating a leaderboard in AppGallery Connect.")
        return
    show_leaderboard(LEADERBOARD_ID)

func show_leaderboard(leaderboard_id: String) -> void:
    if not _require_plugin("show_leaderboard"):
        return
    _native_plugin.call("showLeaderboard", leaderboard_id)

func _require_plugin(operation: String) -> bool:
    if is_available():
        return true
    operation_completed.emit(operation, false, "Huawei Game Service is available only in an Android export with the plugin enabled.")
    return false

func _on_native_sign_in_completed(success: bool, player_id: String) -> void:
    sign_in_completed.emit(success, player_id)

func _on_native_operation_completed(operation: String, success: bool, details: String) -> void:
    operation_completed.emit(operation, success, details)



