#!/bin/bash
# Schedules a CPU load so the CloudWatch alarm can be demonstrated without SSH.
set -euxo pipefail

# Helper: one busy loop per vCPU for N seconds (no packages needed)
cat > /usr/local/bin/generate-load.sh <<'SCRIPT'
#!/bin/bash
DURATION="$1"
for i in $(seq "$(nproc)"); do
  timeout "$DURATION" sh -c 'while :; do :; done' &
done
wait
SCRIPT
chmod +x /usr/local/bin/generate-load.sh

%{ if enable_load_test ~}
# Start the load after a delay (transient systemd timer)
systemd-run --unit=cpu-load --on-active=${load_start_delay}s \
  /usr/local/bin/generate-load.sh ${load_duration}
%{ endif ~}
