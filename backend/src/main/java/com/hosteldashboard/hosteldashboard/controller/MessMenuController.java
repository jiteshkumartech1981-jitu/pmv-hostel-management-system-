package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.model.MessMenu;
import com.hosteldashboard.hosteldashboard.repository.MessMenuRepository;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/mess-menu")
public class MessMenuController {

    private final MessMenuRepository repository;

    public MessMenuController(MessMenuRepository repository) {
        this.repository = repository;
    }

    // Get menu by date or all menus
    @GetMapping
    public List<MessMenu> getMenu(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        if (date != null) {
            List<MessMenu> list = repository.findByMenuDate(date);
            if (!list.isEmpty()) return list;
            // Fallback to day of week menu for this date
            return repository.findByDayOfWeek(date.getDayOfWeek().name());
        }
        return repository.findAll();
    }

    // Get today's menu: checks specific date first, then falls back to today's day-of-week
    @GetMapping("/today")
    public List<MessMenu> getTodayMenu() {
        LocalDate today = LocalDate.now();
        List<MessMenu> list = repository.findByMenuDate(today);
        if (!list.isEmpty()) {
            return list;
        }
        // Fallback to recurring weekly schedule for today's day of week
        String todayDayOfWeek = today.getDayOfWeek().name();
        List<MessMenu> dayList = repository.findByDayOfWeek(todayDayOfWeek);
        if (!dayList.isEmpty()) {
            return dayList;
        }
        // Last fallback: latest available entries
        List<MessMenu> all = repository.findAll();
        if (all.isEmpty()) return List.of();
        return all.subList(0, Math.min(4, all.size()));
    }

    // Get menu for a specific day of the week (e.g. MONDAY, TUESDAY)
    @GetMapping("/day")
    public List<MessMenu> getMenuByDay(@RequestParam String day) {
        return repository.findByDayOfWeek(day.trim().toUpperCase());
    }

    // Get full recurring weekly timetable
    @GetMapping("/weekly")
    public List<MessMenu> getWeeklyMenu() {
        return repository.findAll().stream()
                .filter(m -> m.getDayOfWeek() != null && !m.getDayOfWeek().isBlank())
                .toList();
    }

    // Admin creates or updates menu (by date or by day of week)
    @PostMapping
    public ResponseEntity<?> add(@RequestBody MessMenu menu) {
        if (menu.getMealType() == null || menu.getItems() == null || menu.getItems().isBlank()) {
            return ResponseEntity.badRequest().body("mealType and items are required.");
        }

        if (menu.getDayOfWeek() != null && !menu.getDayOfWeek().isBlank()) {
            String day = menu.getDayOfWeek().trim().toUpperCase();
            menu.setDayOfWeek(day);
            Optional<MessMenu> existing = repository.findByDayOfWeekAndMealType(day, menu.getMealType());
            if (existing.isPresent()) {
                MessMenu m = existing.get();
                m.setItems(menu.getItems());
                return ResponseEntity.ok(repository.save(m));
            }
            return ResponseEntity.ok(repository.save(menu));
        }

        if (menu.getMenuDate() != null) {
            Optional<MessMenu> existing = repository.findByMenuDateAndMealType(menu.getMenuDate(), menu.getMealType());
            if (existing.isPresent()) {
                MessMenu m = existing.get();
                m.setItems(menu.getItems());
                return ResponseEntity.ok(repository.save(m));
            }
            return ResponseEntity.ok(repository.save(menu));
        }

        return ResponseEntity.badRequest().body("Either menuDate or dayOfWeek must be specified.");
    }

    // Admin updates an existing menu item by ID
    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody MessMenu updated) {
        return repository.findById(id).map(existing -> {
            if (updated.getItems() == null || updated.getItems().isBlank()) {
                return ResponseEntity.badRequest().body("Items cannot be empty.");
            }
            existing.setItems(updated.getItems());
            if (updated.getDayOfWeek() != null) existing.setDayOfWeek(updated.getDayOfWeek().trim().toUpperCase());
            return ResponseEntity.ok(repository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }
}