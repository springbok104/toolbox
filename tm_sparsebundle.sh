#!/bin/bash

# Time Machine Sparsebundle Creation Script
#
# Purpose:
#   Time Machine has a mind of its own. Especially when backing up
#   to remote drives or NAS volumes. This script creates a 
#   sparsebundle disk image with custom options to use with Time Machine
#
# Use Case:
#   For macOS users manually configuring backups to non-Apple storage. Whether 
#   you're using a NAS or setting up offsite rotation, this gives
#   you control over band size, encryption, naming and inheritance for adding to Time Machine
#
# Notes on Band Size:
#   - Band size governs how data is chunked inside the sparsebundle:
#       • Smaller (1–4MB): more granular, but can slow things down
#       • Larger (32–64MB): faster bulk writes, less efficient with small changes
#   - Default is 16MB — a sensible middle ground for most network backups
#
# Overview:
#   - Prompts for volume name, backup size, band size, encryption, and destination path
#   - Validates input, applies defaults, and ensures clarity throughout
#   - Creates a .sparsebundle named after your system’s UUID
#   - Optionally encrypts with AES-256 and a password
#   - Offers to call ‘tmutil inheritbackup’ so Time Machine recognizes it
#
# After Creation:
#   - Go to System Settings > Time Machine
#   - Add Backup Disk → Use Existing Disk
#   - Enter the password (if set) when prompted
#
# Considerations:
#   - You might want to test read/write access to the destination beforehand
#   - Some commands use sudo


# Gather system UUID
uuid=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $4}')

# Prompt for input
echo ""
read -p "Enter volume name: " volume_name
read -p "Enter backup size in GB: " backup_size
read -p "Enter band size in MB 1–64 (default = 8MB): " band_size
read -p "Enable encryption? (y/n): " enable_encryption
read -p "Enter directory path to create Sparsebundle: " directory_path
echo ""

if [[ -z "$volume_name" || -z "$backup_size" ]]; then
    echo "Missing required input for Volume Name and Backup Size in GB. Exiting."
    exit 1
fi

# Display summary
echo ""
echo "Configuration Summary:"
echo "  Volume Name:       $volume_name"
echo "  Backup Size:       ${backup_size}GB"
echo "  Band Size:         ${band_size}MB"
echo "  Encryption:        $( [[ "$enable_encryption" =~ ^(y|Y|yes)$ ]] && echo "Enabled" || echo "Disabled" )"
echo "  Destination Path:  $directory_path"
echo ""

if ! [[ "$band_size" =~ ^[0-9]+$ ]]; then
    band_size="8"
fi

band_size=$((band_size * 2048))  # Convert MB to blocks (1 block = 512 bytes)

# Handle encryption input
if [[ "$enable_encryption" =~ ^(y|Y|yes)$ ]]; then
    read -s -p "Set disk image password: " password
    echo ""

    if [[ -z "$password" ]]; then
        echo "      Password isn't set. Exiting now."
        exit 1
    fi

    encryption_flags="-encryption AES-256 -stdinpass"
else
    encryption_flags=""
fi

# Verify directory path
if [ ! -d "$directory_path" ]; then
    directory_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    echo "  Path not entered. Defaulting to: ${directory_path}"
fi

echo ""
read -p "Would you like to proceed? (y/n): " confirm

# Final confirmation and image creation
if [[ "$confirm" =~ ^(y|Y|yes)$ ]]; then
    echo ""
    echo "Creating sparsebundle disk image..."
    echo ""

    if [[ "$enable_encryption" =~ ^(y|Y|yes)$ ]]; then
        printf "%s\0" "$password" | hdiutil create \
            -size "${backup_size}g" \
            -type SPARSEBUNDLE \
            -fs HFS+J \
            -volname "$volume_name" \
            $encryption_flags \
            -imagekey sparse-band-size="${band_size}" \
            "${directory_path}/${uuid}.sparsebundle"
    else
        hdiutil create \
            -size "${backup_size}g" \
            -type SPARSEBUNDLE \
            -fs HFS+J \
            -volname "$volume_name" \
            -imagekey sparse-band-size="${band_size}" \
            "${directory_path}/${uuid}.sparsebundle"
    fi

else
    echo ""
    echo "You have chosen to cancel. Script will halt."
    exit 1
fi

if [ -d "${directory_path}/${uuid}.sparsebundle" ]; then
    echo "Found the sparsebundle that was created"
    read -p "Would you like to inherit $uuid.sparsebundle? (y/n) " inherit

    if [[ "$inherit" =~ ^(y|Y|yes)$ ]]; then
        echo "Attempting to inherit sparsebundle"
        sudo tmutil inheritbackup "${directory_path}/${uuid}.sparsebundle"
        echo "Done. Please create a Time Machine backup via System settings and use existing disk"
    else
        echo "Sparsebundle will not be inherited"
    fi
fi