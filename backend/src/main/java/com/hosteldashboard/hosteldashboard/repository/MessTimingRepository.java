package com.hosteldashboard.hosteldashboard.repository;

import com.hosteldashboard.hosteldashboard.model.MealType;
import com.hosteldashboard.hosteldashboard.model.MessTiming;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface MessTimingRepository extends JpaRepository<MessTiming, Long> {
    Optional<MessTiming> findByMealType(MealType mealType);
}