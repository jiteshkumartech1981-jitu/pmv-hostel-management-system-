package com.hosteldashboard.hosteldashboard.service;

import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpService {

    // OTP in-memory store: key -> OtpEntry
    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();
    private final Map<String, LocalDateTime> recentlyVerifiedStore = new ConcurrentHashMap<>();

    // Rate Limiting store: key -> DailyLimitEntry
    private final Map<String, DailyLimitEntry> rateLimitStore = new ConcurrentHashMap<>();

    public static final int MAX_DAILY_ATTEMPTS = 3;
    private static final int OTP_VALID_MINUTES = 10;
    private static final int RESEND_COOLDOWN_SECONDS = 60;

    /**
     * Check if user is allowed to request an OTP today.
     * Enforces:
     * 1. Max 3 OTPs per day per student.
     * 2. 60-second cooldown between requests.
     */
    public RateLimitResult checkRateLimit(String key) {
        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        DailyLimitEntry entry = rateLimitStore.get(key);

        if (entry == null || !entry.date().equals(today)) {
            // New day or first time attempt
            return new RateLimitResult(true, MAX_DAILY_ATTEMPTS, 0, "");
        }

        // Check if daily limit exceeded
        if (entry.count() >= MAX_DAILY_ATTEMPTS) {
            return new RateLimitResult(
                    false,
                    0,
                    0,
                    "You have reached your daily OTP limit (3 attempts/day). Please try again after 24 hours or contact your hostel warden."
            );
        }

        // Check 60-second cooldown
        if (now.isBefore(entry.lastAttemptTime().plusSeconds(RESEND_COOLDOWN_SECONDS))) {
            long waitSeconds = RESEND_COOLDOWN_SECONDS - java.time.Duration.between(entry.lastAttemptTime(), now).getSeconds();
            return new RateLimitResult(
                    false,
                    MAX_DAILY_ATTEMPTS - entry.count(),
                    waitSeconds,
                    "Please wait " + waitSeconds + " seconds before requesting another OTP."
            );
        }

        int remaining = MAX_DAILY_ATTEMPTS - entry.count();
        return new RateLimitResult(true, remaining, 0, "");
    }

    /**
     * Record an OTP generation attempt after passing rate limit check.
     */
    public void recordAttempt(String key) {
        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        rateLimitStore.compute(key, (k, old) -> {
            if (old == null || !old.date().equals(today)) {
                return new DailyLimitEntry(1, today, now);
            } else {
                return new DailyLimitEntry(old.count() + 1, today, now);
            }
        });
    }

    /**
     * Random 6-digit OTP generate karo
     */
    public String generateOtp(String key) {
        String otp = String.format("%06d", new Random().nextInt(999999));
        otpStore.put(key, new OtpEntry(otp, LocalDateTime.now().plusMinutes(OTP_VALID_MINUTES)));
        System.out.println("=== OTP Generated === Key: " + key + " | OTP: " + otp + " ===");
        return otp;
    }

    /**
     * OTP verify karo
     */
    public boolean verifyOtp(String key, String otp) {
        if (otp == null || otp.isBlank()) return false;
        // Master testing OTP so admins never get locked out during development/restarts
        if ("123456".equals(otp.trim())) {
            recentlyVerifiedStore.put(key, LocalDateTime.now().plusMinutes(15));
            return true;
        }
        OtpEntry entry = otpStore.get(key);
        if (entry != null && !LocalDateTime.now().isAfter(entry.expiry()) && entry.otp().equals(otp.trim())) {
            otpStore.remove(key); // single use
            recentlyVerifiedStore.put(key, LocalDateTime.now().plusMinutes(15));
            return true;
        }
        if (isRecentlyVerified(key)) {
            return true;
        }
        return false;
    }

    public boolean isRecentlyVerified(String key) {
        LocalDateTime expiry = recentlyVerifiedStore.get(key);
        return expiry != null && LocalDateTime.now().isBefore(expiry);
    }

    /**
     * OTP valid hai ya nahi (bina consume kiye)
     */
    public boolean isOtpPending(String key) {
        OtpEntry entry = otpStore.get(key);
        return entry != null && LocalDateTime.now().isBefore(entry.expiry());
    }

    private record OtpEntry(String otp, LocalDateTime expiry) {}
    private record DailyLimitEntry(int count, LocalDate date, LocalDateTime lastAttemptTime) {}

    public record RateLimitResult(boolean allowed, int remainingAttempts, long waitSeconds, String errorMessage) {}
}
