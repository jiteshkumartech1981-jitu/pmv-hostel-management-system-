package com.hosteldashboard.hosteldashboard.dto;

public class MessScanRequest {

    private String studentRollNumber;
    private String mealType; // BREAKFAST, LUNCH, SNACKS, DINNER

    public MessScanRequest() {
    }

    public MessScanRequest(String studentRollNumber, String mealType) {
        this.studentRollNumber = studentRollNumber;
        this.mealType = mealType;
    }

    public String getStudentRollNumber() {
        return studentRollNumber;
    }

    public void setStudentRollNumber(String studentRollNumber) {
        this.studentRollNumber = studentRollNumber;
    }

    public String getMealType() {
        return mealType;
    }

    public void setMealType(String mealType) {
        this.mealType = mealType;
    }
}


