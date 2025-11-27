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
    useradd -m -c "$fullname" "$username"
    if [[ $? -ne 0 ]]; then
        echo "Failed to create user."
        pause
        return
    fi


    # Secure password prompt and Simple password length check loop
	while true; do
    	  read -s -p "Enter password: " password
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
	     	   read -s -p "New password (8–12 chars, or 'q' to cancel): " pass1
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
}


# List Users

list_users() {
    echo "                              "
    echo "---- List of System Users ----"
    echo "                              "
    cat /etc/passwd
    pause
}


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
    echo "5) Exit"
    echo "                              "

    read -p "Choose an option: " option

    case $option in
        1) add_user ;;
        2) delete_user ;;
        3) modify_user ;;
        4) list_users ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option"; pause ;;
    esac
done

