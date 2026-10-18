import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");
const SUPPORT_CHAT_ID = Deno.env.get("SUPPORT_CHAT_ID");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const supabase =
  SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
    ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    : null;

const telegramApi = `https://api.telegram.org/bot${BOT_TOKEN}`;

async function sendTelegram(method: string, body: Record<string, unknown>) {
  return await fetch(`${telegramApi}/${method}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

Deno.serve(async (req) => {
  try {
    const update = await req.json();
    const message = update.message;

    if (!message) {
      return new Response("OK");
    }

    const chatId = message.chat?.id;

    if (!chatId) {
      return new Response("OK");
    }

    // ==================================================
    // MESSAGE FROM SUPPORT ADMIN → REPLY OR /ban COMMAND
    // ==================================================

    if (String(chatId) === String(SUPPORT_CHAT_ID)) {
      const repliedMessage = message.reply_to_message;

      if (!repliedMessage) {
        return new Response("OK");
      }

      const repliedText = repliedMessage.text ?? repliedMessage.caption ?? "";

      const match = repliedText.match(/User ID:\s*(\d+)/);

      if (!match) {
        console.log("Could not find user chat ID.");
        return new Response("OK");
      }

      const userChatId = match[1];
      const trimmedText = (message.text ?? "").trim();

      // ── Handle /ban command ─────────────────────────
      if (trimmedText.startsWith("/ban")) {
        if (!supabase) {
          await sendTelegram("sendMessage", {
            chat_id: SUPPORT_CHAT_ID,
            text: "⚠️ Supabase client is not initialized to record bans.",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        const reason =
          trimmedText.replace(/^\/ban\s*/, "").trim() ||
          "Spam or policy violation";

        const { error } = await supabase
          .from("telegram_banned_users")
          .upsert({
            chat_id: String(userChatId),
            reason,
            banned_at: new Date().toISOString(),
          });

        if (error) {
          console.error("Error banning user:", error);
          await sendTelegram("sendMessage", {
            chat_id: SUPPORT_CHAT_ID,
            text: `❌ Failed to ban user \`${userChatId}\`: ${error.message}`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        } else {
          await sendTelegram("sendMessage", {
            chat_id: SUPPORT_CHAT_ID,
            text:
              `🚫 *User Banned Successfully*\n\n` +
              `• *User ID:* \`${userChatId}\`\n` +
              `• *Reason:* ${reason}\n\n` +
              `Future messages from this user will be silently ignored.`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        }
        return new Response("OK");
      }

      // ── Handle /unban command ───────────────────────
      if (trimmedText.startsWith("/unban")) {
        if (!supabase) {
          await sendTelegram("sendMessage", {
            chat_id: SUPPORT_CHAT_ID,
            text: "⚠️ Supabase client is not initialized to remove bans.",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        const { error } = await supabase
          .from("telegram_banned_users")
          .delete()
          .eq("chat_id", String(userChatId));

        if (error) {
          console.error("Error unbanning user:", error);
          await sendTelegram("sendMessage", {
            chat_id: SUPPORT_CHAT_ID,
            text: `❌ Failed to unban user \`${userChatId}\`: ${error.message}`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        } else {
          await sendTelegram("sendMessage", {
            chat_id: SUPPORT_CHAT_ID,
            text:
              `✅ *User Unbanned Successfully*\n\n` +
              `• *User ID:* \`${userChatId}\`\n` +
              `This user can now send support messages again.`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        }
        return new Response("OK");
      }

      // Text reply forwarding
      if (message.text) {
        await sendTelegram("sendMessage", {
          chat_id: userChatId,
          text: message.text,
        });

        return new Response("OK");
      }

      // Image reply forwarding
      if (message.photo) {
        const photo = message.photo[message.photo.length - 1];

        await sendTelegram("sendPhoto", {
          chat_id: userChatId,
          photo: photo.file_id,
          caption: message.caption || undefined,
        });

        return new Response("OK");
      }

      return new Response("OK");
    }

    // ==================================================
    // CHECK IF SENDER IS BANNED
    // ==================================================

    if (supabase) {
      const { data: bannedUser } = await supabase
        .from("telegram_banned_users")
        .select("chat_id")
        .eq("chat_id", String(chatId))
        .maybeSingle();

      if (bannedUser) {
        console.log(`Silently dropped message from banned user ${chatId}`);
        return new Response("OK");
      }
    }

    // ==================================================
    // /start → DON'T FORWARD TO SUPPORT
    // ==================================================

    if (message.text === "/start") {
      await sendTelegram("sendMessage", {
        chat_id: chatId,
        text:
          "👋 *Welcome to MatricET Support*\n\n" +
          "We're here to help you with any questions or issues you have.\n\n" +
          "_Please describe your issue clearly so we can help you faster._",
        parse_mode: "Markdown",
      });

      return new Response("OK");
    }

    // ==================================================
    // USER INFORMATION
    // ==================================================

    const firstName = message.from?.first_name ?? "Unknown";
    const lastName = message.from?.last_name ?? "";
    const username = message.from?.username;

    const fullName = `${firstName} ${lastName}`.trim();

    const userInfo = username
      ? `👤 ${fullName}\n@${username}`
      : `👤 ${fullName}\nID: ${chatId}`;

    // Internal routing information.
    const routingInfo = `\n\nUser ID: ${chatId}`;

    // ==================================================
    // TEXT MESSAGE
    // ==================================================

    if (message.text) {
      await sendTelegram("sendMessage", {
        chat_id: SUPPORT_CHAT_ID,
        text: `${userInfo}\n\n${message.text}${routingInfo}`,
        reply_parameters: {
          allow_sending_without_reply: true,
        },
      });
    }

    // ==================================================
    // IMAGE MESSAGE
    // ==================================================
    else if (message.photo) {
      const photo = message.photo[message.photo.length - 1];

      const caption = message.caption
        ? `${userInfo}\n\n${message.caption}${routingInfo}`
        : `${userInfo}${routingInfo}`;

      await sendTelegram("sendPhoto", {
        chat_id: SUPPORT_CHAT_ID,
        photo: photo.file_id,
        caption,
      });
    }

    // ==================================================
    // OTHER MESSAGE TYPES
    // ==================================================
    else {
      await sendTelegram("sendMessage", {
        chat_id: SUPPORT_CHAT_ID,
        text:
          `${userInfo}\n\n` +
          "📎 The user sent a message type that isn't currently supported." +
          routingInfo,
      });
    }

    // ==================================================
    // CONFIRMATION TO USER
    // ==================================================

    await sendTelegram("sendMessage", {
      chat_id: chatId,
      text: "✅ *Message Received*",
      parse_mode: "Markdown",
    });

    return new Response("OK");
  } catch (error) {
    console.error("Telegram support error:", error);

    return new Response("Error", {
      status: 500,
    });
  }
});
