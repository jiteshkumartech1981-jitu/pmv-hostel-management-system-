package com.hosteldashboard.hosteldashboard.dto;

public class GatePassScanRequest {

    private String studentRollNumber;

    public GatePassScanRequest() {
    }

    public GatePassScanRequest(String studentRollNumber) {
        this.studentRollNumber = studentRollNumber;
    }

    public String getStudentRollNumber() {
        return studentRollNumber;
    }

    public void setStudentRollNumber(String studentRollNumber) {
        this.studentRollNumber = studentRollNumber;
    }
}