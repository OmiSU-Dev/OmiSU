# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
# Run omisu-restart-xcompose to apply changes

# Include fast emoji access
include "/usr/share/omisu/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$OMISU_USER_NAME"
<Multi_key> <space> <e> : "$OMISU_USER_EMAIL"
EOF
