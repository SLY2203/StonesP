from django.db import models
from django.conf import settings
from alumni.models import AlumniProfile

class Communication(models.Model):
    class Category(models.TextChoices):
        ANNOUNCEMENT = 'ANNOUNCEMENT', 'Department Announcement'
        EVENT = 'EVENT', 'Alumni Event & Reunion'
        MENTORSHIP = 'MENTORSHIP', 'Mentorship Program'
        JOB_VACANCY = 'JOB_VACANCY', 'Career / Job Opportunity'

    title = models.CharField(max_length=220)
    content = models.TextField()
    category = models.CharField(
        max_length=30,
        choices=Category.choices,
        default=Category.ANNOUNCEMENT
    )
    target_graduation_year = models.PositiveIntegerField(
        blank=True,
        null=True,
        help_text="Optional cohort filter (null = all alumni cohorts)"
    )
    target_programme = models.CharField(
        max_length=150,
        blank=True,
        null=True,
        help_text="Optional programme filter (null = all programmes)"
    )
    
    # Event and Job specific fields
    event_date = models.DateTimeField(blank=True, null=True)
    location = models.CharField(max_length=220, blank=True, null=True, help_text="Physical venue or virtual meeting link")
    application_deadline = models.DateTimeField(blank=True, null=True)
    external_link = models.URLField(blank=True, null=True, help_text="Link to apply or register online")

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='posted_communications'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"[{self.category}] {self.title}"

class RSVP(models.Model):
    class ResponseType(models.TextChoices):
        ATTENDING = 'ATTENDING', 'Attending'
        INTERESTED = 'INTERESTED', 'Interested'
        APPLIED = 'APPLIED', 'Applied'

    communication = models.ForeignKey(
        Communication,
        on_delete=models.CASCADE,
        related_name='rsvps'
    )
    alumnus = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='rsvps'
    )
    response_type = models.CharField(
        max_length=20,
        choices=ResponseType.choices,
        default=ResponseType.INTERESTED
    )
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('communication', 'alumnus')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.alumnus.user.get_full_name()} -> {self.communication.title} ({self.response_type})"
