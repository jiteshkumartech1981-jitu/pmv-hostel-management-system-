package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.dto.GatePassScanRequest;
import com.hosteldashboard.hosteldashboard.dto.ScanResponse;
import com.hosteldashboard.hosteldashboard.model.GatePass;
import com.hosteldashboard.hosteldashboard.repository.GatePassRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/gatepass")
public class GatePassController {

    private final GatePassRepository gatePassRepository;
    private final com.hosteldashboard.hosteldashboard.service.SmsService smsService;
    private final com.hosteldashboard.hosteldashboard.repository.StudentRepository studentRepository;
    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public GatePassController(GatePassRepository gatePassRepository,
                              com.hosteldashboard.hosteldashboard.service.SmsService smsService,
                              com.hosteldashboard.hosteldashboard.repository.StudentRepository studentRepository) {
        this.gatePassRepository = gatePassRepository;
        this.smsService = smsService;
        this.studentRepository = studentRepository;
    }

    // 1. Student applies for Gate Pass
    @PostMapping
    public ResponseEntity<?> createGatePass(@RequestBody GatePass gatePass) {
        if (gatePass.getStudentRollNumber() == null || gatePass.getStudentRollNumber().isBlank()) {
            return ResponseEntity.badRequest().body("Student Roll Number is required.");
        }

        // Rule: Only Saturday and Sunday allowed
        java.time.DayOfWeek day = java.time.LocalDate.now().getDayOfWeek();
        boolean isWeekend = (day == java.time.DayOfWeek.SATURDAY || day == java.time.DayOfWeek.SUNDAY);
        // If not weekend, check if reason indicates emergency
        String reason = gatePass.getReason() != null ? gatePass.getReason() : "";
        if (!isWeekend && !reason.toLowerCase().contains("emergency")) {
            return ResponseEntity.badRequest().body(
                    "Gate pass is only permitted on Saturday and Sunday. For emergency leave, contact Hostel Director Vijay Rana directly at 7015821282."
            );
        }

        // Rule: Max outing until 17:00 (5:00 PM)
        String returnTime = gatePass.getExpectedReturnTime();
        if (returnTime != null && returnTime.matches("^\\d{1,2}:\\d{2}$")) {
            String[] parts = returnTime.split(":");
            int hour = Integer.parseInt(parts[0]);
            int min = Integer.parseInt(parts[1]);
            if (hour > 17 || (hour == 17 && min > 0)) {
                return ResponseEntity.badRequest().body(
                        "Expected return time cannot be later than 05:00 PM (17:00). Please adjust your return time."
                );
            }
        }

        if (gatePass.getStatus() == null || gatePass.getStatus().isEmpty()) {
            gatePass.setStatus("PENDING");
        }
        return ResponseEntity.ok(gatePassRepository.save(gatePass));
    }

    // Student's own passes
    @GetMapping("/my")
    public List<GatePass> myGatePasses(Authentication authentication) {
        return gatePassRepository.findByStudentRollNumber(authentication.getName());
    }

    // Get active/latest status of gate pass for a student (Used by Mobile App & Guard)
    @GetMapping("/status/{rollNumber}")
    public ResponseEntity<?> getGatePassStatus(@PathVariable String rollNumber) {
        Optional<GatePass> passOpt = gatePassRepository.findFirstByStudentRollNumberAndStatusInOrderByIdDesc(
                rollNumber.trim().toUpperCase(),
                List.of("APPROVED", "OUT", "PENDING")
        );
        if (passOpt.isPresent()) {
            return ResponseEntity.ok(passOpt.get());
        }
        // Fallback to latest pass regardless of status
        List<GatePass> allStudentPasses = gatePassRepository.findByStudentRollNumber(rollNumber.trim().toUpperCase());
        if (!allStudentPasses.isEmpty()) {
            return ResponseEntity.ok(allStudentPasses.get(allStudentPasses.size() - 1));
        }
        return ResponseEntity.notFound().build();
    }

    // 2. Director: View All Passes
    @GetMapping
    public List<GatePass> getAllGatePasses() {
        return gatePassRepository.findAll();
    }

    // 3. Director: View Pending passes
    @GetMapping("/pending")
    public List<GatePass> getPendingGatePasses() {
        return gatePassRepository.findByStatus("PENDING");
    }

    // 🎯 Approved & Active Gate Passes for Staff Portal (Student Name, Roll No, Mobile No)
    @GetMapping("/approved/today")
    public List<java.util.Map<String, Object>> getTodayApprovedPasses() {
        List<GatePass> passes = gatePassRepository.findAll().stream()
                .filter(p -> "APPROVED".equalsIgnoreCase(p.getStatus())
                          || "OUT".equalsIgnoreCase(p.getStatus())
                          || "RETURNED".equalsIgnoreCase(p.getStatus()))
                .sorted((a, b) -> Long.compare(b.getId() != null ? b.getId() : 0, a.getId() != null ? a.getId() : 0))
                .toList();

        return passes.stream().map(p -> {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", p.getId());
            map.put("studentName", p.getStudentName());
            map.put("studentRollNumber", p.getStudentRollNumber());
            map.put("reason", p.getReason());
            map.put("exitTime", p.getExitTime());
            map.put("expectedReturnTime", p.getExpectedReturnTime());
            map.put("actualExitTime", p.getActualExitTime());
            map.put("actualReturnTime", p.getActualReturnTime());
            map.put("status", p.getStatus());

            String roll = p.getStudentRollNumber();
            if (roll != null && !roll.isBlank()) {
                studentRepository.findByRollNumber(roll.trim().toUpperCase()).ifPresentOrElse(s -> {
                    map.put("mobile", s.getMobile() != null ? s.getMobile() : (p.getParentPhone() != null ? p.getParentPhone() : ""));
                    if (map.get("studentName") == null || ((String)map.get("studentName")).isBlank()) {
                        map.put("studentName", s.getName());
                    }
                }, () -> {
                    map.put("mobile", p.getParentPhone() != null ? p.getParentPhone() : "");
                });
            } else {
                map.put("mobile", p.getParentPhone() != null ? p.getParentPhone() : "");
            }
            return map;
        }).toList();
    }

    // 4. Director: Approve Pass (Supports both POST and PUT)
    @RequestMapping(value = "/{id}/approve", method = {RequestMethod.POST, RequestMethod.PUT})
    public GatePass approveGatePass(@PathVariable Long id) {
        GatePass gatePass = gatePassRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Gate Pass not found with id: " + id));
        gatePass.setStatus("APPROVED");
        return gatePassRepository.save(gatePass);
    }

    // 5. Director: Reject Pass (Supports both POST and PUT)
    @RequestMapping(value = "/{id}/reject", method = {RequestMethod.POST, RequestMethod.PUT})
    public GatePass rejectGatePass(@PathVariable Long id) {
        GatePass gatePass = gatePassRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Gate Pass not found with id: " + id));
        gatePass.setStatus("REJECTED");
        return gatePassRepository.save(gatePass);
    }

    // 🎯 6. GUARD SCAN ENDPOINT (Main Gate QR Scanner)
    @PostMapping("/scan")
    public ResponseEntity<ScanResponse> scanGatePass(@RequestBody GatePassScanRequest request) {
        String rollNumber = request.getStudentRollNumber();

        if (rollNumber == null || rollNumber.isEmpty()) {
            return ResponseEntity.badRequest().body(new ScanResponse(
                    false, "REJECTED", "Student Roll Number is required.", null
            ));
        }

        Optional<GatePass> passOpt = gatePassRepository.findFirstByStudentRollNumberAndStatusInOrderByIdDesc(
                rollNumber.trim().toUpperCase(),
                List.of("APPROVED", "OUT")
        );

        if (passOpt.isEmpty()) {
            return ResponseEntity.ok(new ScanResponse(
                    false,
                    "REJECTED",
                    "No approved gate pass found. Campus exit is not permitted.",
                    rollNumber
            ));
        }

        GatePass pass = passOpt.get();
        String currentTime = LocalDateTime.now().format(formatter);

        // CASE A: Student EXITING through main gate (First Scan)
        if ("APPROVED".equalsIgnoreCase(pass.getStatus())) {
            pass.setStatus("OUT");
            pass.setActualExitTime(currentTime);
            gatePassRepository.save(pass);

            return ResponseEntity.ok(new ScanResponse(
                    true,
                    "EXIT_ALLOWED",
                    "Gate Pass Verified! Campus exit allowed. Please return to hostel before 05:00 PM.",
                    pass.getStudentName()
            ));
        }

        // CASE B: Student RETURNING through main gate (Second Scan)
        if ("OUT".equalsIgnoreCase(pass.getStatus())) {
            pass.setStatus("RETURNED");
            pass.setActualReturnTime(currentTime);
            gatePassRepository.save(pass);

            return ResponseEntity.ok(new ScanResponse(
                    true,
                    "ENTRY_ALLOWED",
                    "Welcome Back! Campus entry allowed. Return recorded at " + currentTime + ".",
                    pass.getStudentName()
            ));
        }

        return ResponseEntity.ok(new ScanResponse(
                false, "REJECTED", "Invalid Gate Pass State.", pass.getStudentName()
        ));
    }
}