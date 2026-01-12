import * as admin from "firebase-admin";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

admin.initializeApp();

const runtimeOptions = { region: "us-central1" };

type NotificationInput = {
  tokens?: unknown;
  title?: unknown;
  body?: unknown;
  notificationData?: unknown;
};

type NotificationFailure = {
  token: string;
  error: string;
};

export const ping = onRequest(runtimeOptions, (_req, res) => {
  res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
});

export const sendNotification = onCall(runtimeOptions, async (request) => {
  const payload = request.data as NotificationInput | undefined;
  const tokens = normalizeTokens(payload?.tokens);
  if (tokens.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "The 'tokens' array is required and must contain at least one valid FCM token.",
    );
  }

  const notification = buildNotification(payload?.title, payload?.body);
  const data = buildNotificationData(payload?.notificationData);

  const message: admin.messaging.MulticastMessage = { tokens };
  if (notification) {
    message.notification = notification;
  }
  if (data) {
    message.data = data;
  }

  try {
    const result = await admin.messaging().sendEachForMulticast(message);
    const failures = result.responses
      .map<NotificationFailure | null>((response, index) => {
        if (response.success) return null;
        return {
          token: tokens[index],
          error: formatResponseError(response.error),
        };
      })
      .filter((response): response is NotificationFailure => response !== null);

    return {
      successCount: result.successCount,
      failureCount: result.failureCount,
      failures,
    };
  } catch (error) {
    console.error("sendNotification error", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      "Unable to send notifications. Please try again later.",
      error instanceof Error ? error.message : undefined,
    );
  }
});

function normalizeTokens(rawTokens: unknown): string[] {
  if (!Array.isArray(rawTokens)) {
    return [];
  }
  return rawTokens
    .filter((token): token is string => typeof token === "string")
    .map((token) => token.trim())
    .filter((token) => token.length > 0);
}

function buildNotification(title?: unknown, body?: unknown): admin.messaging.Notification | undefined {
  const result: admin.messaging.Notification = {};
  if (typeof title === "string" && title.trim().length > 0) {
    result.title = title.trim();
  }
  if (typeof body === "string" && body.trim().length > 0) {
    result.body = body.trim();
  }
  return Object.keys(result).length > 0 ? result : undefined;
}

function buildNotificationData(rawData: unknown): Record<string, string> | undefined {
  if (rawData == null || typeof rawData !== "object" || Array.isArray(rawData)) {
    return undefined;
  }
  const data: Record<string, string> = {};
  Object.entries(rawData).forEach(([key, value]) => {
    if (typeof value === "string") {
      data[key] = value;
    }
  });
  return Object.keys(data).length > 0 ? data : undefined;
}

function formatResponseError(error: admin.messaging.SendResponse["error"]): string {
  if (!error) {
    return "unknown";
  }
  if ("message" in error && typeof error.message === "string") {
    return error.message;
  }
  if ("code" in error && typeof error.code === "string") {
    return error.code;
  }
  return "unknown";
}
