package com.hosteldashboard.hosteldashboard.config;

import com.hosteldashboard.hosteldashboard.model.Role;
import com.hosteldashboard.hosteldashboard.model.Staff;
import com.hosteldashboard.hosteldashboard.repository.StaffRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AdminSeeder {

    @Bean
    public CommandLineRunner seedSuperAdmin(StaffRepository staffRepository,
                                            PasswordEncoder passwordEncoder) {
        return args -> {
            if (staffRepository.count() > 0) {
                return;
            }

            String username = System.getenv("ADMIN_USERNAME");
            String password = System.getenv("ADMIN_PASSWORD");

            if (username == null || username.isBlank()
                    || password == null || password.length() < 8) {
                System.out.println("SUPER_ADMIN nahi bana: ADMIN_USERNAME aur ADMIN_PASSWORD (kam se kam 8 characters) set karo.");
                return;
            }

            Staff admin = new Staff();
            admin.setUsername(username);
            admin.setPasswordHash(passwordEncoder.encode(password));
            admin.setFullName("Super Admin");
            admin.setRole(Role.SUPER_ADMIN);
            admin.setActive(true);
            staffRepository.save(admin);

            System.out.println("SUPER_ADMIN ban gaya: " + username);
        };
    }
}