import "@supabase/functions-js/edge-runtime.d.ts";

const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");
const SUPPORT_CHAT_ID = Deno.env.get("SUPPORT_CHAT_ID");

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
    // MESSAGE FROM YOU → SEND REPLY TO USER
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

      // Text reply
      if (message.text) {
        await sendTelegram("sendMessage", {
          chat_id: userChatId,
          text: message.text,
        });

        return new Response("OK");
      }

      // Image reply
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
