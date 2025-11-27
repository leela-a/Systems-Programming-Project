# SOFE 3200 – System Programming  
## Final Project: User Account Management Script   
**CRN44209 - Group 4**   
*Abdul Aziz Syed - 100792709*   
*Leela Alagala - 100913874*   
*Hannah Albi - 100821689*   

This project contains a Bash script that works as a simple user-management tool in the Linux operating system (OS).  
The requirement/goal was to build a script/system that feels easy to use, while also still completing the main tasks a system administrator needs to do.  
This script follows the requirements given in the project outline and rubric, and everything was written in a way that it has ease-of-access and is efficient and stable.

---

## Project Description

The idea behind this project is simple: to create a script that helps a person/system manage user accounts without having to type long commands every time.  
Instead of remembering several Linux utilities/instructions, you can just run 1 script and pick what you want from a user-given menu.

The script lets you add users, remove them, change their personal information, and even list the current perople on the system.  
Each option will explain to the user what it needs, check for mistakes, and try to prevent accidental changes or errors.  
Security and clean error handling were also important parts of the project, so the script makes sure to not store sensitive information and also gives a notification when something is wrong.

---

## Script Overview

The main script, *`user_mgmt.sh`*, is based on a menu, so when you run it, you’ll see a list of options.  
You pick what you want to do, and the script takes care of the rest.

### Available Options

**1. Add User**  
- Asks for a username, full name, and password  
- Creates the account using `useradd`  
- Sets the password through `passwd`  
- Checks if the user already exists

**2. Delete User**  
- Prompts for the username  
- Removes the account using `userdel`  
- Confirms the user is real before deleting anything

**3. Modify User**  
- Lets you update things like the password, default shell, or full name  
- Uses commands such as `passwd` and `chfn`  
- Makes sure the account exists before trying to change it

**4. List Users**  
- Shows the entries in `/etc/passwd`  
- Gives a quick view of all user accounts

**5. Exit**  
- Closes the script safely

### Error Handling

The script checks for missing inputs, invalid usernames, permission problems, and failed system commands.  
If something goes wrong, the script prints a clear message so it’s easy to tell what happened.

### Security Notes

- Passwords are always handled through Linux’s built-in tools  
- No passwords are stored in the script  
- Most actions require `sudo`, so the script will warn you if you’re not running it with the right permissions

### Room for Expansion

The script can be extended later with things like group management, permission changes, or log files.  
Its structure makes it easy to add new options without rewriting the whole program.

---

## Languages and Tools Used

- **Bash** — main scripting language  
- **Linux user-management commands**:  
  - `useradd`, `userdel`, `usermod`  
  - `passwd`, `chfn`  
  - `cat`, `grep`, `cut`  
- **System Requirements**:  
  - Any Linux distribution  
  - `sudo` or root access  
  - Bash shell (version 4+ recommended)

---
