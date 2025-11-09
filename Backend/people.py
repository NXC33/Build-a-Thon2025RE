from meet import Meeting
from datetime import datetime

class Account:
    def __init__(self, name: str, proficiency: dict[str, tuple[str, ...]]): 
        """Initializes an account

        Args:
            name: Full display name
            proficiency: Maps subject -> tuple of strong courses' labels.
                Keys should be case-sensitive string related to subjects.
                Values should be tuples (with at least 1 item) of strings consisting of course labels the account has proficiency with.
                Example: 
                    {
                        "Math": ("Pre-Calculus", "Calculus 1"), 
                        "Science": ("Chemistry", "AP Physics C"), 
                        "History": ("United States History")
                    }
                
        Raises: 
            ValueError: If 'name' is empty
        """

        if name == "": raise ValueError("Instance variable 'name' cannot be empty")

        self.name = name
        self.proficiency = proficiency
        self.meetings = [] #fill with Meetings this Account creates/accepts
        self.requests = [] #fill with Meetings people send to this Account
    
    
    def create_meeting(self, 
        date: datetime, 
        time: tuple[int, int], 
        subject: str, 
        title: str, 
        sender: object,
        reciever: object=None, 
        status: bool=False
    ):
        new_meet = Meeting(date, time, subject, title, sender, reciever, status)
        self.meetings.append(new_meet)
    
    
    def accept_meeting(self, meeting: Meeting):
        meeting.status = True
        self.meetings.append(meeting)
        self.requests.remove(meeting)




class Student(Account):
    def __init__(self, name: str, courses: list, proficiency: dict[str, tuple[str, ...]], grade: str):
        """Initializes Student class, inherited from Account
        
        Args: 
            courses: All classes the Student is taking
            grade: Grade level e.g, "Freshman", "Sophomore", "Junior", "Senior" 

        """

        super().__init__(name, proficiency)
        self.courses = courses
        self.grade = grade




class Teacher(Account): 
    def __init__(self, name: str, proficiency: dict[str, tuple[str, ...]], title: str):
        """Initializes Teacher class, inherited from Account
        
        Args: 
            title: Title/role e.g, "Mr.", "Mrs.", "Dr."

        """
        
        super().__init__(name, proficiency)
        self.title = title




timmy = Student("Timmy Theodore", {"Math": ("Pre-calc")}, "Freshman")
james = Teacher("James Smith", {"Math": ("Pre-calc", "calc1", "calc2", "multivariable")}, "Mr.")

#!!!!!!!!!!!!!!!!!!!test!!!!!!!!!!!!!!!!!!!!!!
a = datetime.datetime.now()

print(a)

# print(timmy.grade, timmy.name)
# print(james.title, james.name)