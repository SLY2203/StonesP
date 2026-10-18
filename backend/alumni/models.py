from django.db import models
from django.conf import settings

class AlumniProfile(models.Model):
    PROGRAMME_CHOICES = [
        ('BSc Hons Computer Science', 'BSc Hons Computer Science'),
        ('BSc Hons Information Systems', 'BSc Hons Information Systems'),
        ('BSc Hons Information Technology', 'BSc Hons Information Technology'),
        ('BSc Hons Software Engineering', 'BSc Hons Software Engineering'),
        ('BSc Hons Cybersecurity & Digital Forensics', 'BSc Hons Cybersecurity & Digital Forensics'),
        ('MSc Information Technology', 'MSc Information Technology'),
        ('MPhil / PhD Computer Science', 'MPhil / PhD Computer Science'),
        ('Other DCS Programme', 'Other DCS Programme'),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='alumni_profile'
    )
    registration_number = models.CharField(
        max_length=30,
        unique=True,
        help_text="MSU student registration number (e.g. R201456B)"
    )
    graduation_year = models.PositiveIntegerField(
        help_text="Year of graduation from MSU DCS"
    )
    programme = models.CharField(
        max_length=120,
        choices=PROGRAMME_CHOICES,
        default='BSc Hons Computer Science'
    )
    phone_number = models.CharField(max_length=25, blank=True, null=True)
    address = models.CharField(max_length=255, blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    linkedin_url = models.URLField(blank=True, null=True)
    github_url = models.URLField(blank=True, null=True)
    profile_photo = models.ImageField(upload_to='alumni_photos/', blank=True, null=True)

    # Suggestion 1: Technical skills & competencies
    skills = models.CharField(
        max_length=500,
        blank=True,
        default='',
        help_text="Comma-separated technical skills (e.g. Python, Flutter, PostgreSQL, AWS, Docker)"
    )

    # Suggestion 3: Mentorship & peer networking
    is_available_for_mentorship = models.BooleanField(
        default=False,
        help_text="Willing to mentor current DCS students and junior alumni"
    )
    mentorship_areas = models.CharField(
        max_length=350,
        blank=True,
        default='',
        help_text="Mentorship areas (e.g. Career Advice, CV Review, Software Engineering, Postgraduate Research)"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-graduation_year', 'user__last_name']
        indexes = [
            models.Index(fields=['registration_number']),
            models.Index(fields=['graduation_year']),
            models.Index(fields=['programme']),
            models.Index(fields=['is_available_for_mentorship']),
        ]

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.registration_number}) - Class of {self.graduation_year}"

    @property
    def skills_list(self):
        if not self.skills:
            return []
        return [s.strip() for s in self.skills.split(',') if s.strip()]


class GraduationRoster(models.Model):
    """
    Suggestion 2: Official DCS graduation records uploaded by department staff.
    Allows automated verification of alumni registrations when student registration number matches.
    """
    registration_number = models.CharField(
        max_length=30,
        unique=True,
        help_text="Official MSU DCS registration number (e.g. R175420X)"
    )
    full_name = models.CharField(
        max_length=150,
        help_text="Official graduate full name as documented on the graduation roster"
    )
    graduation_year = models.PositiveIntegerField(
        help_text="Graduation ceremony year"
    )
    programme = models.CharField(
        max_length=120,
        choices=AlumniProfile.PROGRAMME_CHOICES,
        default='BSc Hons Computer Science'
    )
    degree_class = models.CharField(
        max_length=50,
        blank=True,
        default='Pass',
        help_text="Degree classification (e.g. First Class, 2.1, 2.2, Pass)"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-graduation_year', 'registration_number']
        indexes = [
            models.Index(fields=['registration_number']),
            models.Index(fields=['graduation_year']),
        ]

    def __str__(self):
        return f"{self.registration_number} - {self.full_name} ({self.graduation_year})"


class MentorshipRequest(models.Model):
    """
    Suggestion 3: Peer-to-peer and senior-to-junior mentorship connections.
    """
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        ACCEPTED = 'ACCEPTED', 'Accepted'
        DECLINED = 'DECLINED', 'Declined'
        COMPLETED = 'COMPLETED', 'Completed'

    mentor = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='received_mentorship_requests'
    )
    mentee = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='sent_mentorship_requests'
    )
    topic = models.CharField(
        max_length=150,
        help_text="e.g. Career Transition, Mock Technical Interview, CV / Portfolio Review"
    )
    message = models.TextField(
        help_text="Introduction and background on what guidance is sought"
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    response_message = models.TextField(
        blank=True,
        null=True,
        help_text="Mentor's response or contact instructions"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Mentorship: {self.mentee.user.get_full_name()} -> {self.mentor.user.get_full_name()} [{self.status}]"

