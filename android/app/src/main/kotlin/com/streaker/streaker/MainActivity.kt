package com.streaker.streaker

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit
import android.content.Context
import androidx.work.WorkManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.streaker/health_connect"
    private val TAG = "HealthConnect"
    
    private lateinit var healthConnectClient: HealthConnectClient
    private lateinit var methodChannel: MethodChannel
    
    // Define the permissions we need
    private val permissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
        HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(HydrationRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getReadPermission(OxygenSaturationRecord::class),
        HealthPermission.getReadPermission(BloodPressureRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class)
    )
    
    // Permission request code
    private val PERMISSION_REQUEST_CODE = 1001
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Health Connect client
        val providerPackageName = "com.google.android.apps.healthdata"
        healthConnectClient = HealthConnectClient.getOrCreate(this, providerPackageName)
        
        Log.d(TAG, "Health Connect client initialized")
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> checkAvailability(result)
                "requestPermissions" -> requestPermissions(result)
                "checkPermissions" -> checkPermissions(result)
                "readSteps" -> readSteps(result)
                "readHeartRate" -> readHeartRate(result)
                "readCalories" -> readCalories(result)
                "readDistance" -> readDistance(result)
                "readAllData" -> readAllHealthData(result)
                "startBackgroundSync" -> startBackgroundSync(result)
                "stopBackgroundSync" -> stopBackgroundSync(result)
                "getLastSyncInfo" -> getLastSyncInfo(result)
                else -> result.notImplemented()
            }
        }
    }
    
    private fun checkAvailability(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val availability = HealthConnectClient.getSdkStatus(this@MainActivity, "com.google.android.apps.healthdata")
                Log.d(TAG, "Health Connect SDK status: $availability")
                
                when (availability) {
                    HealthConnectClient.SDK_AVAILABLE -> {
                        result.success(mapOf(
                            "available" to true,
                            "status" to "available"
                        ))
                    }
                    HealthConnectClient.SDK_UNAVAILABLE -> {
                        result.success(mapOf(
                            "available" to false,
                            "status" to "not_installed"
                        ))
                    }
                    HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> {
                        result.success(mapOf(
                            "available" to false,
                            "status" to "update_required"
                        ))
                    }
                    else -> {
                        result.success(mapOf(
                            "available" to false,
                            "status" to "unknown"
                        ))
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking availability", e)
                result.error("AVAILABILITY_ERROR", e.message, null)
            }
        }
    }
    
    private fun requestPermissions(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                Log.d(TAG, "Requesting permissions for ${permissions.size} data types")
                
                // Check which permissions are already granted
                val granted = healthConnectClient.permissionController.getGrantedPermissions()
                Log.d(TAG, "Already granted: ${granted.size} permissions")
                
                // Request permissions using the permission controller
                val contract = PermissionController.createRequestPermissionResultContract()
                val intent = contract.createIntent(this@MainActivity, permissions)
                startActivityForResult(intent, PERMISSION_REQUEST_CODE)
                
                // Return immediately, result will be handled in onActivityResult
                result.success(mapOf("status" to "requesting"))
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting permissions", e)
                result.error("PERMISSION_ERROR", e.message, null)
            }
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            Log.d(TAG, "Permission request result: $resultCode")
            coroutineScope.launch {
                checkPermissionsAndRespond()
            }
        }
    }
    
    private fun checkPermissions(result: MethodChannel.Result) {
        coroutineScope.launch {
            checkPermissionsAndRespond(result)
        }
    }
    
    private suspend fun checkPermissionsAndRespond(result: MethodChannel.Result? = null) {
        try {
            val granted = healthConnectClient.permissionController.getGrantedPermissions()
            Log.d(TAG, "Granted permissions: ${granted.size} out of ${permissions.size}")
            
            val allGranted = granted.containsAll(permissions)
            
            val response = mapOf(
                "granted" to allGranted,
                "grantedCount" to granted.size,
                "requiredCount" to permissions.size,
                "grantedPermissions" to granted.map { it.toString() }
            )
            
            if (result != null) {
                result.success(response)
            } else {
                // Send update to Flutter via event channel or method channel
                methodChannel.invokeMethod("onPermissionsChecked", response)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking permissions", e)
            result?.error("CHECK_ERROR", e.message, null)
        }
    }
    
    private fun readSteps(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val now = Instant.now()
                val startOfDay = ZonedDateTime.now().truncatedTo(ChronoUnit.DAYS).toInstant()
                
                Log.d(TAG, "Reading steps from $startOfDay to $now")
                
                val response = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        StepsRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                    )
                )
                
                // Separate steps by source to avoid double-counting
                var samsungSteps = 0L
                var googleFitSteps = 0L
                var otherSteps = 0L
                val stepDetails = mutableListOf<Map<String, Any>>()
                
                response.records.forEach { record ->
                    val source = record.metadata.dataOrigin.packageName
                    Log.d(TAG, "Steps record: ${record.count} steps from ${source}")
                    Log.d(TAG, "  Time: ${record.startTime} to ${record.endTime}")
                    
                    val detail = mapOf(
                        "count" to record.count,
                        "startTime" to record.startTime.toString(),
                        "endTime" to record.endTime.toString(),
                        "source" to source
                    )
                    
                    // Categorize by source
                    when {
                        source.contains("shealth") || 
                        source.contains("com.sec.android") || 
                        source.contains("samsung") || 
                        source.contains("gear") -> {
                            samsungSteps += record.count
                            stepDetails.add(detail)
                        }
                        source.contains("google.android.apps.fitness") -> {
                            googleFitSteps += record.count
                            if (samsungSteps == 0L) stepDetails.add(detail) // Only add if no Samsung data
                        }
                        else -> {
                            otherSteps += record.count
                            if (samsungSteps == 0L && googleFitSteps == 0L) stepDetails.add(detail)
                        }
                    }
                }
                
                // PRIORITY: Use Samsung Health data if available, otherwise fall back to Google Fit
                val finalSteps = when {
                    samsungSteps > 0 -> {
                        Log.d(TAG, "Using Samsung Health data: $samsungSteps steps (ignoring Google Fit: $googleFitSteps)")
                        samsungSteps
                    }
                    googleFitSteps > 0 -> {
                        Log.d(TAG, "No Samsung Health data, using Google Fit: $googleFitSteps steps")
                        googleFitSteps
                    }
                    else -> {
                        Log.d(TAG, "Using other sources: $otherSteps steps")
                        otherSteps
                    }
                }
                
                Log.d(TAG, "FINAL steps (prioritizing Samsung): $finalSteps from ${response.records.size} records")
                
                val resultData = mapOf(
                    "totalSteps" to finalSteps.toInt(),
                    "recordCount" to response.records.size,
                    "details" to stepDetails,
                    "lastSync" to Instant.now().toString(),
                    "dataSource" to when {
                        samsungSteps > 0 -> "Samsung Health"
                        googleFitSteps > 0 -> "Google Fit"
                        else -> "Other"
                    }
                )
                
                result.success(resultData)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading steps", e)
                result.error("READ_ERROR", e.message, null)
            }
        }
    }
    
    private fun readHeartRate(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val now = Instant.now()
                val oneHourAgo = now.minus(1, ChronoUnit.HOURS)
                
                val response = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        HeartRateRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(oneHourAgo, now)
                    )
                )
                
                if (response.records.isNotEmpty()) {
                    // Get the most recent heart rate
                    val latestRecord = response.records.maxByOrNull { it.endTime }
                    val latestHeartRate = latestRecord?.samples?.lastOrNull()?.beatsPerMinute ?: 0
                    
                    Log.d(TAG, "Latest heart rate: $latestHeartRate bpm")
                    result.success(latestHeartRate.toInt())
                } else {
                    result.success(0)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error reading heart rate", e)
                result.error("READ_ERROR", e.message, null)
            }
        }
    }
    
    private fun readCalories(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val now = Instant.now()
                val startOfDay = ZonedDateTime.now().truncatedTo(ChronoUnit.DAYS).toInstant()
                
                val response = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        ActiveCaloriesBurnedRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                    )
                )
                
                var totalCalories = 0.0
                response.records.forEach { record ->
                    totalCalories += record.energy.inKilocalories
                }
                
                Log.d(TAG, "Total calories burned: $totalCalories kcal")
                result.success(totalCalories.toInt())
            } catch (e: Exception) {
                Log.e(TAG, "Error reading calories", e)
                result.error("READ_ERROR", e.message, null)
            }
        }
    }
    
    private fun readDistance(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val now = Instant.now()
                val startOfDay = ZonedDateTime.now().truncatedTo(ChronoUnit.DAYS).toInstant()
                
                val response = healthConnectClient.readRecords(
                    ReadRecordsRequest(
                        DistanceRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                    )
                )
                
                var totalDistance = 0.0
                response.records.forEach { record ->
                    totalDistance += record.distance.inKilometers
                }
                
                Log.d(TAG, "Total distance: $totalDistance km")
                result.success(totalDistance)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading distance", e)
                result.error("READ_ERROR", e.message, null)
            }
        }
    }
    
    private fun readAllHealthData(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val now = Instant.now()
                val startOfDay = ZonedDateTime.now().truncatedTo(ChronoUnit.DAYS).toInstant()
                
                Log.d(TAG, "=== Fetching all health data ===")
                Log.d(TAG, "Time range: $startOfDay to $now")
                
                val healthData = mutableMapOf<String, Any>()
                val dataSources = mutableSetOf<String>()
                val stepDetails = mutableListOf<Map<String, Any>>()
                
                // Read steps with detailed source tracking
                try {
                    val stepsResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            StepsRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    // Separate steps by source to avoid double-counting
                    var samsungSteps = 0L
                    var googleFitSteps = 0L
                    var otherSteps = 0L
                    val samsungRecords = mutableListOf<Map<String, Any>>()
                    val googleFitRecords = mutableListOf<Map<String, Any>>()
                    val otherRecords = mutableListOf<Map<String, Any>>()
                    
                    stepsResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        dataSources.add(source)
                        
                        Log.d(TAG, "Steps: ${record.count} from ${source}")
                        Log.d(TAG, "  Time: ${record.startTime} to ${record.endTime}")
                        
                        val recordDetail = mapOf(
                            "count" to record.count,
                            "source" to source,
                            "startTime" to record.startTime.toString(),
                            "endTime" to record.endTime.toString()
                        )
                        
                        // Categorize by source - Samsung Health uses com.sec.android.app.shealth
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") || 
                            source.contains("gear") -> {
                                samsungSteps += record.count
                                samsungRecords.add(recordDetail)
                                Log.d(TAG, "  -> Samsung/Galaxy Watch data detected!")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitSteps += record.count
                                googleFitRecords.add(recordDetail)
                                Log.d(TAG, "  -> Google Fit data")
                            }
                            else -> {
                                otherSteps += record.count
                                otherRecords.add(recordDetail)
                                Log.d(TAG, "  -> Other source")
                            }
                        }
                    }
                    
                    // PRIORITY: Use Samsung Health data if available, otherwise fall back to Google Fit
                    val finalSteps = when {
                        samsungSteps > 0 -> {
                            Log.d(TAG, "Using Samsung Health data: $samsungSteps steps")
                            stepDetails.addAll(samsungRecords)
                            samsungSteps
                        }
                        googleFitSteps > 0 -> {
                            Log.d(TAG, "Samsung Health not available, using Google Fit: $googleFitSteps steps")
                            stepDetails.addAll(googleFitRecords)
                            googleFitSteps
                        }
                        else -> {
                            Log.d(TAG, "Using other sources: $otherSteps steps")
                            stepDetails.addAll(otherRecords)
                            otherSteps
                        }
                    }
                    
                    Log.d(TAG, "=== Step Data Summary ===")
                    Log.d(TAG, "Samsung Health: $samsungSteps steps")
                    Log.d(TAG, "Google Fit: $googleFitSteps steps")
                    Log.d(TAG, "Other sources: $otherSteps steps")
                    Log.d(TAG, "FINAL STEPS (prioritizing Samsung): $finalSteps")
                    
                    healthData["steps"] = finalSteps.toInt()
                    healthData["stepDetails"] = stepDetails
                    healthData["stepsBySource"] = mapOf(
                        "samsung" to samsungSteps.toInt(),
                        "googleFit" to googleFitSteps.toInt(),
                        "other" to otherSteps.toInt(),
                        "dataSource" to when {
                            samsungSteps > 0 -> "Samsung Health"
                            googleFitSteps > 0 -> "Google Fit"
                            else -> "Other"
                        }
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading steps", e)
                    healthData["steps"] = 0
                }
                
                // Read heart rate - try to get the lowest (resting) from today
                try {
                    val heartRateResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            HeartRateRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    if (heartRateResponse.records.isNotEmpty()) {
                        // Collect all heart rate samples from Samsung Health
                        val samsungHeartRates = mutableListOf<Long>()
                        val otherHeartRates = mutableListOf<Long>()
                        
                        heartRateResponse.records.forEach { record ->
                            val source = record.metadata.dataOrigin.packageName
                            val samples = record.samples.map { it.beatsPerMinute }
                            
                            if (source.contains("shealth") || 
                                source.contains("com.sec.android") || 
                                source.contains("samsung")) {
                                samsungHeartRates.addAll(samples)
                                Log.d(TAG, "Samsung HR samples: ${samples.size} readings")
                            } else {
                                otherHeartRates.addAll(samples)
                            }
                        }
                        
                        // Use Samsung Health data if available, otherwise fall back
                        val heartRatesToUse = if (samsungHeartRates.isNotEmpty()) samsungHeartRates else otherHeartRates
                        
                        if (heartRatesToUse.isNotEmpty()) {
                            // Get the minimum (resting) and latest heart rate
                            val restingHeartRate = heartRatesToUse.minOrNull() ?: 0
                            val latestHeartRate = heartRatesToUse.last()
                            
                            // Use resting heart rate as the primary metric
                            healthData["heartRate"] = restingHeartRate.toInt()
                            healthData["latestHeartRate"] = latestHeartRate.toInt()
                            healthData["heartRateType"] = "resting"
                            
                            Log.d(TAG, "Heart rate - Resting: $restingHeartRate bpm, Latest: $latestHeartRate bpm")
                        } else {
                            healthData["heartRate"] = 0
                            healthData["heartRateType"] = "none"
                        }
                    } else {
                        healthData["heartRate"] = 0
                        healthData["heartRateType"] = "none"
                        Log.d(TAG, "No heart rate data found")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading heart rate", e)
                    healthData["heartRate"] = 0
                    healthData["heartRateType"] = "error"
                }
                
                // Read calories with source prioritization
                try {
                    val caloriesResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            ActiveCaloriesBurnedRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    var samsungCalories = 0.0
                    var googleFitCalories = 0.0
                    var otherCalories = 0.0
                    
                    caloriesResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val calories = record.energy.inKilocalories
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                samsungCalories += calories
                                Log.d(TAG, "Samsung calories: $calories kcal")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitCalories += calories
                            }
                            else -> {
                                otherCalories += calories
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalCalories = when {
                        samsungCalories > 0 -> samsungCalories
                        googleFitCalories > 0 -> googleFitCalories
                        else -> otherCalories
                    }
                    
                    healthData["calories"] = finalCalories.toInt()
                    Log.d(TAG, "Total calories (prioritizing Samsung): $finalCalories kcal")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading calories", e)
                    healthData["calories"] = 0
                }
                
                // Read distance with source prioritization
                try {
                    val distanceResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            DistanceRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    var samsungDistance = 0.0
                    var googleFitDistance = 0.0
                    var otherDistance = 0.0
                    
                    distanceResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val distance = record.distance.inKilometers
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                samsungDistance += distance
                                Log.d(TAG, "Samsung distance: $distance km")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitDistance += distance
                            }
                            else -> {
                                otherDistance += distance
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalDistance = when {
                        samsungDistance > 0 -> samsungDistance
                        googleFitDistance > 0 -> googleFitDistance
                        else -> otherDistance
                    }
                    
                    healthData["distance"] = finalDistance
                    Log.d(TAG, "Total distance (prioritizing Samsung): $finalDistance km")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading distance", e)
                    healthData["distance"] = 0.0
                }
                
                // Read sleep data
                try {
                    // Get sleep sessions from last night (last 24 hours)
                    val sleepResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            SleepSessionRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(
                                now.minus(24, ChronoUnit.HOURS), 
                                now
                            )
                        )
                    )
                    
                    if (sleepResponse.records.isNotEmpty()) {
                        var totalSleepMinutes = 0L
                        val sleepDetails = mutableListOf<Map<String, Any>>()
                        
                        sleepResponse.records.forEach { record ->
                            val source = record.metadata.dataOrigin.packageName
                            val duration = java.time.Duration.between(record.startTime, record.endTime)
                            val minutes = duration.toMinutes()
                            
                            Log.d(TAG, "Sleep session: ${minutes} minutes from ${source}")
                            Log.d(TAG, "  Time: ${record.startTime} to ${record.endTime}")
                            
                            // Prioritize Samsung Health for sleep data too
                            if (source.contains("shealth") || 
                                source.contains("com.sec.android") || 
                                source.contains("samsung")) {
                                totalSleepMinutes = minutes // Use Samsung data exclusively
                                sleepDetails.clear()
                                sleepDetails.add(mapOf(
                                    "duration" to minutes,
                                    "startTime" to record.startTime.toString(),
                                    "endTime" to record.endTime.toString(),
                                    "source" to source,
                                    "title" to (record.title ?: "Sleep"),
                                    "notes" to (record.notes ?: "")
                                ))
                                Log.d(TAG, "  -> Using Samsung sleep data")
                            } else if (totalSleepMinutes == 0L) {
                                // Only use non-Samsung data if no Samsung data exists
                                totalSleepMinutes += minutes
                                sleepDetails.add(mapOf(
                                    "duration" to minutes,
                                    "startTime" to record.startTime.toString(),
                                    "endTime" to record.endTime.toString(),
                                    "source" to source,
                                    "title" to (record.title ?: "Sleep"),
                                    "notes" to (record.notes ?: "")
                                ))
                            }
                        }
                        
                        // Convert minutes to hours
                        val sleepHours = totalSleepMinutes / 60.0
                        healthData["sleep"] = sleepHours
                        healthData["sleepMinutes"] = totalSleepMinutes
                        healthData["sleepDetails"] = sleepDetails
                        
                        Log.d(TAG, "Total sleep: $sleepHours hours ($totalSleepMinutes minutes)")
                        
                        // Note: Sleep stages would require SleepStageRecord which may not be available in all SDK versions
                    } else {
                        healthData["sleep"] = 0.0
                        healthData["sleepMinutes"] = 0
                        Log.d(TAG, "No sleep data found")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading sleep data", e)
                    healthData["sleep"] = 0.0
                    healthData["sleepMinutes"] = 0
                }
                
                // Add other default values
                healthData["water"] = 0
                healthData["weight"] = 0.0
                
                // Add metadata
                healthData["dataSources"] = dataSources.toList()
                healthData["lastSync"] = Instant.now().toString()
                healthData["syncTime"] = System.currentTimeMillis()
                
                Log.d(TAG, "=== Health Data Summary ===")
                Log.d(TAG, "Data sources found: ${dataSources.joinToString(", ")}")
                Log.d(TAG, "Steps: ${healthData["steps"]} (${healthData["stepsBySource"]?.let { (it as Map<*, *>)["dataSource"] } ?: "Unknown"})")
                Log.d(TAG, "Heart Rate: ${healthData["heartRate"]} bpm (${healthData["heartRateType"]})")
                Log.d(TAG, "Calories: ${healthData["calories"]} kcal")
                Log.d(TAG, "Distance: ${healthData["distance"]} km")
                Log.d(TAG, "Sleep: ${healthData["sleep"]} hours (${healthData["sleepMinutes"]} minutes)")
                Log.d(TAG, "=========================")
                
                result.success(healthData)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading all health data", e)
                result.error("READ_ERROR", e.message, null)
            }
        }
    }
    
    private fun startBackgroundSync(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Starting background health sync...")
            HealthSyncWorker.schedulePeriodicSync(this)
            
            result.success(mapOf(
                "success" to true,
                "message" to "Background sync scheduled for every hour"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error starting background sync", e)
            result.error("SYNC_ERROR", e.message, null)
        }
    }
    
    private fun stopBackgroundSync(result: MethodChannel.Result) {
        try {
            Log.d(TAG, "Stopping background health sync...")
            HealthSyncWorker.cancelSync(this)
            
            result.success(mapOf(
                "success" to true,
                "message" to "Background sync cancelled"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping background sync", e)
            result.error("SYNC_ERROR", e.message, null)
        }
    }
    
    private fun getLastSyncInfo(result: MethodChannel.Result) {
        try {
            val sharedPrefs = getSharedPreferences("health_sync", Context.MODE_PRIVATE)
            val lastSyncTime = sharedPrefs.getLong("last_sync_time", 0)
            val lastSyncSteps = sharedPrefs.getInt("last_sync_steps", 0)
            val lastSyncHeartRate = sharedPrefs.getInt("last_sync_heart_rate", 0)
            val lastSyncCalories = sharedPrefs.getFloat("last_sync_calories", 0f)
            val dataSources = sharedPrefs.getStringSet("data_sources", emptySet()) ?: emptySet()
            
            val syncInfo = mapOf(
                "lastSyncTime" to lastSyncTime,
                "lastSyncTimeString" to if (lastSyncTime > 0) Instant.ofEpochMilli(lastSyncTime).toString() else "Never",
                "lastSyncSteps" to lastSyncSteps,
                "lastSyncHeartRate" to lastSyncHeartRate,
                "lastSyncCalories" to lastSyncCalories,
                "dataSources" to dataSources.toList(),
                "hasSamsungData" to dataSources.any { 
                    it.contains("samsung") || 
                    it.contains("shealth") || 
                    it.contains("com.sec.android") || 
                    it.contains("gear") 
                }
            )
            
            Log.d(TAG, "Last sync info: $syncInfo")
            result.success(syncInfo)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting last sync info", e)
            result.error("SYNC_ERROR", e.message, null)
        }
    }
}