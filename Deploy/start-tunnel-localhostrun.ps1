$ErrorActionPreference = 'Stop'
# Free SSH tunnel (localhost.run) -> local API on http://127.0.0.1:5199
# Keep this window open. Copy the printed https://xxxx.lhr.life URL.
# The -T flag is important: it prints the URL instead of opening a full-screen view.
ssh -T -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:127.0.0.1:5199 nokey@localhost.run
