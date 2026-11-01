package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.dto.MessScanRequest;
import com.hosteldashboard.hosteldashboard.dto.ScanResponse;
import com.hosteldashboard.hosteldashboard.model.MealType;
import com.hosteldashboard.hosteldashboard.model.MessTiming;
import com.hosteldashboard.hosteldashboard.model.ScanLog;
import com.hosteldashboard.hosteldashboard.repository.MessTimingRepository;
import com.hosteldashboard.hosteldashboard.repository.ScanLogRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/scan")
public class ScanLogController {

    private final ScanLogRepository scanLogRepository;
    private final MessTimingRepository messTimingRepository;
    private final com.hosteldashboard.hosteldashboard.repository.StudentRepository studentRepository;

    public ScanLogController(ScanLogRepository scanLogRepository,
                             MessTimingRepository messTimingRepository,
                             com.hosteldashboard.hosteldashboard.repository.StudentRepository studentRepository) {
        this.scanLogRepository = scanLogRepository;
        this.messTimingRepository = messTimingRepository;
        this.studentRepository = studentRepository;
    }

    // 🎯 MAIN MESS ENTRY SCAN ENDPOINT
    @PostMapping("/mess")
    public ResponseEntity<ScanResponse> scanMess(@RequestBody MessScanRequest request) {
        String rollNumber = request.getStudentRollNumber();
        String mealTypeStr = request.getMealType();

        if (rollNumber == null || mealTypeStr == null) {
            return ResponseEntity.badRequest().body(new ScanResponse(
                    false, "REJECTED", "Roll Number and Meal Type are required!", rollNumber
            ));
        }

        // Validate that the student exists
        java.util.Optional<com.hosteldashboard.hosteldashboard.model.Student> studentOpt =
                studentRepository.findByRollNumber(rollNumber);
        if (studentOpt.isEmpty()) {
            return ResponseEntity.status(403).body(new ScanResponse(
                    false, "REJECTED", "Invalid QR code or student not registered.", rollNumber));
        }
        String studentName = studentOpt.get().getName();

        MealType mealType;
        try {
            mealType = MealType.valueOf(mealTypeStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ScanResponse(
                    false, "REJECTED", "Invalid Meal Type: " + mealTypeStr, studentName
            ));
        }

        Optional<MessTiming> timingOpt = messTimingRepository.findByMealType(mealType);
        if (timingOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(new ScanResponse(
                    false, "REJECTED", "Schedule timing not set for " + mealType, studentName
            ));
        }

        MessTiming timing = timingOpt.get();
        LocalTime now = LocalTime.now();
        LocalDate today = LocalDate.now();

        // 2. CHECK: Early Entry
        if (now.isBefore(timing.getStartTime())) {
            saveLog(rollNumber, mealType.name(), today, now, "REJECTED - Early Entry", "MESS_ENTRY");
            return ResponseEntity.ok(new ScanResponse(
                    false,
                    "REJECTED",
                    "Entry not available yet! " + mealType + " begins at " + timing.getStartTime() + ". Mess hours: " + timing.getStartTime() + " - " + timing.getEndTime() + ".",
                    studentName
            ));
        }

        // 3. CHECK: Late Entry
        if (now.isAfter(timing.getEndTime())) {
            saveLog(rollNumber, mealType.name(), today, now, "REJECTED - Time Over", "MESS_ENTRY");
            return ResponseEntity.ok(new ScanResponse(
                    false,
                    "REJECTED",
                    mealType + " hours have ended! Closing time was " + timing.getEndTime() + ".",
                    studentName
            ));
        }

        // 4. CHECK: Duplicate Scan
        boolean alreadyScanned = scanLogRepository.existsByStudentRollNumberAndMealTypeAndScanDateAndStatus(
                rollNumber, mealType.name(), today, "ALLOWED"
        );

        if (alreadyScanned) {
            saveLog(rollNumber, mealType.name(), today, now, "REJECTED - Duplicate Entry", "MESS_ENTRY");
            return ResponseEntity.ok(new ScanResponse(
                    false,
                    "REJECTED",
                    "Entry already recorded! You have already claimed today's " + mealType + ".",
                    studentName
            ));
        }

        // 5. SUCCESS: Entry ALLOWED
        saveLog(rollNumber, mealType.name(), today, now, "ALLOWED", "MESS_ENTRY");

        return ResponseEntity.ok(new ScanResponse(
                true,
                "SUCCESS",
                "Entry Approved for " + mealType + "! Enjoy your meal.",
                studentName
        ));
    }

    // 🎯 MESS EXIT SCAN ENDPOINT
    @PostMapping("/mess/exit")
    public ResponseEntity<ScanResponse> scanMessExit(@RequestBody MessScanRequest request) {
        String rollNumber = request.getStudentRollNumber();
        String mealTypeStr = request.getMealType() != null ? request.getMealType() : "MEAL";

        String studentName = studentRepository.findByRollNumber(rollNumber)
                .map(com.hosteldashboard.hosteldashboard.model.Student::getName)
                .orElse(rollNumber);

        LocalTime now = LocalTime.now();
        LocalDate today = LocalDate.now();
        saveLog(rollNumber, mealTypeStr, today, now, "EXIT_LOGGED", "MESS_EXIT");

        return ResponseEntity.ok(new ScanResponse(
                true,
                "EXIT_ALLOWED",
                "Mess Exit recorded at " + now.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm:ss")) + ".",
                studentName
        ));
    }

    // Saare scan logs dekhne ke liye
    @GetMapping
    public List<ScanLog> getAllScans() {
        return scanLogRepository.findAll();
    }

    // 🎯 Aaj ke mess entries dekhne ke liye (Name, Roll No, Mobile No ke saath)
    @GetMapping("/today")
    public List<java.util.Map<String, Object>> getTodayScans() {
        LocalDate today = LocalDate.now();
        List<ScanLog> logs = scanLogRepository.findAll().stream()
                .filter(l -> today.equals(l.getScanDate()) && "ALLOWED".equalsIgnoreCase(l.getStatus()) && "MESS_ENTRY".equalsIgnoreCase(l.getScanType()))
                .sorted((a, b) -> Long.compare(b.getId() != null ? b.getId() : 0, a.getId() != null ? a.getId() : 0))
                .toList();

        return logs.stream().map(log -> {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", log.getId());
            map.put("rollNumber", log.getStudentRollNumber());
            map.put("mealType", log.getMealType() != null ? log.getMealType() : "MEAL");
            map.put("scanTime", log.getScanTime() != null ? log.getScanTime().split("\\.")[0] : "");
            map.put("scanDate", log.getScanDate() != null ? log.getScanDate().toString() : today.toString());
            map.put("status", log.getStatus());

            studentRepository.findByRollNumber(log.getStudentRollNumber()).ifPresentOrElse(s -> {
                map.put("name", s.getName());
                map.put("mobile", s.getMobile() != null ? s.getMobile() : "");
            }, () -> {
                map.put("name", log.getStudentRollNumber());
                map.put("mobile", "");
            });
            return map;
        }).toList();
    }

    // Helper method
    private void saveLog(String rollNumber, String mealType, LocalDate date, LocalTime time, String status, String scanType) {
        ScanLog log = new ScanLog();
        log.setStudentRollNumber(rollNumber);
        log.setScanType(scanType != null ? scanType : "MESS_ENTRY");
        log.setMealType(mealType);
        log.setScanDate(date);
        log.setScanTime(time.toString());
        log.setStatus(status);
        scanLogRepository.save(log);
    }
}