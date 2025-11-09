from people import Account, Student, Teacher, timmy, james
from datetime import datetime

"""
meetings = [
    {"day":"Mon","start":"10:30","end":"11:30","title":"Test review","with":"Ms. Rivera","status":"Confirmed"},
    {"day":"Tue","start":"14:15","end":"14:30","title":"Project help","with":"Mr. Lee","status":"Pending"},
    {"day":"Wed","start":"09:00","end":"10:00","title":"Counselor check-in","with":"Dr. Adams","status":"Confirmed"},
]
"""


class Meeting:
    def __init__(self, 
        date: datetime, 
        time: tuple[int, int], 
        subject: str, 
        title: str, 
        sender: object,
        reciever: object=None, 
        status: bool=False
    ):
        """Initializes a meeting 

        Args: 
            date: A tuple in (year, month, day)
                Example: 
                    (2025, 11, 2) #help on the 2nd of November, 2025
            time: A tuple in (start, end) where time is minutes elapsed since midnight.
                Example: 
                    (450, 495) #help from 7:30 through 8:15
            subject: The course which the meeting would be about
            title: The title of the meeting
            sender: The creator of the meeting (child of Account class)
            reciever (optional): The recipient of the meeting
            status (optional): False is "Pending" and True is "Confirmed". Default is False
        """
        

        # if date > datetime.datetime.now(): print("boo")
        
        self.date = date
        self.time = time
        self.subject = subject
        self.title = title
        self.sender = sender
        self.reciever = reciever
        self.status = status

        if reciever != None:
            reciever.requests.append(self)
    

    def cancel(self):
        """Deletes the meeting from both the sender and recipient's ends"""
        self.sender.meetings.remove(self)

        if self.status: self.reciever.meetings.remove(self)
        else: self.reciever.requests.remove(self)

        del self


date: (2025)
time: tuple[int, int]
subject: str
title: str
sender: object
reciever: object=None
status: bool=False
timmy.create_meeting()
# timmy creates a meeting for calculus help with james
# james then accepts the meeting
