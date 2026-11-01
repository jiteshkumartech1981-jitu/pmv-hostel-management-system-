package com.hosteldashboard.hosteldashboard.repository;

import com.hosteldashboard.hosteldashboard.model.GatePass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GatePassRepository extends JpaRepository<GatePass, Long> {

    // Student ke saare passes dekhne ke liye (App me history dikhane ke liye)
    List<GatePass> findByStudentRollNumber(String studentRollNumber);

    // Warden ke liye: Sirf "PENDING" passes dekhne ke liye
    List<GatePass> findByStatus(String status);

    // 🎯 GUARD SCAN KE LIYE: Student ka active pass dhoondhna (Jo APPROVED ya OUT ho)
    Optional<GatePass> findFirstByStudentRollNumberAndStatusInOrderByIdDesc(
            String studentRollNumber,
            List<String> statuses
    );
}