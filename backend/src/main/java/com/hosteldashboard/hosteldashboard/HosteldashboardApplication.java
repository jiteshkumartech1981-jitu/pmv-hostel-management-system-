package com.hosteldashboard.hosteldashboard;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class HosteldashboardApplication {

	public static void main(String[] args) {
		SpringApplication.run(HosteldashboardApplication.class, args);
	}

}
