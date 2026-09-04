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
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-graduation_year', 'user__last_name']
        indexes = [
            models.Index(fields=['registration_number']),
            models.Index(fields=['graduation_year']),
            models.Index(fields=['programme']),
        ]

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.registration_number}) - Class of {self.graduation_year}"
