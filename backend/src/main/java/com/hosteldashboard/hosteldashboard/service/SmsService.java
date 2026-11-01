package com.hosteldashboard.hosteldashboard.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

@Service
public class SmsService {

    @Value("${sms.fast2sms.api-key:}")
    private String fast2SmsApiKey;

    @Value("${otp.webhook.url:}")
    private String otpWebhookUrl;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    /**
     * Send real SMS via Fast2SMS Gateway or n8n Webhook.
     *
     * @param mobile 10-digit Indian phone number
     * @param message Text message content
     * @return true if successfully delivered/dispatched, false otherwise
     */
    public boolean sendSms(String mobile, String message) {
        if (mobile == null || mobile.trim().isEmpty()) {
            System.out.println("⚠️ [SMS WARNING] Mobile number is empty. Cannot send SMS.");
            return false;
        }

        // Clean phone number (strip +91 or spaces)
        String cleanPhone = mobile.replaceAll("[^0-9]", "");
        if (cleanPhone.length() > 10) {
            cleanPhone = cleanPhone.substring(cleanPhone.length() - 10);
        }

        System.out.println("===============================================================");
        System.out.println("📨 [SMS DISPATCH] To: +91-" + cleanPhone);
        System.out.println("📄 [MESSAGE]: " + message);

        // 1. If n8n Webhook URL is configured, send to n8n automation
        if (otpWebhookUrl != null && !otpWebhookUrl.trim().isEmpty()) {
            try {
                String jsonPayload = String.format("{\"mobile\":\"%s\",\"message\":\"%s\"}", cleanPhone, message.replace("\"", "\\\""));
                HttpRequest webhookReq = HttpRequest.newBuilder()
                        .uri(URI.create(otpWebhookUrl))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                        .timeout(Duration.ofSeconds(8))
                        .build();
                HttpResponse<String> webhookRes = httpClient.send(webhookReq, HttpResponse.BodyHandlers.ofString());
                System.out.println("🤖 [n8n WEBHOOK DISPATCH]: Response " + webhookRes.statusCode());
                System.out.println("===============================================================");
                return webhookRes.statusCode() == 200;
            } catch (Exception e) {
                System.err.println("❌ [n8n WEBHOOK ERROR]: " + e.getMessage());
            }
        }

        // 2. If Fast2SMS is configured, send via Fast2SMS
        if (fast2SmsApiKey == null || fast2SmsApiKey.trim().isEmpty() || "YOUR_FAST2SMS_KEY_HERE".equals(fast2SmsApiKey)) {
            System.out.println("ℹ️ [SMS INFO] No Gateway/Webhook key configured. Printed to console.");
            System.out.println("===============================================================");
            return true;
        }

        try {
            String encodedMessage = URLEncoder.encode(message, StandardCharsets.UTF_8);
            String url = "https://www.fast2sms.com/dev/bulkV2?authorization=" + fast2SmsApiKey
                    + "&route=q&message=" + encodedMessage
                    + "&language=english&flash=0&numbers=" + cleanPhone;

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("cache-control", "no-cache")
                    .GET()
                    .timeout(Duration.ofSeconds(10))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            System.out.println("📡 [SMS GATEWAY RESPONSE]: " + response.statusCode() + " " + response.body());
            System.out.println("===============================================================");
            return response.statusCode() == 200;
        } catch (Exception e) {
            System.err.println("❌ [SMS ERROR] Failed to send SMS via Fast2SMS: " + e.getMessage());
            System.out.println("===============================================================");
            return false;
        }
    }

    /**
     * Send OTP SMS to Student
     */
    public boolean sendOtpSms(String mobile, String otp) {
        String msg = "Your PMV Hostel verification OTP is " + otp + ". Valid for 10 minutes. Do not share this OTP with anyone.";
        return sendSms(mobile, msg);
    }

    /**
     * Send Gate Pass Exit/Entry alert SMS to Parent
     */
    public boolean sendParentGateAlert(String parentMobile, String studentName, String action, String time, String reason) {
        String msg;
        if ("EXIT".equalsIgnoreCase(action)) {
            msg = "Dear Parent, your ward " + studentName + " has exited PMV Hostel campus at " + time + ". Reason: " + reason + ".";
        } else {
            msg = "Dear Parent, your ward " + studentName + " has safely returned to PMV Hostel campus at " + time + ".";
        }
        return sendSms(parentMobile, msg);
    }
}
