Driver Manager (PowerShell)

This repository contains a simple PowerShell-based Driver Manager with a user interface and an admin panel.

Files:
- driver-manager.ps1 : Main UI for scanning devices and launching driver installs
- admin-panel.ps1   : Password-protected admin CRUD for drivers-db.json (default password: pluisje)
- drivers-db.json   : Sample driver database

Usage (run as Administrator):

1) To run the user UI:
   irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/driver-manager.ps1 | iex

2) To open the admin panel (edit DB):
   irm https://raw.githubusercontent.com/pluizigegamer/drivers/main/admin-panel.ps1 | iex

Notes:
- Command-type driver entries are executed by writing the command text to a temporary .ps1 and running PowerShell with Bypass execution policy to avoid environment expansion errors.
- The database is stored at $env:APPDATA\DriverManager\drivers-db.json

If anything fails when running via irm|iex, download the file first and run locally to debug. "
}]}}]}
