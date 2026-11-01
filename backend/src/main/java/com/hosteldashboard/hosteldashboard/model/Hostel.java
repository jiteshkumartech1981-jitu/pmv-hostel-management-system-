package com.hosteldashboard.hosteldashboard.model;

import jakarta.persistence.*;

@Entity
@Table(
        name = "hostels",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_hostel_name", columnNames = "name")
        }
)
public class Hostel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    // BOYS ya GIRLS
    @Column(nullable = false, length = 10)
    private String type;

    @Column(nullable = false)
    private boolean active = true;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}