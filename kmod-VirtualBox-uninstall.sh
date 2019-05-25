#!/usr/bin/env bash

# Check dependencies
for d in zenity date; do
    if ! type $d >/dev/null 2>&1; then
        echo "Dependency not found: $d" >&2
        exit 1
    fi
done

# sudo function
function run_sudo
{
    file=$1

    if [ -t 0 ]; then
        # Interactive mode (terminal)
        sudo "$file"
    else
        if type kdesudo >/dev/null 2>&1; then
            kdesudo -c "$file"
        elif type kdesu >/dev/null 2>&1; then
            kdesu -n -c "$file"
        elif type gksudo >/dev/null 2>&1; then
            gksudo "$file"
        elif type gksu >/dev/null 2>&1; then
            gksu --su-mode "$file"
        else
            zenity --error --text \
                "gksu not found, cannot sudo non-interactively"
        fi
    fi
}

# Create script in /tmp
cd /tmp/ || exit 1
ts=$(date +%s)
file=".tmp_script.$$.$ts.sh"
if [ -e "$file" ]; then
    # File conflict
    exit 1
fi
cat << 'EOF' > "$file"
#!/usr/bin/env bash

# Temporary script

# List all installed kmod packages for VirtualBox
list=$(rpm -qa 'kmod-VirtualBox*')
count=$(echo -n "$list" | grep -c '^')

# Abort if nothing found
if [[ $count -eq 0 ]]; then
    zenity --warning --text "No kmod-VirtualBox* modules found!"
    exit
fi

# Ask if they can be uninstalled
zenity --question --text "$count module(s) found. Uninstall these now?
$list"
if [ $? -ne 0 ]; then
    exit
fi

# Uninstall them
output=$(rpm -e $list 2>&1)
rc=$?
if [ $rc -ne 0 ]; then
    error_text=$output
    if [[ "$error_text" != "" ]]; then
        error_text=": $error_text"
    fi
    error_text="Error $rc$error_text"
    zenity --error --text "$error_text"
    exit $rc
else
    zenity --info --text "Modules uninstalled successfully!"
fi



EOF
chmod +x "$file"

# Run with sudo (gui support, not in terminal)
run_sudo "./$file"

# Clean up
rm "$file"



