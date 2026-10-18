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


class DepartmentFeedback(models.Model):
    FEEDBACK_CATEGORIES = [
        ('CURRICULUM', 'Curriculum & Courses Feedback'),
        ('CAREER_SERVICES', 'Career Services & Industry Linkages'),
        ('FACILITIES', 'Department Facilities & Resources'),
        ('ALUMNI_EVENTS', 'Alumni Events & Engagement'),
        ('GENERAL', 'General Suggestion / Feedback'),
    ]

    alumnus = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='department_feedbacks'
    )
    subject = models.CharField(max_length=200)
    category = models.CharField(
        max_length=50,
        choices=FEEDBACK_CATEGORIES,
        default='GENERAL'
    )
    message = models.TextField()
    is_reviewed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.category}] {self.subject} by {self.alumnus.user.get_full_name()}"


class SystemFeedbackSurvey(models.Model):
    SYSTEM_ASPECTS = [
        ('GENERAL', 'General System Performance'),
        ('CAREER_TRACKING', 'Career Progression & Milestones'),
        ('DIRECTORY', 'Alumni Directory & Search'),
        ('VERIFICATION', 'Verification & Registration Flow'),
        ('JOBS_EVENTS', 'Jobs, Broadcasts & RSVPs'),
        ('MENTORSHIP', 'Mentorship Program'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='system_surveys'
    )
    overall_rating = models.PositiveSmallIntegerField(
        help_text="Overall system satisfaction from 1 (Poor) to 5 (Excellent)"
    )
    ease_of_use_rating = models.PositiveSmallIntegerField(
        default=5,
        help_text="Ease of navigation and UI from 1 to 5"
    )
    features_rating = models.PositiveSmallIntegerField(
        default=5,
        help_text="Satisfaction with features from 1 to 5"
    )
    performance_rating = models.PositiveSmallIntegerField(
        default=5,
        help_text="Speed and responsiveness from 1 to 5"
    )
    system_aspect = models.CharField(
        max_length=50,
        choices=SYSTEM_ASPECTS,
        default='GENERAL'
    )
    what_works_well = models.TextField(
        blank=True,
        null=True,
        help_text="What works well in the system?"
    )
    improvements_needed = models.TextField(
        blank=True,
        null=True,
        help_text="What friction or improvements are needed?"
    )
    would_recommend = models.BooleanField(
        default=True,
        help_text="Would you recommend the portal?"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"System Survey: {self.user.get_full_name()} - {self.overall_rating}★"
