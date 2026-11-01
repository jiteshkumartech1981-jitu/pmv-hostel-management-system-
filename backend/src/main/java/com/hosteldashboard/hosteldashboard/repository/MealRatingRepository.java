package com.hosteldashboard.hosteldashboard.repository;

import com.hosteldashboard.hosteldashboard.model.MealRating;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MealRatingRepository extends JpaRepository<MealRating, Long> {
    List<MealRating> findByMenuId(Long menuId);
    Optional<MealRating> findByMenuIdAndStudentRollNumber(Long menuId, String studentRollNumber);
}