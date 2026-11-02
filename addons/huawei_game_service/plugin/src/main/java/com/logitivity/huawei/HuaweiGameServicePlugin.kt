package com.logitivity.huawei

import android.content.Intent
import com.huawei.hms.support.hwid.HuaweiIdAuthManager
import com.huawei.hms.support.hwid.request.HuaweiIdAuthParams
import com.huawei.hms.jos.JosApps
import com.huawei.hms.jos.games.Games
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class HuaweiGameServicePlugin(godot: Godot) : GodotPlugin(godot) {
    private var signedIn = false
    private val signInRequestCode = 48172

    init {
        runOnHostThread {
            activity?.let { JosApps.getJosAppsClient(it).init(null) }
        }
    }

    override fun getPluginName(): String = "HuaweiGameService"
    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("sign_in_completed", Boolean::class.javaObjectType, String::class.java),
        SignalInfo("operation_completed", String::class.java, Boolean::class.javaObjectType, String::class.java)
    )

    @UsedByGodot
    fun isSignedIn(): Boolean = signedIn

    @UsedByGodot
    fun signIn() {
        runOnHostThread {
            val service = HuaweiIdAuthManager.getService(activity, HuaweiIdAuthParams.DEFAULT_AUTH_REQUEST_PARAM_GAME)
            service.silentSignIn()
                .addOnSuccessListener { finishSignIn() }
                .addOnFailureListener {
                    try {
                        activity?.let { it.startActivityForResult(service.signInIntent, signInRequestCode) } ?: emitOperation("sign_in", false, "Godot activity is unavailable.")
                    } catch (error: Exception) {
                        emitOperation("sign_in", false, error.message ?: "Could not open Huawei sign-in.")
                    }
                }
        }
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onMainActivityResult(requestCode, resultCode, data)
        if (requestCode != signInRequestCode) return
        if (data == null) {
            signedIn = false
            emitSignal("sign_in_completed", false, "")
            emitOperation("sign_in", false, "Huawei sign-in was cancelled.")
            return
        }
        HuaweiIdAuthManager.parseAuthResultFromIntent(data)
            .addOnSuccessListener { finishSignIn() }
            .addOnFailureListener { error ->
                signedIn = false
                emitSignal("sign_in_completed", false, "")
                emitOperation("sign_in", false, error.message ?: "Huawei sign-in failed.")
            }
    }

    private fun finishSignIn() {
        signedIn = true
        runOnHostThread {
            Games.getPlayersClient(activity).currentPlayer
                .addOnSuccessListener { player ->
                    emitSignal("sign_in_completed", true, player.playerId ?: "")
                    emitOperation("sign_in", true, player.displayName ?: "Signed in to Huawei Game Service.")
                }
                .addOnFailureListener { error ->
                    signedIn = false
                    emitSignal("sign_in_completed", false, "")
                    emitOperation("sign_in", false, error.message ?: "Could not load Huawei player profile.")
                }
        }
    }

    @UsedByGodot
    fun unlockAchievement(achievementId: String) {
        if (!requireSignIn("unlock_achievement")) return
        runOnHostThread {
            Games.getAchievementsClient(activity).reachWithResult(achievementId)
                .addOnSuccessListener { emitOperation("unlock_achievement", true, achievementId) }
                .addOnFailureListener { emitOperation("unlock_achievement", false, it.message ?: "Achievement request failed.") }
        }
    }

    @UsedByGodot
    fun addAchievementSteps(achievementId: String, steps: Int) {
        if (!requireSignIn("add_achievement_steps")) return
        if (steps <= 0) {
            emitOperation("add_achievement_steps", false, "Steps must be greater than zero.")
            return
        }
        runOnHostThread {
            Games.getAchievementsClient(activity).makeStepsWithResult(achievementId, steps)
                .addOnSuccessListener { emitOperation("add_achievement_steps", it, achievementId) }
                .addOnFailureListener { emitOperation("add_achievement_steps", false, it.message ?: "Achievement progress request failed.") }
        }
    }

    @UsedByGodot
    fun showAchievements() {
        if (!requireSignIn("show_achievements")) return
        runOnHostThread {
            Games.getAchievementsClient(activity).showAchievementListIntent
                .addOnSuccessListener { intent ->
                    if (intent == null) emitOperation("show_achievements", false, "Huawei did not return the achievements screen.")
                    else {
                        activity?.let { it.startActivity(intent) } ?: emitOperation("show_screen", false, "Godot activity is unavailable.")
                        emitOperation("show_achievements", true, "")
                    }
                }
                .addOnFailureListener { emitOperation("show_achievements", false, it.message ?: "Could not open achievements.") }
        }
    }

    @UsedByGodot
    fun submitScore(leaderboardId: String, score: Long) {
        if (!requireSignIn("submit_score")) return
        if (leaderboardId.isBlank()) {
            emitOperation("submit_score", false, "A Huawei leaderboard ID is required.")
            return
        }
        runOnHostThread {
            Games.getRankingsClient(activity).submitScoreWithResult(leaderboardId, score)
                .addOnSuccessListener { emitOperation("submit_score", true, leaderboardId) }
                .addOnFailureListener { emitOperation("submit_score", false, it.message ?: "Leaderboard score submission failed.") }
        }
    }

    @UsedByGodot
    fun showLeaderboard(leaderboardId: String) {
        if (!requireSignIn("show_leaderboard")) return
        if (leaderboardId.isBlank()) {
            emitOperation("show_leaderboard", false, "A Huawei leaderboard ID is required.")
            return
        }
        runOnHostThread {
            Games.getRankingsClient(activity).getRankingIntent(leaderboardId)
                .addOnSuccessListener { intent ->
                    if (intent == null) emitOperation("show_leaderboard", false, "Huawei did not return the leaderboard screen.")
                    else {
                        activity?.let { it.startActivity(intent) } ?: emitOperation("show_screen", false, "Godot activity is unavailable.")
                        emitOperation("show_leaderboard", true, leaderboardId)
                    }
                }
                .addOnFailureListener { emitOperation("show_leaderboard", false, it.message ?: "Could not open leaderboard.") }
        }
    }

    private fun requireSignIn(operation: String): Boolean {
        if (signedIn) return true
        emitOperation(operation, false, "Sign in to Huawei Game Service first.")
        return false
    }

    private fun emitOperation(operation: String, success: Boolean, details: String) {
        emitSignal("operation_completed", operation, success, details)
    }
}




