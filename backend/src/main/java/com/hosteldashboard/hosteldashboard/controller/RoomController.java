package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.model.Room;
import com.hosteldashboard.hosteldashboard.repository.RoomRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
public class RoomController {

    private final RoomRepository roomRepository;

    public RoomController(RoomRepository roomRepository) {
        this.roomRepository = roomRepository;
    }

    @PostMapping
    public Room addRoom(@RequestBody Room room) {
        return roomRepository.save(room);
    }

    @GetMapping
    public List<Room> getAllRooms(@RequestParam(required = false) Long hostelId) {
        if (hostelId != null) {
            return roomRepository.findByHostelId(hostelId);
        }
        return roomRepository.findAll();
    }
}