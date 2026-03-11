# WoW Logs Addon (v1.0.2)

A powerful in-game utility for players on the **wow-logs.co.in** platform. This addon provides real-time ranking data, performance trends, and tooltip enhancements for World of Warcraft 3.3.5a.

## Features

- **Real-time Rankings**: View the top 20 players for every class, spec, and raid difficulty directly in-game.
- **Performance Trends**: Premium users can see personal performance gains/dips and their latest parse dates.
- **Enhanced Tooltips**: Hover over any player to see their global rank and performance snippets.
- **Followed Players**: Highlights your favorite players or rivals at the top of the ranking lists.

## Installation & Setup

1. **Download**: Clone or download this repository and place the `WowLogsAddon` folder into your `Interface/AddOns/` directory.
2. **Uploader**: Ensure you have the [Native Uploader](https://github.com/rksdevs/uploader-client-native) installed.
3. **Sync**:
   - Open the Native Uploader.
   - Select your server and click **Update Rankings**.
   - In-game, run `/reload` to load the fresh data.

## Premium Features & API Tokens

To access advanced features like **Performance Trends** and **Followed Players**, you must link an API token in the Native Uploader. There are two types of tokens:

### Personal API Tokens
For individual premium subscribers to track their own performance and followers.
1. **Generate**: Log in to [wow-logs.co.in](https://wow-logs.co.in) -> **Profile Settings** -> **API Access** -> **Generate Token**.
2. **Setup**: In the Native Uploader, expand **Premium Settings** and paste into **Personal API Token**.
3. **Save & Sync**: Click **Save Token**, then **Update Rankings**.

### Guild API Tokens
Guild Masters can share a token to provide premium rankings and trends to their entire roster.
1. **Generate (GM/Staff only)**: Navigate to your **Guild Management** page on the website and click **Generate Addon Token**.
2. **Share**: Share this token with your guild members via Discord or Guild Message.
3. **Setup (Member)**: In the Native Uploader, expand **Premium Settings** and paste into **Guild API Token**.
4. **Save & Sync**: Click **Save Token**, then **Update Rankings**.

*Note: After any token change, you must run `/reload` in-game to see the updated data.*

## Slash Commands

- `/wla` or `/wowlogs`: Toggle the ranking window.
- `/wla refresh`: Display instructions for updating data.
- `/wla status`: View the current database status and last update time.

## License

MIT License. Open source and community-driven.
