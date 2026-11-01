package com.hosteldashboard.hosteldashboard.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"menuDate", "mealType"}))
public class MessMenu {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDate menuDate;

    @Enumerated(EnumType.STRING)
    private MealType mealType;

    @Column(length = 20)
    private String dayOfWeek;

    @Column(length = 500)
    private String items;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public LocalDate getMenuDate() { return menuDate; }
    public void setMenuDate(LocalDate menuDate) { this.menuDate = menuDate; }
    public String getDayOfWeek() { return dayOfWeek; }
    public void setDayOfWeek(String dayOfWeek) { this.dayOfWeek = dayOfWeek; }
    public MealType getMealType() { return mealType; }
    public void setMealType(MealType mealType) { this.mealType = mealType; }
    public String getItems() { return items; }
    public void setItems(String items) { this.items = items; }
}