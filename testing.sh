echo 
echo " USER ACCOUNT MANAGEMENT SCRIPT "
echo 
echo " This script allows an administrator to:"
echo "  - Add, delete or modify system users"
echo "  - Manage groups"
echo "  - Change file permissions"
echo "  - Set a default shell"
echo "  - List only custom-created users and groups"

pause


#!/bin/bash

# ============================================================
#   USER ACCOUNT MANAGEMENT SCRIPT
# ============================================================

# Require root
if [[ $EUID -ne 0 ]]; then
    echo "Must run as root: sudo ./user_mgmt.sh"
    exit 1
fi

# Pause helper
pause() {
    read -p "Press Enter to continue..."
}

# Logging
log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> /var/log/user_mgmt.log
}

# ------------------------------------------------------------
# ADD USER
# ------------------------------------------------------------
add_user() {
    echo
    echo "---- Add New User ----"
    echo

    read -p "Enter username (or 'q' to cancel): " username
    if [[ "$username" == "q" ]]; then
        echo "Cancelled."
        pause
        return
    fi

    username=$(echo "$username" | tr 'A-Z' 'a-z')

    if id "$username" &>/dev/null; then
        echo "Error: User already exists."
        pause
        return
    fi

    read -p "Enter full name: " fullname

    # Default shell
    if [[ -f default_shell.conf ]]; then
        def_shell=$(cat default_shell.conf)
    else
        def_shell="/bin/bash"
    fi

    useradd -m -s "$def_shell" -c "$fullname" "$username"
    if [[ $? -ne 0 ]]; then
        echo "Failed to create user."
        pause
        return
    fi

    # Password loop
    while true; do
        read -s -p "Enter password (8–12 chars): " password
        echo
        read -s -p "Confirm password: " password2
        echo

        if [[ "$password" != "$password2" ]]; then
            echo "Passwords do not match."
            continue
        fi

        if (( ${#password} < 8 || ${#password} > 12 )); then
            echo "Password must be 8–12 characters."
            continue
        fi

        echo "$username:$password" | chpasswd
        break
    done

    echo "User '$username' created."
    log_action "Created user '$username'"
    pause
}

# ------------------------------------------------------------
# DELETE USER
# ------------------------------------------------------------
delete_user() {
    echo
    echo "---- Delete User ----"
    echo

    read -p "Enter username to delete (or 'q' to cancel): " username
    if [[ "$username" == "q" ]]; then
        echo "Cancelled."
        pause
        return
    fi

    username=$(echo "$username" | tr 'A-Z' 'a-z')

    if ! id "$username" &>/dev/null; then
        echo "User does not exist."
        pause
        return
    fi

    read -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        userdel -r "$username"
        echo "Deleted."
        log_action "Deleted user '$username'"
    else
        echo "Cancelled."
    fi

    pause
}

# ------------------------------------------------------------
# MODIFY USER
# ------------------------------------------------------------
modify_user() {
    echo
    echo "---- Modify User ----"
    echo

    read -p "Enter username (or 'q' to cancel): " username
    if [[ "$username" == "q" ]]; then
        echo "Cancelled."
        pause
        return
    fi

    username=$(echo "$username" | tr 'A-Z' 'a-z')

    if ! id "$username" &>/dev/null; then
        echo "User does not exist."
        pause
        return
    fi

    echo "1) Change password"
    echo "2) Change full name"
    echo "3) Change shell"
    echo "4) Cancel"
    read -p "Choose option: " choice

    case $choice in
        1)
            while true; do
                read -s -p "New password (8–12 chars, or 'q' to cancel): " pass1
                echo
                read -s -p "Confirm new password: " pass2
                echo

                if [[ "$pass1" == "q" || "$pass2" == "q" ]]; then
                    echo "Cancelled."
                    pause
                    return
                fi

                if [[ "$pass1" != "$pass2" ]]; then
                    echo "Passwords do not match."
                    continue
                fi

                if (( ${#pass1} < 8 || ${#pass1} > 12 )); then
                    echo "Password must be 8–12 characters."
                    continue
                fi

                echo "$username:$pass1" | chpasswd
                echo "Password updated."
                log_action "Changed password for '$username'"
                break
            done
            ;;

        2)
            read -p "Enter new full name (or 'q' to cancel): " fullname
            if [[ "$fullname" == "q" ]]; then
                echo "Cancelled."
                pause
                return
            fi

            chfn -f "$fullname" "$username"
            echo "Full name updated."
            log_action "Changed full name for '$username'"
            ;;

        3)
            read -p "Enter new shell (e.g. /bin/bash): " shell
            if [[ "$shell" == "q" ]]; then
                echo "Cancelled."
                pause
                return
            fi

            chsh -s "$shell" "$username"
            echo "Shell updated."
            log_action "Changed shell for '$username'"
            ;;

        4)
            echo "Cancelled."
            ;;

        *)
            echo "Invalid choice."
            ;;
    esac

    pause
}

# ------------------------------------------------------------
# LIST USERS
# ------------------------------------------------------------
list_users() {
    echo
    echo "---- System Users ----"
    echo
    cat /etc/passwd
    pause
}

# ------------------------------------------------------------
# GROUP MANAGEMENT
# ------------------------------------------------------------
group_management() {
    echo
    echo "---- Group Management ----"
    echo

    echo "1) Create group"
    echo "2) Add user to group"
    echo "3) List groups"
    echo "4) Cancel"
    read -p "Choose option: " gopt

    case $gopt in
        1)
            read -p "Enter group name: " gname
            if [[ "$gname" == "q" ]]; then pause; return; fi

            if getent group "$gname" >/dev/null; then
                echo "Group exists."
            else
                groupadd "$gname"
                echo "Group created."
            fi
            ;;

        2)
            read -p "Enter username: " uname
            uname=$(echo "$uname" | tr 'A-Z' 'a-z')
            read -p "Enter group name: " gname

            if ! id "$uname" &>/dev/null; then
                echo "User does not exist."
            elif ! getent group "$gname" >/dev/null; then
                echo "Group does not exist."
            else
                usermod -aG "$gname" "$uname"
                echo "Added."
            fi
            ;;

        3)
            cut -d: -f1 /etc/group
            ;;

        4)
            echo "Cancelled."
            ;;

        *)
            echo "Invalid option."
            ;;
    esac

    pause
}

# ------------------------------------------------------------
# PERMISSION MANAGEMENT
# ------------------------------------------------------------
permission_management() {
    echo
    echo "---- Permission Management ----"
    echo

    echo "1) chmod"
    echo "2) chown"
    echo "3) Cancel"
    read -p "Choose option: " popt

    case $popt in
        1)
            read -p "Enter file path: " path
            if [[ ! -e "$path" ]]; then echo "Not found."; pause; return; fi

            read -p "Enter permission (e.g., 755): " perms
            if [[ ! "$perms" =~ ^[0-7]{3,4}$ ]]; then
                echo "Invalid format."
                pause
                return
            fi

            chmod "$perms" "$path"
            echo "Permissions updated."
            ;;

        2)
            read -p "Enter file path: " path
            if [[ ! -e "$path" ]]; then echo "Not found."; pause; return; fi

            read -p "Enter new owner: " uname
            uname=$(echo "$uname" | tr 'A-Z' 'a-z')

            if ! id "$uname" &>/dev/null; then echo "User not found."; pause; return; fi

            chown "$uname" "$path"
            echo "Owner updated."
            ;;

        3)
            echo "Cancelled."
            ;;

        *)
            echo "Invalid option."
            ;;
    esac

    pause
}

# ------------------------------------------------------------
# SET DEFAULT SHELL
# ------------------------------------------------------------
set_default_shell() {
    read -p "Enter default shell (e.g., /bin/bash): " dshell

    if [[ ! -x "$dshell" ]]; then
        echo "Invalid shell."
        pause
        return
    fi

    echo "$dshell" > default_shell.conf
    echo "Default shell saved."
    pause
}

# ------------------------------------------------------------
# MAIN MENU LOOP
# ------------------------------------------------------------
while true; do
    clear
    echo
    echo "   USER ACCOUNT MANAGEMENT"
    echo
    echo "1) Add user"
    echo "2) Delete user"
    echo "3) Modify user"
    echo "4) List users"
    echo "5) Group management"
    echo "6) Permission management"
    echo "7) Set default shell"
    echo "8) Exit"
    echo

    read -p "Choose an option: " option

    case $option in
        1) add_user ;;
        2) delete_user ;;
        3) modify_user ;;
        4) list_users ;;
        5) group_management ;;
        6) permission_management ;;
        7) set_default_shell ;;
        8) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option."; pause ;;
    esac
done
