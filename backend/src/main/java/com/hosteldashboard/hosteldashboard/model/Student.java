package com.hosteldashboard.hosteldashboard.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(
        name = "students",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_student_roll_number", columnNames = "roll_number")
        }
)
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "roll_number", nullable = false, length = 30)
    private String rollNumber;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 50)
    private String branch;

    private Integer year;

    @Column(length = 50)
    private String hostel;

    @Column(length = 20)
    private String block;

    @Column(length = 20)
    private String roomNumber;

    @Column(length = 15)
    private String mobile;

    @Column(length = 120)
    private String email;

    @Column(length = 100)
    private String parentName;

    @Column(length = 15)
    private String parentContactNumber;

    @Column(nullable = false)
    private boolean active = true;

    @JsonIgnore
    @Column(name = "password_hash", length = 100)
    private String passwordHash;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getRollNumber() { return rollNumber; }
    public void setRollNumber(String rollNumber) { this.rollNumber = rollNumber; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getBranch() { return branch; }
    public void setBranch(String branch) { this.branch = branch; }

    public Integer getYear() { return year; }
    public void setYear(Integer year) { this.year = year; }

    public String getHostel() { return hostel; }
    public void setHostel(String hostel) { this.hostel = hostel; }

    public String getBlock() { return block; }
    public void setBlock(String block) { this.block = block; }

    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getParentName() { return parentName; }
    public void setParentName(String parentName) { this.parentName = parentName; }

    public String getParentContactNumber() { return parentContactNumber; }
    public void setParentContactNumber(String parentContactNumber) { this.parentContactNumber = parentContactNumber; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
}
