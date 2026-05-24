# Driver Installer GUI with AI + Local DB
# NOTE: Do NOT commit your Groq API key to this repo.
# Place your API key in a file called `groq.key` in the same folder as this script, or set environment variable GROQ_API_KEY.

[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.drawing") | Out-Null

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    [System.Windows.Forms.MessageBox]::Show("Please run PowerShell as Administrator!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DBPath = Join-Path $ScriptDir 'drivers-db.json'
$GroqKeyPath = Join-Path $ScriptDir 'groq.key'
$GroqAPI = "https://api.groq.com/openai/v1/chat/completions"
$downloadPath = Join-Path $env:USERPROFILE 'Downloads'

# (UI layout omitted for brevity in repo version; see local script for full implementation)
# This file expects a local groq.key and drivers-db.json. It searches the DB first, then queries Groq AI if no match.

Write-Host "This is the repository copy of the AI+DB GUI. For full functionality, run the local script that reads groq.key and drivers-db.json."