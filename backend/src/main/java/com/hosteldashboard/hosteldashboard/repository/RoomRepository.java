package com.hosteldashboard.hosteldashboard.repository;

import com.hosteldashboard.hosteldashboard.model.Room;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RoomRepository extends JpaRepository<Room, Long> {
    List<Room> findByHostelId(Long hostelId);
}