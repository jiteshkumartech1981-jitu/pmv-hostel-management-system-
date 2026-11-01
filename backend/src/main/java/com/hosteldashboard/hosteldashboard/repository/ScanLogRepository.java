package com.hosteldashboard.hosteldashboard.repository;

import com.hosteldashboard.hosteldashboard.model.ScanLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;

@Repository
public interface ScanLogRepository extends JpaRepository<ScanLog, Long> {

    // Ye check karega ki kya student ne aaj ye meal le liya hai aur ALLOWED ho chuka hai
    boolean existsByStudentRollNumberAndMealTypeAndScanDateAndStatus(
            String studentRollNumber,
            String mealType,
            LocalDate scanDate,
            String status
    );
}