package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.model.MessTiming;
import com.hosteldashboard.hosteldashboard.repository.MessTimingRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/mess-timing")
public class MessTimingController {

    private final MessTimingRepository repository;

    public MessTimingController(MessTimingRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<MessTiming> getAll() {
        return repository.findAll();
    }

    @PostMapping
    public ResponseEntity<?> add(@RequestBody MessTiming timing) {
        if (timing.getMealType() == null || timing.getStartTime() == null || timing.getEndTime() == null) {
            return ResponseEntity.badRequest().body("mealType, startTime, and endTime are all required.");
        }
        if (!timing.getStartTime().isBefore(timing.getEndTime())) {
            return ResponseEntity.badRequest().body("startTime must be before endTime.");
        }
        if (repository.findByMealType(timing.getMealType()).isPresent()) {
            return ResponseEntity.badRequest().body("Timing already exists for this meal type. Use PUT to update.");
        }
        return ResponseEntity.ok(repository.save(timing));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody MessTiming updated) {
        return repository.findById(id).map(existing -> {
            if (updated.getStartTime() == null || updated.getEndTime() == null
                    || !updated.getStartTime().isBefore(updated.getEndTime())) {
                return ResponseEntity.badRequest().body("Valid startTime and endTime required. startTime must be before endTime.");
            }
            existing.setStartTime(updated.getStartTime());
            existing.setEndTime(updated.getEndTime());
            return ResponseEntity.ok(repository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }
}