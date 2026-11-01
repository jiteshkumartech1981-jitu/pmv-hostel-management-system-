package com.hosteldashboard.hosteldashboard.controller;

import com.hosteldashboard.hosteldashboard.model.Hostel;
import com.hosteldashboard.hosteldashboard.repository.HostelRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/hostels")
public class HostelController {

    private final HostelRepository hostelRepository;

    public HostelController(HostelRepository hostelRepository) {
        this.hostelRepository = hostelRepository;
    }

    @PostMapping
    public Hostel addHostel(@RequestBody Hostel hostel) {
        return hostelRepository.save(hostel);
    }

    @GetMapping
    public List<Hostel> getAllHostels() {
        return hostelRepository.findAll();
    }
}