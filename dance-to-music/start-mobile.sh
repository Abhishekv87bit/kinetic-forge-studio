#!/bin/bash
# Start the dance-to-music server + HTTPS tunnel for mobile access.
# No password needed — opens directly on phone.

cd "$(dirname "$0")"

echo "Starting HTTP server on port 3000..."
python -m http.server 3000 &
SERVER_PID=$!

echo "Starting HTTPS tunnel (Cloudflare)..."
cloudflared tunnel --url http://localhost:3000 2>&1 | tee /dev/stderr | grep -o "https://[^ ]*trycloudflare.com" &
TUNNEL_PID=$!

sleep 5
echo ""
echo "==================================="
echo "  Open the trycloudflare.com URL"
echo "  shown above on your phone."
echo "==================================="
echo ""
echo "Press Ctrl+C to stop."

trap "kill $SERVER_PID $TUNNEL_PID 2>/dev/null; exit" INT
wait
