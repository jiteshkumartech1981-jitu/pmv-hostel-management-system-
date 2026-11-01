package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.model.Complaint;
import com.hosteldashboard.hosteldashboard.repository.ComplaintRepository;
import com.hosteldashboard.hosteldashboard.repository.StudentRepository;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/complaints")
public class ComplaintController {

    private final ComplaintRepository complaintRepository;
    private final StudentRepository studentRepository;
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final String UPLOAD_DIR = "uploads/complaint_videos";

    public ComplaintController(ComplaintRepository complaintRepository, StudentRepository studentRepository) {
        this.complaintRepository = complaintRepository;
        this.studentRepository = studentRepository;
    }

    /**
     * Upload a short 20-second complaint video proof.
     */
    @PostMapping(value = "/upload-video", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadVideo(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "No video file was uploaded."));
        }

        try {
            Path uploadPath = Paths.get(UPLOAD_DIR);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String originalName = file.getOriginalFilename();
            String extension = ".mp4";
            if (originalName != null && originalName.lastIndexOf('.') != -1) {
                extension = originalName.substring(originalName.lastIndexOf('.'));
            }

            String fileName = "complaint_video_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + extension;
            Path filePath = uploadPath.resolve(fileName);
            Files.copy(file.getInputStream(), filePath);

            String videoUrl = "/api/complaints/video/" + fileName;
            return ResponseEntity.ok(Map.of("videoUrl", videoUrl, "fileName", fileName));
        } catch (IOException e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to store video: " + e.getMessage()));
        }
    }

    /**
     * Stream or download the complaint video proof.
     * When accessed by staff/admin, marks videoViewedAt timestamp so it auto-deletes in 1-2 days.
     */
    @GetMapping("/video/{fileName:.+}")
    public ResponseEntity<Resource> streamVideo(@PathVariable String fileName) {
        try {
            Path filePath = Paths.get(UPLOAD_DIR).resolve(fileName).normalize();
            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }

            Resource resource = new UrlResource(filePath.toUri());
            if (!resource.exists() || !resource.isReadable()) {
                return ResponseEntity.notFound().build();
            }

            // Mark complaint as viewed if not already marked
            String targetUrl = "/api/complaints/video/" + fileName;
            complaintRepository.findAll().stream()
                    .filter(c -> c.getVideoUrl() != null && c.getVideoUrl().endsWith(fileName))
                    .findFirst()
                    .ifPresent(c -> {
                        if (c.getVideoViewedAt() == null) {
                            c.setVideoViewedAt(LocalDateTime.now());
                            complaintRepository.save(c);
                        }
                    });

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType("video/mp4"))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + fileName + "\"")
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping
    public Complaint addComplaint(@RequestBody Complaint complaint, Authentication authentication) {
        complaint.setStatus("Submitted");
        if ((complaint.getStudentRollNumber() == null || complaint.getStudentRollNumber().isBlank()) && authentication != null) {
            complaint.setStudentRollNumber(authentication.getName());
        }
        if (complaint.getCreatedAt() == null || complaint.getCreatedAt().isBlank()) {
            complaint.setCreatedAt(LocalDateTime.now().format(FORMATTER));
        }
        if (complaint.getVideoUrl() != null && !complaint.getVideoUrl().isBlank()) {
            complaint.setVideoDeleted(false);
            complaint.setVideoViewedAt(null);
        }

        // Auto-fill student name and mobile if missing
        if (complaint.getStudentRollNumber() != null && !complaint.getStudentRollNumber().isBlank()) {
            studentRepository.findByRollNumber(complaint.getStudentRollNumber().trim().toUpperCase()).ifPresent(s -> {
                if (complaint.getStudentName() == null || complaint.getStudentName().isBlank()) {
                    complaint.setStudentName(s.getName());
                }
                if (complaint.getStudentMobile() == null || complaint.getStudentMobile().isBlank()) {
                    complaint.setStudentMobile(s.getMobile());
                }
            });
        }
        return complaintRepository.save(complaint);
    }

    @GetMapping("/my")
    public List<Complaint> myComplaints(@RequestParam(required = false) String rollNumber, Authentication authentication) {
        String roll = (rollNumber != null && !rollNumber.isBlank()) ? rollNumber : (authentication != null ? authentication.getName() : null);
        if (roll == null) {
            return List.of();
        }
        return complaintRepository.findByStudentRollNumber(roll.trim().toUpperCase());
    }

    @GetMapping
    public List<Complaint> getAllComplaints() {
        List<Complaint> all = complaintRepository.findAll();
        // Enrich any older complaints where name or mobile was null
        for (Complaint c : all) {
            if ((c.getStudentMobile() == null || c.getStudentName() == null) && c.getStudentRollNumber() != null) {
                studentRepository.findByRollNumber(c.getStudentRollNumber().trim().toUpperCase()).ifPresent(s -> {
                    if (c.getStudentName() == null || c.getStudentName().isBlank()) c.setStudentName(s.getName());
                    if (c.getStudentMobile() == null || c.getStudentMobile().isBlank()) c.setStudentMobile(s.getMobile());
                });
            }
        }
        // Return latest first
        return all.stream().sorted((a, b) -> Long.compare(b.getId() != null ? b.getId() : 0, a.getId() != null ? a.getId() : 0)).toList();
    }

    @RequestMapping(value = "/{id}/status", method = {RequestMethod.POST, RequestMethod.PUT})
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        String newStatus = body.get("status");
        if (newStatus == null || newStatus.isBlank()) {
            newStatus = "Resolved";
        }
        final String finalStatus = newStatus;
        return complaintRepository.findById(id).map(c -> {
            c.setStatus(finalStatus);
            return ResponseEntity.ok(complaintRepository.save(c));
        }).orElse(ResponseEntity.notFound().build());
    }
}
