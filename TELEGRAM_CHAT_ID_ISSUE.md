# Telegram Chat ID Issue

The daily status report attempted to send a message to "Jeremy Pogue" but failed because the chat ID is unknown or invalid. This typically happens if:
- The bot hasn't been started in a direct message with Jeremy
- The bot was removed from a group/channel
- The group was migrated (new -100… ID)
- An incorrect bot token is configured

Please verify the correct chat ID and ensure the bot is properly configured for messaging.