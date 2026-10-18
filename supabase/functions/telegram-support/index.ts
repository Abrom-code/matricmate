import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");
const SUPPORT_CHAT_ID_RAW = Deno.env.get("SUPPORT_CHAT_ID") ?? "";

// Robust parsing: handles commas, semicolons, spaces, newlines, and quotes
const SUPPORT_CHAT_IDS = SUPPORT_CHAT_ID_RAW
  .replace(/["']/g, "")
  .split(/[\s,;]+/)
  .map((id) => id.trim())
  .filter(Boolean);

// An update is from support if either the chat ID (group/DM) OR sender user ID matches
const isSupport = (chatId?: string | number, fromId?: string | number) => {
  const cId = String(chatId ?? "");
  const fId = String(fromId ?? "");
  return SUPPORT_CHAT_IDS.includes(cId) || (fId !== "" && SUPPORT_CHAT_IDS.includes(fId));
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
  Deno.env.get("SUPABASE_ANON_KEY") ||
  "";

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

async function broadcastToSupport(
  method: string,
  bodyBuilder: (supportChatId: string) => Record<string, unknown>,
) {
  return await Promise.allSettled(
    SUPPORT_CHAT_IDS.map((id) => sendTelegram(method, bodyBuilder(id))),
  );
}

// Broadcasts a copy of an admin's action/reply to all OTHER support admins
async function broadcastToOtherAdmins(
  currentChatId: string | number,
  method: string,
  bodyBuilder: (supportChatId: string) => Record<string, unknown>,
) {
  const otherIds = SUPPORT_CHAT_IDS.filter(
    (id) => id !== String(currentChatId),
  );
  if (otherIds.length === 0) return [];
  return await Promise.allSettled(
    otherIds.map((id) => sendTelegram(method, bodyBuilder(id))),
  );
}

Deno.serve(async (req) => {
  try {
    const update = await req.json();
    const message = update.message;

    if (!message) {
      return new Response("OK");
    }

    const chatId = message.chat?.id;
    const fromId = message.from?.id;

    if (!chatId) {
      return new Response("OK");
    }

    const userIsSupport = isSupport(chatId, fromId);

    // ==================================================
    // MESSAGE FROM SUPPORT ADMIN → COMMANDS OR REPLIES
    // ==================================================

    if (userIsSupport) {
      const trimmedText = (message.text ?? "").trim();
      const repliedMessage = message.reply_to_message;

      // Build admin tag (e.g. "Abebe Bikila (@abebe)" or "Abebe")
      const adminFirstName = message.from?.first_name ?? "Admin";
      const adminLastName = message.from?.last_name ?? "";
      const adminFullName = `${adminFirstName} ${adminLastName}`.trim();
      const adminHandle = message.from?.username
        ? `(@${message.from?.username})`
        : "";
      const adminTag = `${adminFullName} ${adminHandle}`.trim();

      // ── 1. Handle /banned or /banlist command ────────
      if (trimmedText === "/banned" || trimmedText === "/banlist") {
        if (!supabase) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: "⚠️ Supabase client is not initialized to read bans.",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        const { data: bannedList, error } = await supabase
          .from("telegram_banned_users")
          .select("chat_id, reason, banned_at")
          .order("banned_at", { ascending: false })
          .limit(50);

        if (error) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: `❌ Error fetching banned users: ${error.message}`,
            reply_parameters: { message_id: message.message_id },
          });
        } else if (!bannedList || bannedList.length === 0) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: "📋 *No banned users.* The ban list is currently empty.",
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        } else {
          const lines = bannedList.map(
            (u, i) =>
              `${i + 1}. \`${u.chat_id}\` — _${u.reason || "No reason"}_`,
          );
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text:
              `🚫 *Banned Users (${bannedList.length}):*\n\n` +
              `${lines.join("\n")}\n\n` +
              `_To unban: /unban <ID>_`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        }
        return new Response("OK");
      }

      // ── 2. Determine target user ID from argument or reply ──
      let targetUserChatId: string | null = null;
      let commandReason: string | null = null;

      const parts = trimmedText.split(/\s+/);
      const isBanCmd = parts[0] === "/ban";
      const isUnbanCmd = parts[0] === "/unban";

      if (
        (isBanCmd || isUnbanCmd) &&
        parts.length > 1 &&
        /^\d+$/.test(parts[1])
      ) {
        // Direct format: /unban 12345678 or /ban 12345678 reason
        targetUserChatId = parts[1];
        if (isBanCmd) {
          commandReason = parts.slice(2).join(" ").trim() || null;
        }
      } else if (repliedMessage) {
        // Reply format: swipe-reply /unban or /ban [reason]
        const repliedText = repliedMessage.text ?? repliedMessage.caption ?? "";
        const match = repliedText.match(/User ID:\s*`?(\d+)`?/i);
        if (match) {
          targetUserChatId = match[1];
          if (isBanCmd) {
            commandReason = trimmedText.replace(/^\/ban\s*/, "").trim() || null;
          }
        }
      }

      // ── 3. Handle /ban command ──────────────────────
      if (isBanCmd) {
        if (!targetUserChatId) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text:
              "⚠️ *Usage:*\n" +
              "• Reply `/ban` to a forwarded user message, or\n" +
              "• Type `/ban <User_ID> [reason]`",
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        if (!supabase) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: "⚠️ Supabase client is not initialized to record bans.",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        const reason = commandReason || "Spam or policy violation";

        const { error } = await supabase
          .from("telegram_banned_users")
          .upsert({
            chat_id: String(targetUserChatId),
            reason,
            banned_at: new Date().toISOString(),
          });

        if (error) {
          console.error("Error banning user:", error);
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: `❌ Failed to ban user \`${targetUserChatId}\`: ${error.message}`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        } else {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text:
              `🚫 *User Banned Successfully*\n\n` +
              `• *User ID:* \`${targetUserChatId}\`\n` +
              `• *Reason:* ${reason}\n\n` +
              `Future messages from this user will be silently ignored.\n` +
              `_To unban: /unban ${targetUserChatId}_`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });

          // Notify other admins about the ban
          await broadcastToOtherAdmins(chatId, "sendMessage", (otherId) => ({
            chat_id: otherId,
            text:
              `🚫 *Admin Banned User*\n\n` +
              `• *By Admin:* ${adminTag}\n` +
              `• *User ID:* \`${targetUserChatId}\`\n` +
              `• *Reason:* ${reason}`,
            parse_mode: "Markdown",
          }));
        }
        return new Response("OK");
      }

      // ── 4. Handle /unban command ────────────────────
      if (isUnbanCmd) {
        if (!targetUserChatId) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text:
              "⚠️ *Usage:*\n" +
              "• Reply `/unban` to a user's message, or\n" +
              "• Type `/unban <User_ID>`",
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        if (!supabase) {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: "⚠️ Supabase client is not initialized to remove bans.",
            reply_parameters: { message_id: message.message_id },
          });
          return new Response("OK");
        }

        const { error } = await supabase
          .from("telegram_banned_users")
          .delete()
          .eq("chat_id", String(targetUserChatId));

        if (error) {
          console.error("Error unbanning user:", error);
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text: `❌ Failed to unban user \`${targetUserChatId}\`: ${error.message}`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });
        } else {
          await sendTelegram("sendMessage", {
            chat_id: chatId,
            text:
              `✅ *User Unbanned Successfully*\n\n` +
              `• *User ID:* \`${targetUserChatId}\`\n` +
              `This user can now send support messages again.`,
            parse_mode: "Markdown",
            reply_parameters: { message_id: message.message_id },
          });

          // Notify other admins about the unban
          await broadcastToOtherAdmins(chatId, "sendMessage", (otherId) => ({
            chat_id: otherId,
            text:
              `✅ *Admin Unbanned User*\n\n` +
              `• *By Admin:* ${adminTag}\n` +
              `• *User ID:* \`${targetUserChatId}\``,
            parse_mode: "Markdown",
          }));
        }
        return new Response("OK");
      }

      // ── 5. Regular Message Reply Forwarding ─────────
      if (!repliedMessage) {
        // Internal admin chatter that is not a reply to a user ticket is ignored
        return new Response("OK");
      }

      const repliedText = repliedMessage.text ?? repliedMessage.caption ?? "";
      const match = repliedText.match(/User ID:\s*`?(\d+)`?/i);

      if (!match) {
        console.log("Could not find user chat ID in replied message.");
        return new Response("OK");
      }

      const userChatId = match[1];

      // Text reply forwarding to user + sync to other admins
      if (message.text) {
        // 1. Send clean reply to the student
        await sendTelegram("sendMessage", {
          chat_id: userChatId,
          text: message.text,
        });

        // 2. Notify other admins with the Admin Tag
        await broadcastToOtherAdmins(chatId, "sendMessage", (otherId) => ({
          chat_id: otherId,
          text:
            `💬 *Admin Reply Sent*\n\n` +
            `• *By Admin:* ${adminTag}\n` +
            `• *To User ID:* \`${userChatId}\`\n\n` +
            `*Message:*\n${message.text}`,
          parse_mode: "Markdown",
        }));

        return new Response("OK");
      }

      // Image reply forwarding to user + sync to other admins
      if (message.photo) {
        const photo = message.photo[message.photo.length - 1];

        // 1. Send photo to the student
        await sendTelegram("sendPhoto", {
          chat_id: userChatId,
          photo: photo.file_id,
          caption: message.caption || undefined,
        });

        // 2. Notify other admins with the Admin Tag
        const otherCaption =
          `🖼️ *Admin Photo Reply Sent*\n\n` +
          `• *By Admin:* ${adminTag}\n` +
          `• *To User ID:* \`${userChatId}\`` +
          (message.caption ? `\n\n*Caption:*\n${message.caption}` : "");

        await broadcastToOtherAdmins(chatId, "sendPhoto", (otherId) => ({
          chat_id: otherId,
          photo: photo.file_id,
          caption: otherCaption,
          parse_mode: "Markdown",
        }));

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
    // TEXT MESSAGE → BROADCAST TO ALL SUPPORT IDS
    // ==================================================

    if (message.text) {
      await broadcastToSupport("sendMessage", (supportId) => ({
        chat_id: supportId,
        text: `${userInfo}\n\n${message.text}${routingInfo}`,
        reply_parameters: {
          allow_sending_without_reply: true,
        },
      }));
    }

    // ==================================================
    // IMAGE MESSAGE → BROADCAST TO ALL SUPPORT IDS
    // ==================================================
    else if (message.photo) {
      const photo = message.photo[message.photo.length - 1];

      const caption = message.caption
        ? `${userInfo}\n\n${message.caption}${routingInfo}`
        : `${userInfo}${routingInfo}`;

      await broadcastToSupport("sendPhoto", (supportId) => ({
        chat_id: supportId,
        photo: photo.file_id,
        caption,
      }));
    }

    // ==================================================
    // OTHER MESSAGE TYPES → BROADCAST TO ALL SUPPORT IDS
    // ==================================================
    else {
      await broadcastToSupport("sendMessage", (supportId) => ({
        chat_id: supportId,
        text:
          `${userInfo}\n\n` +
          "📎 The user sent a message type that isn't currently supported." +
          routingInfo,
      }));
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
