package com.hosteldashboard.hosteldashboard.service;

import com.hosteldashboard.hosteldashboard.model.Complaint;
import com.hosteldashboard.hosteldashboard.repository.ComplaintRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class ComplaintVideoCleanupService {

    private static final Logger log = LoggerFactory.getLogger(ComplaintVideoCleanupService.class);
    private final ComplaintRepository complaintRepository;

    public ComplaintVideoCleanupService(ComplaintRepository complaintRepository) {
        this.complaintRepository = complaintRepository;
    }

    /**
     * Runs every 30 minutes.
     * Auto-deletes complaint videos after they have been viewed by admin for 24 hours (1 to 2 days).
     */
    @Scheduled(fixedRate = 1800000)
    public void cleanupViewedVideos() {
        try {
            List<Complaint> complaints = complaintRepository.findAll();
            LocalDateTime cutoff = LocalDateTime.now().minusHours(24);

            for (Complaint c : complaints) {
                if (c.getVideoUrl() != null && !Boolean.TRUE.equals(c.getVideoDeleted())) {
                    boolean shouldDelete = false;
                    // Auto-delete if reviewed by admin > 24 hours ago
                    if (c.getVideoViewedAt() != null && c.getVideoViewedAt().isBefore(cutoff)) {
                        shouldDelete = true;
                        log.info("Auto-deleting complaint video #{} - viewed at {}", c.getId(), c.getVideoViewedAt());
                    }

                    if (shouldDelete) {
                        deleteVideoFile(c);
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error during complaint video cleanup: {}", e.getMessage());
        }
    }

    private void deleteVideoFile(Complaint c) {
        try {
            String url = c.getVideoUrl();
            if (url != null && url.contains("/api/complaints/video/")) {
                String fileName = url.substring(url.lastIndexOf('/') + 1);
                Path path = Paths.get("uploads/complaint_videos").resolve(fileName).normalize();
                if (Files.exists(path)) {
                    Files.delete(path);
                    log.info("Successfully deleted video file: {}", fileName);
                }
            }
        } catch (IOException ex) {
            log.warn("Could not delete file for complaint {}: {}", c.getId(), ex.getMessage());
        } finally {
            c.setVideoDeleted(true);
            c.setVideoUrl(null);
            complaintRepository.save(c);
        }
    }
}
