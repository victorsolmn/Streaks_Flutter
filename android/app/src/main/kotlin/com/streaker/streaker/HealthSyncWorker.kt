package com.streaker.streaker

import android.content.Context
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit

class HealthSyncWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        const val TAG = "HealthSyncWorker"
        const val WORK_NAME = "health_sync_work"
        
        fun schedulePeriodicSync(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            
            // Schedule hourly sync
            val syncRequest = PeriodicWorkRequestBuilder<HealthSyncWorker>(
                1, // Repeat every 1 hour
                java.util.concurrent.TimeUnit.HOURS
            )
                .setConstraints(constraints)
                .addTag("health_sync")
                .build()
            
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.REPLACE,
                syncRequest
            )
            
            Log.d(TAG, "Scheduled hourly health sync")
        }
        
        fun cancelSync(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            Log.d(TAG, "Cancelled health sync")
        }
    }
    
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Starting background health sync...")
            
            // Initialize Health Connect client
            val providerPackageName = "com.google.android.apps.healthdata"
            val healthConnectClient = HealthConnectClient.getOrCreate(applicationContext, providerPackageName)
            
            // Check if we have permissions
            val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()
            if (grantedPermissions.isEmpty()) {
                Log.w(TAG, "No Health Connect permissions granted, skipping sync")
                return@withContext Result.failure()
            }
            
            val now = Instant.now()
            val oneHourAgo = now.minus(1, ChronoUnit.HOURS)
            
            // Sync recent data (last hour)
            val healthData = mutableMapOf<String, Any>()
            val dataSources = mutableSetOf<String>()
            
            // Read steps
            try {
                val stepsResponse = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        StepsRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(oneHourAgo, now)
                    )
                )
                
                var totalSteps = 0L
                stepsResponse.records.forEach { record ->
                    totalSteps += record.count
                    val source = record.metadata.dataOrigin.packageName
                    dataSources.add(source)
                    
                    // Log Samsung Health data
                    // Samsung Health uses com.sec.android.app.shealth
                    if (source.contains("samsung") || 
                        source.contains("shealth") || 
                        source.contains("com.sec.android") || 
                        source.contains("gear")) {
                        Log.d(TAG, "Synced ${record.count} steps from Samsung Health/Galaxy Watch")
                    }
                }
                
                healthData["steps"] = totalSteps
                Log.d(TAG, "Synced $totalSteps steps in the last hour")
            } catch (e: Exception) {
                Log.e(TAG, "Error syncing steps", e)
            }
            
            // Read heart rate
            try {
                val heartRateResponse = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        HeartRateRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(oneHourAgo, now)
                    )
                )
                
                if (heartRateResponse.records.isNotEmpty()) {
                    val latestRecord = heartRateResponse.records.maxByOrNull { it.endTime }
                    val latestHeartRate = latestRecord?.samples?.lastOrNull()?.beatsPerMinute ?: 0
                    healthData["heartRate"] = latestHeartRate
                    Log.d(TAG, "Synced heart rate: $latestHeartRate bpm")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error syncing heart rate", e)
            }
            
            // Read calories
            try {
                val caloriesResponse = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        ActiveCaloriesBurnedRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(oneHourAgo, now)
                    )
                )
                
                var totalCalories = 0.0
                caloriesResponse.records.forEach { record ->
                    totalCalories += record.energy.inKilocalories
                }
                healthData["calories"] = totalCalories
                Log.d(TAG, "Synced $totalCalories calories burned")
            } catch (e: Exception) {
                Log.e(TAG, "Error syncing calories", e)
            }
            
            // Store the data locally or send to server
            // For now, we'll just save to SharedPreferences
            val sharedPrefs = applicationContext.getSharedPreferences("health_sync", Context.MODE_PRIVATE)
            sharedPrefs.edit().apply {
                putLong("last_sync_time", System.currentTimeMillis())
                putInt("last_sync_steps", (healthData["steps"] as? Long ?: 0L).toInt())
                putInt("last_sync_heart_rate", (healthData["heartRate"] as? Long ?: 0L).toInt())
                putFloat("last_sync_calories", (healthData["calories"] as? Double ?: 0.0).toFloat())
                putStringSet("data_sources", dataSources)
                apply()
            }
            
            Log.d(TAG, "Background sync completed successfully")
            Log.d(TAG, "Data sources: ${dataSources.joinToString(", ")}")
            
            return@withContext Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Background sync failed", e)
            return@withContext Result.retry()
        }
    }
}