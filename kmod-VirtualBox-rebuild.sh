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

# Run akmods
output=$(akmods --force 2>&1)
rc=$?
if [ $rc -ne 0 ]; then
    text=$output
    if [[ "$text" != "" ]]; then
        text=$'\n'"$text"
    fi
    text="Error $rc$text"
    zenity --error --text "$text"
    exit $rc
else
    text=$output
    if [[ "$text" != "" ]]; then
        text=$'\n'"$text"
    fi
    text="OK$text"
    zenity --info --text "$text"
fi



EOF
chmod +x "$file"

# Run with sudo (gui support, not in terminal)
run_sudo "./$file"

# Clean up
rm "$file"



