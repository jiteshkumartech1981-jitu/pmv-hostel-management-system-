package com.hosteldashboard.hosteldashboard.dto;

public record LoginResponse(
        String token,
        String username,
        String role,
        String name,
        String rollNumber,
        String hostel,
        String roomNumber,
        String branch,
        Integer year,
        String mobile,
        String parentContactNumber
) {
    public LoginResponse(String token, String username, String role, String name, String rollNumber, String hostel, String roomNumber) {
        this(token, username, role, name, rollNumber, hostel, roomNumber, null, null, null, null);
    }
}
