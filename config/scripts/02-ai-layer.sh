#!/usr/bin/env bash
set -euo pipefail

# ── Collet OS AI Layer Setup ───────────────────────────────
# Installs Ollama and prepares the AI configuration.
# Model download happens on first boot (not during image build).

echo ":: Setting up AI layer"

# Install Ollama binary
curl -fsSL https://ollama.com/install.sh | sh

# Create AI configuration directory
mkdir -p /usr/share/collet-os/ai

# Create first-boot AI setup service
cat > /etc/systemd/system/collet-ai-setup.service << 'EOF'
[Unit]
Description=Collet OS AI First Boot Setup
After=network-online.target ollama.service
Wants=network-online.target
ConditionPathExists=!/var/lib/collet-os/.ai-setup-done

[Service]
Type=oneshot
ExecStart=/usr/share/collet-os/ai/first-boot.sh
ExecStartPost=/usr/bin/touch /var/lib/collet-os/.ai-setup-done
RemainAfterExit=yes
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
EOF

# Create first-boot script
cat > /usr/share/collet-os/ai/first-boot.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Wait for Ollama to be ready
for i in $(seq 1 30); do
    if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Detect available RAM and select appropriate model
RAM_GB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)

if [ "$RAM_GB" -ge 16 ]; then
    MODEL="mistral:7b-instruct-v0.3-q4_K_M"
elif [ "$RAM_GB" -ge 8 ]; then
    MODEL="llama3.2:3b"
else
    MODEL="llama3.2:1b"
fi

echo "Detected ${RAM_GB}GB RAM — pulling model: ${MODEL}"
ollama pull "$MODEL"

# Create the Collet assistant modelfile
cat > /tmp/collet-assistant.modelfile << MODELFILE
FROM ${MODEL}
SYSTEM """$(cat /usr/share/collet-os/ai/system-prompt.md)"""
PARAMETER temperature 0.3
PARAMETER num_ctx 4096
MODELFILE

ollama create collet-assistant -f /tmp/collet-assistant.modelfile
rm /tmp/collet-assistant.modelfile

echo "Collet AI assistant ready with model: ${MODEL}"
SCRIPT

chmod +x /usr/share/collet-os/ai/first-boot.sh

# Enable services
systemctl enable ollama.service
systemctl enable collet-ai-setup.service

echo ":: AI layer configured"
