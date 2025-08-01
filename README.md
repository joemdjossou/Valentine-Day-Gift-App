# Valentine Day Gift App

A Flutter app that analyzes WhatsApp chat messages to find cute and heartwarming messages from your partner, then schedules them as daily notifications.

## How to use

1. Add `.env` file with the following keys:

   ```
   OPEN_AI_API_KEY=[YOUR OPENAI KEY]
   YOUR_PARTNERS_NAME=[YOUR PARTNER'S NAME]
   ```

2. Run `dart run build_runner build` to update the environment keys

3. Add your exported WhatsApp chat to the `assets` folder with name `whatsapp_chat.txt`

4. Follow Flutter get started guide to learn how to run a flutter app on a device

## Caching System

The app includes an intelligent caching system to minimize OpenAI API calls and costs:

### How it works:

- **First run**: The app analyzes your chat with AI and stores the results locally
- **Subsequent runs**: Uses cached data instead of making new API requests
- **Cache expiration**: Automatically refreshes every 7 days
- **Content detection**: If your chat file changes, the cache is invalidated

### Cache Management:

- **Refresh button** (🔄): Updates the current message and checks cache status
- **Clear cache button** (🗑️): Manually clears the cache to force a new AI analysis
- **Status indicator**: Shows whether you're using cached data or fresh analysis

### Benefits:

- **Cost savings**: Reduces OpenAI API calls by 90%+
- **Faster loading**: Cached data loads instantly
- **Offline capability**: Works without internet after initial analysis
- **Automatic updates**: Refreshes when needed without manual intervention

### Cache Status Colors:

- 🟢 **Green**: Using valid cached data
- 🟠 **Orange**: Cache expired, will refresh on next use
