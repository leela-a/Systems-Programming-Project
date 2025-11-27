#!/bin/bash

# ============================================================
#   USER ACCOUNT MANAGEMENT SCRIPT
#   Description:
#       A menu-driven Bash script to manage Linux user accounts.
#       Supports adding, deleting, modifying, listing users, 
#       with secure password handling and robust error checking.
# =========================================================

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use: sudo ./user_mgmt.sh"
    exit 1
fi

# ---- Helper: pause ----
pause() {
    read -p "Press Enter to continue..."
}


# Add User

add_user() {
    echo "                              "
    echo "---- Add New User ----"
    echo "                              "
    read -p "Enter username (or 'q' to cancel): " username

    if [[ "$username" == "q" ]]; then
	    echo "Cancelled."
	    pause
	    return
    fi	    

    # Change username to lowercase
    username=$(echo "$username" | tr 'A-Z' 'a-z')

    # Validate
    if id "$username" &>/dev/null; then
        echo "Error: User '$username' already exists."
        pause
        return
    fi

    read -p "Enter full name: " fullname

    # Create user
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


    # Secure password prompt and Simple password length check loop
	while true; do
    	  read -s -p "Enter password (8 to 12 characters): " password
    	    echo
    	  read -s -p "Confirm password: " password2
    	    echo

    	if [[ "$password" != "$password2" ]]; then
           echo "Passwords do not match. Try again."
          continue
    	fi

    	if (( ${#password} < 8 || ${#password2} > 12 )); then
           echo "Password must be 8–12 characters long."
           continue
    	fi

    # Try to set password (we don't care if Linux flags it)
	echo "$username:$password" | chpasswd

	echo "Password set successfully."

        break
    done

    echo "User '$username' created successfully."
    pause
	log_action "Created user $username"
}



# Delete User

delete_user() {
    echo "                              "
    echo "---- Delete User ----"
    echo "                              "
    read -p "Enter username to delete (or 'q' to cancel): " username

    if [[ "$username" == "q" ]]; then
            echo "Cancelled."
            pause
            return
    fi


    username=$(echo "$username" | tr 'A-Z' 'a-z')

    if ! id "$username" &>/dev/null; then
        echo "User '$username' does not exist."
        pause
        return
    fi

    read -p "Are you sure you want to delete $username? (y/n): " confirm

    if [[ $confirm == "y" ]]; then
        userdel -r "$username"
        echo "✅ User '$username' deleted successfully."
    else
        echo "Cancelled."
    fi
    pause
	log_action "Deleted user $username"
}


# Modify User

modify_user() {
    echo "                              "
    echo "---- Modify User ----"
    echo "                              "
    read -p "Enter username to modify (or 'q' to cancel): " username

    if [[ "$username" == "q" ]]; then
            echo "Cancelled."
            pause
            return
    fi

    username=$(echo "$username" | tr 'A-Z' 'a-z')

    if ! id "$username" &>/dev/null; then
	echo "User '$username' does not exist."
        pause
        return
    fi

    echo "Select modification:"
    echo "1) Change password"
    echo "2) Change full name"
    echo "3) Change shell"
    echo "4) Cancel"
    read -p "Enter option: " choice

    case $choice in
        1)
	  # Requires old passwoed first
    	  while true; do
        	read -s -p "Enter current password (or 'q' to cancel): " oldpass
        	echo
        
        	if [[ "$oldpass" == "q" ]]; then
            	    echo "Cancelled."
            	    pause
        	    return
        	fi

          # Verify old password using su
        	if echo "$oldpass" | su -c "exit" "$username" &>/dev/null; then
       	 	    echo "Old password verified."
        	    break
        	else
        	    echo "Incorrect old password. Try again."
        	fi
    		done

      	  # Set new password
    	  	while true; do
	     	   read -s -p "New password (8–12 characters, or 'q' to cancel): " pass1
	     	   echo
	      	   read -s -p "Confirm new password: " pass2
	     	   echo

          # If either = q then cancel
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
	            echo "Password must be 8–12 characters long."
	            continue
        	fi

        	    echo "$username:$pass1" | chpasswd
	            echo "Password updated."
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
        ;;
        3)
            read -p "Enter new shell (e.g., /bin/bash): " shell

	    if [[ "$shell" == "q" ]]; then
                echo "Cancelled."
                pause
                return
            fi

            chsh -s "$shell" "$username"
            echo "Shell updated."
 	;;
	4)
	    echo "Cancelled."
    	    pause
	    return
        ;;
        *)
            echo "Invalid choice."
        ;;
    esac
    pause
	log_action "Modified user $username ($choice)"
}


# List Users

list_users() {
    echo "                              "
    echo "---- List of System Users ----"
    echo "                              "
    cat /etc/passwd
    pause
}

group_management() {
    echo " "
    echo "---- Group Management ----"
    echo " "
    echo "1) Create new group"
    echo "2) Add user to group"
    echo "3) List all groups"
    echo "4) Cancel"
    read -p "Choose an option: " gopt

    case $gopt in
        1)
            read -p "Enter group name (or 'q' to cancel): " gname
            [[ "$gname" == "q" ]] && echo "Cancelled." && pause && return

            if getent group "$gname" >/dev/null; then
                echo "Group '$gname' already exists."
            else
                if groupadd "$gname"; then
                    echo "Group '$gname' created."
                else
                    echo "Failed to create group '$gname'."
                fi
            fi
            ;;

        2)
            read -p "Enter username: " uname
            uname=$(echo "$uname" | tr 'A-Z' 'a-z')
            read -p "Enter group name: " gname

            if ! id "$uname" &>/dev/null; then
                echo "User '$uname' does not exist."
            elif ! getent group "$gname" >/dev/null; then
                echo "Group '$gname' does not exist."
            else
                if usermod -aG "$gname" "$uname"; then
                    echo "Added '$uname' to group '$gname'."
                else
                    echo "Failed to add '$uname' to '$gname'."
                fi
            fi
            ;;

        3)
            echo "---- Groups on System ----"
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

permission_management() {
    echo " "
    echo "---- Permission Management ----"
    echo " "
    echo "1) Change file permissions (chmod)"
    echo "2) Change file owner (chown)"
    echo "3) Cancel"
    read -p "Choose an option: " popt

    case $popt in
        1)
            read -p "Enter file path: " path

            if [[ ! -e "$path" ]]; then
                echo "File '$path' does not exist."
                pause
                return
            fi

            read -p "Enter permission (e.g., 755): " perms

            if [[ ! "$perms" =~ ^[0-7]{3,4}$ ]]; then
                echo "Invalid permission format. Use numeric modes like 644, 755, 0700."
                pause
                return
            fi

            if chmod "$perms" "$path"; then
                echo "Permissions updated successfully."
            else
                echo "Failed to update permissions."
            fi
            ;;

        2)
            read -p "Enter file path: " path

            if [[ ! -e "$path" ]]; then
                echo "File '$path' does not exist."
                pause
                return
            fi

            read -p "Enter new owner username: " uname
            uname=$(echo "$uname" | tr 'A-Z' 'a-z')

            if ! id "$uname" &>/dev/null; then
                echo "User '$uname' does not exist."
                pause
                return
            fi

            if chown "$uname" "$path"; then
                echo "Owner updated successfully."
            else
                echo "Failed to update owner."
            fi
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

set_default_shell() {
 read -p "Enter default shell (e.g., /bin/bash): " dshell
 echo "$dshell" > default_shell.conf
 echo "Default shell saved."
 pause
 }

log_action() { echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> /var/log/user_mgmt.log }

# Main Menu

while true; do
    clear
    echo "                              "
    echo "   USER ACCOUNT MANAGEMENT    "
    echo "                              "
    echo "1) Add user"
    echo "2) Delete user"
    echo "3) Modify user"
    echo "4) List users"
	echo "5) Group management"
	echo "6) Permission management"
	echo "7) Set default shell"
    echo "8) Exit"
    echo "                              "

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
        *) echo "Invalid option"; pause ;;
    esac
done

