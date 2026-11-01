package com.hosteldashboard.hosteldashboard.config;

import com.hosteldashboard.hosteldashboard.model.MealType;
import com.hosteldashboard.hosteldashboard.model.MessMenu;
import com.hosteldashboard.hosteldashboard.model.MessTiming;
import com.hosteldashboard.hosteldashboard.model.Role;
import com.hosteldashboard.hosteldashboard.model.Staff;
import com.hosteldashboard.hosteldashboard.model.Student;
import com.hosteldashboard.hosteldashboard.repository.MessMenuRepository;
import com.hosteldashboard.hosteldashboard.repository.MessTimingRepository;
import com.hosteldashboard.hosteldashboard.repository.StaffRepository;
import com.hosteldashboard.hosteldashboard.repository.StudentRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalTime;

@Component
public class DemoDataSeeder implements CommandLineRunner {

    private final StaffRepository staffRepository;
    private final StudentRepository studentRepository;
    private final MessTimingRepository messTimingRepository;
    private final MessMenuRepository messMenuRepository;
    private final PasswordEncoder passwordEncoder;

    public DemoDataSeeder(StaffRepository staffRepository,
                          StudentRepository studentRepository,
                          MessTimingRepository messTimingRepository,
                          MessMenuRepository messMenuRepository,
                          PasswordEncoder passwordEncoder) {
        this.staffRepository = staffRepository;
        this.studentRepository = studentRepository;
        this.messTimingRepository = messTimingRepository;
        this.messMenuRepository = messMenuRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        seedStaff("superadmin", "Admin@12345", "Jitesh Kumar", Role.SUPER_ADMIN, "9876543210");
        seedStaff("messadmin", "Admin@12345", "Jitesh Kumar", Role.MESS_ADMIN, "9876543210");
        seedStaff("director1", "Admin@12345", "Vijay Rana", Role.DIRECTOR, "9876543211");
        seedStaff("guard", "guard1234", "Gate Guard", Role.GUARD, "9876543211");
        seedDemoStudent();
        seedTimings();
        seedWeeklyMenu();
        System.out.println("PMV Hostel Management ready: Director: Vijay Rana (9876543211) | Mess Admin: Jitesh Kumar (9876543210)");
    }

    private void seedStaff(String username, String password, String fullName, Role role, String mobile) {
        Staff staff = staffRepository.findByUsername(username).orElseGet(Staff::new);
        staff.setUsername(username);
        staff.setPasswordHash(passwordEncoder.encode(password));
        staff.setFullName(fullName);
        staff.setRole(role);
        staff.setMobile(mobile);
        staff.setActive(true);
        staffRepository.save(staff);
    }

    private void seedDemoStudent() {
        Student student = studentRepository.findByRollNumber("21CS101").orElseGet(Student::new);
        student.setRollNumber("21CS101");
        student.setName("Rahul Sharma");
        student.setBranch("CSE");
        student.setYear(3);
        student.setHostel("Boys Hostel");
        student.setBlock("Block 1");
        student.setRoomNumber("204");
        student.setMobile("9876543210");
        student.setParentName("Mr Sharma");
        student.setParentContactNumber("9876543210");
        student.setActive(true);
        student.setPasswordHash(passwordEncoder.encode("student123"));
        studentRepository.save(student);
    }

    private void seedTimings() {
        addTiming(MealType.BREAKFAST, LocalTime.of(8, 0), LocalTime.of(9, 30));
        addTiming(MealType.LUNCH, LocalTime.of(12, 15), LocalTime.of(14, 15));
        addTiming(MealType.SNACK, LocalTime.of(17, 0), LocalTime.of(18, 0));
        addTiming(MealType.DINNER, LocalTime.of(19, 30), LocalTime.of(21, 30));
    }

    private void addTiming(MealType mealType, LocalTime start, LocalTime end) {
        MessTiming timing = messTimingRepository.findByMealType(mealType).orElseGet(MessTiming::new);
        timing.setMealType(mealType);
        timing.setStartTime(start);
        timing.setEndTime(end);
        messTimingRepository.save(timing);
    }

    private void seedWeeklyMenu() {
        addDayMenu("MONDAY", MealType.BREAKFAST, "Parantha, Curd & Tea");
        addDayMenu("MONDAY", MealType.LUNCH, "Roti, Chawal, Dal, Kadu Sabzi, Raita");
        addDayMenu("MONDAY", MealType.SNACK, "Pakoda, Tea");
        addDayMenu("MONDAY", MealType.DINNER, "Roti, Chawal, Dal, Aloo Gobhi Sabzi");

        addDayMenu("TUESDAY", MealType.BREAKFAST, "Milk and Banana");
        addDayMenu("TUESDAY", MealType.LUNCH, "Kadi, Chawal, Sabzi, Salad");
        addDayMenu("TUESDAY", MealType.SNACK, "Rusk, Tea");
        addDayMenu("TUESDAY", MealType.DINNER, "Roti, Kheer, Aloo Chana Sabzi");

        addDayMenu("WEDNESDAY", MealType.BREAKFAST, "Pasta");
        addDayMenu("WEDNESDAY", MealType.LUNCH, "Roti, Chawal, Lauki Sabzi, Raita");
        addDayMenu("WEDNESDAY", MealType.SNACK, "Fried Rice, Tea");
        addDayMenu("WEDNESDAY", MealType.DINNER, "Roti, Chawal, Dal, Soya Chaap Sabzi");

        addDayMenu("THURSDAY", MealType.BREAKFAST, "Poha");
        addDayMenu("THURSDAY", MealType.LUNCH, "Roti, Chawal, Bhindi Sabzi, Raita");
        addDayMenu("THURSDAY", MealType.SNACK, "Manchurian, Tea");
        addDayMenu("THURSDAY", MealType.DINNER, "Roti, Chawal, Dal, Bhindi Sabzi");

        addDayMenu("FRIDAY", MealType.BREAKFAST, "Masala Chana");
        addDayMenu("FRIDAY", MealType.LUNCH, "Puri, Sabzi, Halwa, Raita, Salad");
        addDayMenu("FRIDAY", MealType.SNACK, "Fried Beaten Rice, Tea");
        addDayMenu("FRIDAY", MealType.DINNER, "Roti, Chawal, Chicken Curry, Paneer Curry");

        addDayMenu("SATURDAY", MealType.BREAKFAST, "Khichdi");
        addDayMenu("SATURDAY", MealType.LUNCH, "Roti, Chawal, Aloo Palak, Raita");
        addDayMenu("SATURDAY", MealType.SNACK, "Matthi, Tea");
        addDayMenu("SATURDAY", MealType.DINNER, "Roti, Chawal, Dal, Aloo Soyabean Sabzi");

        addDayMenu("SUNDAY", MealType.BREAKFAST, "Idly or Pasta");
        addDayMenu("SUNDAY", MealType.LUNCH, "Chole, Bhature");
        addDayMenu("SUNDAY", MealType.SNACK, "Noodles, Tea");
        addDayMenu("SUNDAY", MealType.DINNER, "Roti, Chawal, Anda Curry, Paneer Curry");
    }

    private void addDayMenu(String day, MealType mealType, String items) {
        MessMenu menu = messMenuRepository.findByDayOfWeekAndMealType(day, mealType).orElseGet(MessMenu::new);
        menu.setDayOfWeek(day);
        menu.setMealType(mealType);
        menu.setItems(items);
        messMenuRepository.save(menu);
    }
}
