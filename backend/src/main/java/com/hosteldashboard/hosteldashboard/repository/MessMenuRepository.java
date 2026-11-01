package com.hosteldashboard.hosteldashboard.repository;

import com.hosteldashboard.hosteldashboard.model.MealType;
import com.hosteldashboard.hosteldashboard.model.MessMenu;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MessMenuRepository extends JpaRepository<MessMenu, Long> {
    List<MessMenu> findByMenuDate(LocalDate menuDate);
    Optional<MessMenu> findByMenuDateAndMealType(LocalDate menuDate, MealType mealType);
    List<MessMenu> findByDayOfWeek(String dayOfWeek);
    Optional<MessMenu> findByDayOfWeekAndMealType(String dayOfWeek, MealType mealType);
}