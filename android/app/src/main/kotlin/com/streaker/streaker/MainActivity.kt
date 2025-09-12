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
import io.flutter.embedding.android.FlutterFragmentActivity
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

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.streaker/health_connect"
    private val TAG = "HealthConnect"
    
    private lateinit var healthConnectClient: HealthConnectClient
    private lateinit var methodChannel: MethodChannel
    
    // Define the permissions we need - including Samsung Health specific data types
    private val permissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
        HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class), // Samsung Health uses total calories
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(HydrationRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getReadPermission(OxygenSaturationRecord::class),
        HealthPermission.getReadPermission(BloodPressureRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        HealthPermission.getReadPermission(RestingHeartRateRecord::class) // Samsung Health resting heart rate
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
                Log.d(TAG, "=== REQUESTING HEALTH PERMISSIONS ===")
                Log.d(TAG, "Requesting permissions for ${permissions.size} data types:")
                permissions.forEachIndexed { index, permission ->
                    Log.d(TAG, "  ${index + 1}. $permission")
                }
                
                // Check which permissions are already granted
                val granted = healthConnectClient.permissionController.getGrantedPermissions()
                Log.d(TAG, "Already granted: ${granted.size} permissions")
                if (granted.isNotEmpty()) {
                    Log.d(TAG, "Granted permissions:")
                    granted.forEach { permission ->
                        Log.d(TAG, "  ✅ $permission")
                    }
                }
                
                val notGranted = permissions - granted
                if (notGranted.isNotEmpty()) {
                    Log.d(TAG, "Need to request ${notGranted.size} additional permissions:")
                    notGranted.forEach { permission ->
                        Log.d(TAG, "  ❌ $permission")
                    }
                    
                    // Request ALL permissions (including already granted ones for completeness)
                    val contract = PermissionController.createRequestPermissionResultContract()
                    val intent = contract.createIntent(this@MainActivity, permissions)
                    startActivityForResult(intent, PERMISSION_REQUEST_CODE)
                    
                    Log.d(TAG, "Permission dialog launched - waiting for user response...")
                } else {
                    Log.d(TAG, "All permissions already granted!")
                    result.success(mapOf(
                        "status" to "already_granted",
                        "granted" to true,
                        "grantedCount" to granted.size,
                        "requiredCount" to permissions.size
                    ))
                    return@launch
                }
                
                // Return immediately, result will be handled in onActivityResult
                result.success(mapOf(
                    "status" to "requesting",
                    "message" to "Permission dialog opened - grant access to: Steps, Heart Rate, Calories, Distance, Sleep, Water, Weight, Blood Oxygen, Blood Pressure, Exercise sessions"
                ))
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
            Log.d(TAG, "=== PERMISSION STATUS CHECK ===")
            Log.d(TAG, "Granted permissions: ${granted.size} out of ${permissions.size}")
            
            val allGranted = granted.containsAll(permissions)
            val missingPermissions = permissions - granted
            
            // Log granted permissions
            if (granted.isNotEmpty()) {
                Log.d(TAG, "✅ Granted permissions:")
                granted.forEach { permission ->
                    Log.d(TAG, "   $permission")
                }
            }
            
            // Log missing permissions
            if (missingPermissions.isNotEmpty()) {
                Log.w(TAG, "❌ Missing permissions:")
                missingPermissions.forEach { permission ->
                    Log.w(TAG, "   $permission")
                }
                Log.w(TAG, "USER ACTION REQUIRED: Please grant all health permissions in Health Connect")
            } else {
                Log.i(TAG, "🎉 All permissions granted! Health data access is ready.")
            }
            
            val response = mapOf(
                "granted" to allGranted,
                "grantedCount" to granted.size,
                "requiredCount" to permissions.size,
                "grantedPermissions" to granted.map { it.toString() },
                "missingPermissions" to missingPermissions.map { it.toString() },
                "message" to if (allGranted) {
                    "All health permissions granted! Ready to sync health data."
                } else {
                    "Missing ${missingPermissions.size} permissions. Please grant access to: ${missingPermissions.joinToString(", ") { it.toString().substringAfterLast(".") }}"
                }
            )
            
            if (result != null) {
                result.success(response)
            } else {
                // Send update to Flutter via event channel or method channel
                methodChannel.invokeMethod("onPermissionsChecked", response)
            }
            
            Log.d(TAG, "Permission check complete: ${if (allGranted) "SUCCESS" else "INCOMPLETE"}")
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
                
                // Read heart rate - prioritize resting heart rate, then try regular heart rate
                try {
                    var heartRateValue = 0
                    var heartRateType = "none"
                    
                    // First try to get resting heart rate (Samsung Health priority)
                    try {
                        val restingHRResponse = healthConnectClient.readRecords(
                            ReadRecordsRequest(
                                RestingHeartRateRecord::class,
                                timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                            )
                        )
                        
                        if (restingHRResponse.records.isNotEmpty()) {
                            var samsungRestingHR = 0L
                            var otherRestingHR = 0L
                            
                            restingHRResponse.records.forEach { record ->
                                val source = record.metadata.dataOrigin.packageName
                                val beatsPerMinute = record.beatsPerMinute
                                
                                Log.d(TAG, "Resting HR: $beatsPerMinute bpm from $source")
                                
                                if (source.contains("shealth") || 
                                    source.contains("com.sec.android") || 
                                    source.contains("samsung")) {
                                    samsungRestingHR = beatsPerMinute
                                } else {
                                    otherRestingHR = beatsPerMinute
                                }
                            }
                            
                            if (samsungRestingHR > 0) {
                                heartRateValue = samsungRestingHR.toInt()
                                heartRateType = "samsung_resting"
                                Log.d(TAG, "Using Samsung resting heart rate: $heartRateValue bpm")
                            } else if (otherRestingHR > 0) {
                                heartRateValue = otherRestingHR.toInt()
                                heartRateType = "other_resting"
                            }
                        }
                    } catch (e: Exception) {
                        Log.d(TAG, "Resting heart rate not available, trying regular heart rate", e)
                    }
                    
                    // If no resting heart rate found, try regular heart rate data
                    if (heartRateValue == 0) {
                        val heartRateResponse = healthConnectClient.readRecords(
                            ReadRecordsRequest(
                                HeartRateRecord::class,
                                timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                            )
                        )
                        
                        if (heartRateResponse.records.isNotEmpty()) {
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
                            
                            val heartRatesToUse = if (samsungHeartRates.isNotEmpty()) samsungHeartRates else otherHeartRates
                            
                            if (heartRatesToUse.isNotEmpty()) {
                                // For Samsung Health, get average of all readings rather than minimum
                                if (samsungHeartRates.isNotEmpty()) {
                                    heartRateValue = (samsungHeartRates.sum() / samsungHeartRates.size).toInt()
                                    heartRateType = "samsung_average"
                                } else {
                                    // For non-Samsung, use latest reading
                                    heartRateValue = heartRatesToUse.last().toInt()
                                    heartRateType = "other_latest"
                                }
                                
                                Log.d(TAG, "Heart rate ($heartRateType): $heartRateValue bpm from ${heartRatesToUse.size} samples")
                            }
                        }
                    }
                    
                    healthData["heartRate"] = heartRateValue
                    healthData["heartRateType"] = heartRateType
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading heart rate data", e)
                    healthData["heartRate"] = 0
                    healthData["heartRateType"] = "error"
                }
                
                // Read calories with source prioritization - try both active and total calories
                try {
                    var samsungActiveCalories = 0.0
                    var samsungTotalCalories = 0.0
                    var googleFitCalories = 0.0
                    var otherCalories = 0.0
                    
                    // Read Active Calories (exercise calories)
                    try {
                        val activeCaloriesResponse = healthConnectClient.readRecords(
                            ReadRecordsRequest(
                                ActiveCaloriesBurnedRecord::class,
                                timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                            )
                        )
                        
                        activeCaloriesResponse.records.forEach { record ->
                            val source = record.metadata.dataOrigin.packageName
                            val calories = record.energy.inKilocalories
                            
                            when {
                                source.contains("shealth") || 
                                source.contains("com.sec.android") || 
                                source.contains("samsung") -> {
                                    samsungActiveCalories += calories
                                    Log.d(TAG, "Samsung active calories: $calories kcal from $source")
                                }
                                source.contains("google.android.apps.fitness") -> {
                                    googleFitCalories += calories
                                }
                                else -> {
                                    otherCalories += calories
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.d(TAG, "Active calories not available", e)
                    }
                    
                    // Read Total Calories (Samsung Health often uses this)
                    try {
                        val totalCaloriesResponse = healthConnectClient.readRecords(
                            ReadRecordsRequest(
                                TotalCaloriesBurnedRecord::class,
                                timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                            )
                        )
                        
                        totalCaloriesResponse.records.forEach { record ->
                            val source = record.metadata.dataOrigin.packageName
                            val calories = record.energy.inKilocalories
                            
                            when {
                                source.contains("shealth") || 
                                source.contains("com.sec.android") || 
                                source.contains("samsung") -> {
                                    samsungTotalCalories += calories
                                    Log.d(TAG, "Samsung total calories: $calories kcal from $source")
                                }
                                source.contains("google.android.apps.fitness") -> {
                                    if (samsungActiveCalories == 0.0) googleFitCalories += calories // Avoid double counting
                                }
                                else -> {
                                    if (samsungActiveCalories == 0.0 && samsungTotalCalories == 0.0) otherCalories += calories
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.d(TAG, "Total calories not available", e)
                    }
                    
                    // Prioritize Samsung Health data - use total calories if available, otherwise active
                    val finalCalories = when {
                        samsungTotalCalories > 0 -> {
                            Log.d(TAG, "Using Samsung total calories: $samsungTotalCalories kcal")
                            samsungTotalCalories
                        }
                        samsungActiveCalories > 0 -> {
                            Log.d(TAG, "Using Samsung active calories: $samsungActiveCalories kcal")
                            samsungActiveCalories
                        }
                        googleFitCalories > 0 -> {
                            Log.d(TAG, "No Samsung data, using Google Fit: $googleFitCalories kcal")
                            googleFitCalories
                        }
                        else -> {
                            Log.d(TAG, "Using other sources: $otherCalories kcal")
                            otherCalories
                        }
                    }
                    
                    healthData["calories"] = finalCalories.toInt()
                    Log.d(TAG, "Final calories (prioritizing Samsung): $finalCalories kcal")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading calories", e)
                    healthData["calories"] = 0
                }
                
                // Read distance with source prioritization - detailed logging for debugging
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
                    val distanceDetails = mutableListOf<Map<String, Any>>()
                    
                    Log.d(TAG, "Found ${distanceResponse.records.size} distance records")
                    
                    distanceResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val distance = record.distance.inKilometers
                        
                        val detail = mapOf(
                            "distance" to distance,
                            "source" to source,
                            "startTime" to record.startTime.toString(),
                            "endTime" to record.endTime.toString()
                        )
                        
                        Log.d(TAG, "Distance record: $distance km from $source (${record.startTime} to ${record.endTime})")
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                samsungDistance += distance
                                distanceDetails.add(detail)
                                Log.d(TAG, "  -> Samsung Health distance: $distance km (running total: $samsungDistance km)")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitDistance += distance
                                if (samsungDistance == 0.0) distanceDetails.add(detail)
                                Log.d(TAG, "  -> Google Fit distance: $distance km (running total: $googleFitDistance km)")
                            }
                            else -> {
                                otherDistance += distance
                                if (samsungDistance == 0.0 && googleFitDistance == 0.0) distanceDetails.add(detail)
                                Log.d(TAG, "  -> Other source distance: $distance km (running total: $otherDistance km)")
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalDistance = when {
                        samsungDistance > 0 -> {
                            Log.d(TAG, "Using Samsung Health distance: $samsungDistance km")
                            samsungDistance
                        }
                        googleFitDistance > 0 -> {
                            Log.d(TAG, "No Samsung data, using Google Fit distance: $googleFitDistance km")
                            googleFitDistance
                        }
                        else -> {
                            Log.d(TAG, "Using other sources distance: $otherDistance km")
                            otherDistance
                        }
                    }
                    
                    healthData["distance"] = finalDistance
                    healthData["distanceDetails"] = distanceDetails
                    Log.d(TAG, "FINAL distance (prioritizing Samsung): $finalDistance km from ${distanceResponse.records.size} records")
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
                
                // Read water/hydration data with source prioritization
                try {
                    val hydrationResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            HydrationRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    var samsungWater = 0.0
                    var googleFitWater = 0.0
                    var otherWater = 0.0
                    
                    hydrationResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val volume = record.volume.inLiters * 1000 // Convert to ml
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                samsungWater += volume
                                Log.d(TAG, "Samsung water: $volume ml")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitWater += volume
                            }
                            else -> {
                                otherWater += volume
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalWater = when {
                        samsungWater > 0 -> samsungWater
                        googleFitWater > 0 -> googleFitWater
                        else -> otherWater
                    }
                    
                    healthData["water"] = finalWater.toInt()
                    Log.d(TAG, "Total water (prioritizing Samsung): $finalWater ml")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading water data", e)
                    healthData["water"] = 0
                }
                
                // Read weight data with source prioritization
                try {
                    val weightResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            WeightRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(
                                startOfDay.minus(7, ChronoUnit.DAYS), // Last week for weight
                                now
                            )
                        )
                    )
                    
                    var samsungWeight = 0.0
                    var googleFitWeight = 0.0
                    var otherWeight = 0.0
                    var samsungWeightTime: Instant? = null
                    var otherWeightTime: Instant? = null
                    
                    weightResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val weight = record.weight.inKilograms
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                // Get the most recent Samsung weight
                                if (samsungWeightTime == null || record.time.isAfter(samsungWeightTime)) {
                                    samsungWeight = weight
                                    samsungWeightTime = record.time
                                }
                                Log.d(TAG, "Samsung weight: $weight kg at ${record.time}")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitWeight = weight // Just use latest
                            }
                            else -> {
                                // Get the most recent other weight
                                if (otherWeightTime == null || record.time.isAfter(otherWeightTime)) {
                                    otherWeight = weight
                                    otherWeightTime = record.time
                                }
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalWeight = when {
                        samsungWeight > 0 -> samsungWeight
                        googleFitWeight > 0 -> googleFitWeight
                        else -> otherWeight
                    }
                    
                    healthData["weight"] = finalWeight
                    Log.d(TAG, "Latest weight (prioritizing Samsung): $finalWeight kg")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading weight data", e)
                    healthData["weight"] = 0.0
                }
                
                // Read blood oxygen data with source prioritization
                try {
                    val oxygenResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            OxygenSaturationRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    var samsungOxygen = 0.0
                    var googleFitOxygen = 0.0
                    var otherOxygen = 0.0
                    var samsungOxygenTime: Instant? = null
                    var otherOxygenTime: Instant? = null
                    
                    oxygenResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val percentage = record.percentage.value
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                // Get the most recent Samsung reading
                                if (samsungOxygenTime == null || record.time.isAfter(samsungOxygenTime)) {
                                    samsungOxygen = percentage
                                    samsungOxygenTime = record.time
                                }
                                Log.d(TAG, "Samsung blood oxygen: $percentage% at ${record.time}")
                            }
                            source.contains("google.android.apps.fitness") -> {
                                googleFitOxygen = percentage
                            }
                            else -> {
                                if (otherOxygenTime == null || record.time.isAfter(otherOxygenTime)) {
                                    otherOxygen = percentage
                                    otherOxygenTime = record.time
                                }
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalOxygen = when {
                        samsungOxygen > 0 -> samsungOxygen
                        googleFitOxygen > 0 -> googleFitOxygen
                        else -> otherOxygen
                    }
                    
                    healthData["bloodOxygen"] = finalOxygen.toInt()
                    Log.d(TAG, "Latest blood oxygen (prioritizing Samsung): $finalOxygen%")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading blood oxygen data", e)
                    healthData["bloodOxygen"] = 0
                }
                
                // Read blood pressure data with source prioritization
                try {
                    val bpResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            BloodPressureRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    var samsungSystolic = 0.0
                    var samsungDiastolic = 0.0
                    var otherSystolic = 0.0
                    var otherDiastolic = 0.0
                    var samsungBpTime: Instant? = null
                    var otherBpTime: Instant? = null
                    
                    bpResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val systolic = record.systolic.inMillimetersOfMercury
                        val diastolic = record.diastolic.inMillimetersOfMercury
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                // Get the most recent Samsung reading
                                if (samsungBpTime == null || record.time.isAfter(samsungBpTime)) {
                                    samsungSystolic = systolic
                                    samsungDiastolic = diastolic
                                    samsungBpTime = record.time
                                }
                                Log.d(TAG, "Samsung blood pressure: $systolic/$diastolic mmHg at ${record.time}")
                            }
                            else -> {
                                if (otherBpTime == null || record.time.isAfter(otherBpTime)) {
                                    otherSystolic = systolic
                                    otherDiastolic = diastolic
                                    otherBpTime = record.time
                                }
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalSystolic = if (samsungSystolic > 0) samsungSystolic else otherSystolic
                    val finalDiastolic = if (samsungDiastolic > 0) samsungDiastolic else otherDiastolic
                    
                    healthData["bloodPressure"] = mapOf(
                        "systolic" to finalSystolic.toInt(),
                        "diastolic" to finalDiastolic.toInt()
                    )
                    Log.d(TAG, "Latest blood pressure (prioritizing Samsung): $finalSystolic/$finalDiastolic mmHg")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading blood pressure data", e)
                    healthData["bloodPressure"] = mapOf("systolic" to 0, "diastolic" to 0)
                }
                
                // Read exercise/workout data with source prioritization
                try {
                    val exerciseResponse = healthConnectClient.readRecords(
                        ReadRecordsRequest(
                            ExerciseSessionRecord::class,
                            timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                        )
                    )
                    
                    var samsungWorkouts = 0
                    var samsungExerciseMinutes = 0L
                    var otherWorkouts = 0
                    var otherExerciseMinutes = 0L
                    val workoutDetails = mutableListOf<Map<String, Any>>()
                    
                    exerciseResponse.records.forEach { record ->
                        val source = record.metadata.dataOrigin.packageName
                        val duration = java.time.Duration.between(record.startTime, record.endTime)
                        val minutes = duration.toMinutes()
                        
                        val workoutDetail = mapOf(
                            "exerciseType" to (record.exerciseType.toString()),
                            "duration" to minutes,
                            "startTime" to record.startTime.toString(),
                            "endTime" to record.endTime.toString(),
                            "source" to source,
                            "title" to (record.title ?: "Workout")
                        )
                        
                        when {
                            source.contains("shealth") || 
                            source.contains("com.sec.android") || 
                            source.contains("samsung") -> {
                                samsungWorkouts++
                                samsungExerciseMinutes += minutes
                                workoutDetails.clear() // Clear other workouts, use Samsung only
                                workoutDetails.add(workoutDetail)
                                Log.d(TAG, "Samsung workout: ${record.exerciseType} for $minutes min")
                            }
                            else -> {
                                // Only add non-Samsung workouts if no Samsung data exists
                                if (samsungWorkouts == 0) {
                                    otherWorkouts++
                                    otherExerciseMinutes += minutes
                                    workoutDetails.add(workoutDetail)
                                }
                            }
                        }
                    }
                    
                    // Prioritize Samsung Health data
                    val finalWorkouts = if (samsungWorkouts > 0) samsungWorkouts else otherWorkouts
                    val finalExerciseMinutes = if (samsungExerciseMinutes > 0) samsungExerciseMinutes else otherExerciseMinutes
                    
                    healthData["workouts"] = finalWorkouts
                    healthData["exerciseMinutes"] = finalExerciseMinutes
                    healthData["workoutDetails"] = workoutDetails
                    Log.d(TAG, "Total workouts (prioritizing Samsung): $finalWorkouts ($finalExerciseMinutes min)")
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading exercise data", e)
                    healthData["workouts"] = 0
                    healthData["exerciseMinutes"] = 0
                }
                
                // Add metadata
                healthData["dataSources"] = dataSources.toList()
                healthData["lastSync"] = Instant.now().toString()
                healthData["syncTime"] = System.currentTimeMillis()
                
                // Check if Samsung Health data is actually present
                val hasSamsungData = dataSources.any { 
                    it.contains("samsung") || 
                    it.contains("shealth") || 
                    it.contains("com.sec.android") || 
                    it.contains("gear") 
                }
                healthData["hasSamsungHealthData"] = hasSamsungData
                
                Log.d(TAG, "=== Health Data Summary ===")
                Log.d(TAG, "Data sources found: ${dataSources.joinToString(", ")}")
                Log.d(TAG, "Samsung Health detected: $hasSamsungData")
                Log.d(TAG, "Steps: ${healthData["steps"]} (${healthData["stepsBySource"]?.let { (it as Map<*, *>)["dataSource"] } ?: "Unknown"})")
                Log.d(TAG, "Heart Rate: ${healthData["heartRate"]} bpm (${healthData["heartRateType"]})")
                Log.d(TAG, "Calories: ${healthData["calories"]} kcal")
                Log.d(TAG, "Distance: ${healthData["distance"]} km")
                Log.d(TAG, "Sleep: ${healthData["sleep"]} hours (${healthData["sleepMinutes"]} minutes)")
                Log.d(TAG, "Water: ${healthData["water"]} ml")
                Log.d(TAG, "Weight: ${healthData["weight"]} kg")
                Log.d(TAG, "Blood Oxygen: ${healthData["bloodOxygen"]}%")
                val bloodPressure = healthData["bloodPressure"] as? Map<*, *>
                Log.d(TAG, "Blood Pressure: ${bloodPressure?.get("systolic")}/${bloodPressure?.get("diastolic")} mmHg")
                Log.d(TAG, "Workouts: ${healthData["workouts"]} (${healthData["exerciseMinutes"]} min)")
                
                if (!hasSamsungData) {
                    Log.w(TAG, "⚠️  WARNING: No Samsung Health data found! Check if Samsung Health is installed and has data.")
                    Log.w(TAG, "⚠️  Available sources: ${dataSources.joinToString(", ")}")
                } else {
                    Log.i(TAG, "✅ Samsung Health data successfully detected")
                }
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