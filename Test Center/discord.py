import requests
import json
import os

# Set the Discord API endpoint
API_ENDPOINT = "https://discordapp.com/api/v9"

# Set the channel ID
CHANNEL_ID = "1234567890"

# Set the output file
OUTPUT_FILE = "messages.json"

# Get the channel messages
response = requests.get(
    f"{API_ENDPOINT}/channels/{CHANNEL_ID}/messages",
    headers={"Authorization": "Bot <YOUR_BOT_TOKEN>"},
)

# Check for errors
if response.status_code != 200:
    print(f"Error: {response.status_code}")
    exit()

# Parse the JSON response
messages = json.loads(response.content)

# Save the messages to a file
with open(OUTPUT_FILE, "w") as outfile:
    json.dump(messages, outfile)