AutoMeet is a lightweight scheduling tool that automatically connects students and teachers based on availability, subject needs, and proficiency. 
It simplifies booking academic support by avoiding email coordination and calendar conflicts.

Built for the 2025 Build-A-Thon.

Overview
Students specify when they are free, what help they need, and which subjects they are taking.
Teachers list their available hours and subjects they can support.
MeetMatch identifies compatible time windows and enables users to request and confirm meetings.
All data is stored locally using JSON.

Features
Student and teacher profiles
Subject and proficiency tracking
Calendar-based availability editor (click-and-drag)
Automatic matching for meeting requests
Meeting calendar display
Account editing
Help ticket form

Running the Project: 
Clone the repository
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python test.py
Open in browser:
http://localhost:8080


Future Work:
Email notifications
Google Calendar integration
School-wide account directory

Authors:
Nicolas Castillo — Frontend & Backend integration
Cohen McDaniel — Backend
