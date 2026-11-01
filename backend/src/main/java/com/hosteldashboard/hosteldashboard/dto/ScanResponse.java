package com.hosteldashboard.hosteldashboard.dto;

public class ScanResponse {

    private boolean allowed;
    private String status;      // "SUCCESS" ya "REJECTED"
    private String message;     // "Entry Approved" ya "Mess abhi band hai"
    private String studentName; // Student ka naam

    // Default Constructor
    public ScanResponse() {
    }

    // All-args Constructor (Jab hum response create karenge)
    public ScanResponse(boolean allowed, String status, String message, String studentName) {
        this.allowed = allowed;
        this.status = status;
        this.message = message;
        this.studentName = studentName;
    }

    // Getters and Setters
    public boolean isAllowed() {
        return allowed;
    }

    public void setAllowed(boolean allowed) {
        this.allowed = allowed;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }
}