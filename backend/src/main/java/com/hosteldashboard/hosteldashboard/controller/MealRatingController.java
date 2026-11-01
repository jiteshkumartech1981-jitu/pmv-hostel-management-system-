package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.model.MealRating;
import com.hosteldashboard.hosteldashboard.repository.MealRatingRepository;
import com.hosteldashboard.hosteldashboard.repository.MessMenuRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/meal-rating")
public class MealRatingController {

    private final MealRatingRepository ratingRepository;
    private final MessMenuRepository menuRepository;

    public MealRatingController(MealRatingRepository ratingRepository,
                                MessMenuRepository menuRepository) {
        this.ratingRepository = ratingRepository;
        this.menuRepository = menuRepository;
    }

    // Student rating dega
    @PostMapping
    public ResponseEntity<?> addRating(@RequestBody MealRating rating) {
        if (rating.getMenuId() == null || rating.getStudentRollNumber() == null
                || rating.getStudentRollNumber().isBlank()) {
            return ResponseEntity.badRequest().body("menuId and studentRollNumber are required.");
        }
        if (rating.getRating() < 1 || rating.getRating() > 5) {
            return ResponseEntity.badRequest().body("Rating must be between 1 and 5.");
        }
        if (!menuRepository.existsById(rating.getMenuId())) {
            return ResponseEntity.badRequest().body("Menu item not found for the given menuId.");
        }
        Optional<MealRating> existingOpt = ratingRepository.findByMenuIdAndStudentRollNumber(
                rating.getMenuId(), rating.getStudentRollNumber());
        if (existingOpt.isPresent()) {
            MealRating existing = existingOpt.get();
            existing.setRating(rating.getRating());
            return ResponseEntity.ok(ratingRepository.save(existing));
        }
        return ResponseEntity.ok(ratingRepository.save(rating));
    }

    // Saari ratings dekho. ?menuId=1 doge to sirf us menu ki
    @GetMapping
    public List<MealRating> getRatings(@RequestParam(required = false) Long menuId) {
        if (menuId != null) {
            return ratingRepository.findByMenuId(menuId);
        }
        return ratingRepository.findAll();
    }

    // Kisi menu ki average rating
    @GetMapping("/average/{menuId}")
    public Map<String, Object> getAverage(@PathVariable Long menuId) {
        List<MealRating> ratings = ratingRepository.findByMenuId(menuId);
        double average = ratings.stream().mapToInt(MealRating::getRating).average().orElse(0.0);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("menuId", menuId);
        result.put("averageRating", average);
        result.put("totalRatings", ratings.size());
        return result;
    }
}