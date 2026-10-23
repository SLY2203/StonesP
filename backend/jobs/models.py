from django.db import models
from django.conf import settings
from alumni.models import AlumniProfile


class JobVacancy(models.Model):
    """
    Objective 3: Structured job vacancy with AI-extracted fields.
    Admin pastes raw advert text, the AI service extracts structured details,
    and the system matches alumni based on skills, experience, and industry.
    """

    EXPERIENCE_LEVEL_CHOICES = [
        ('ENTRY', 'Entry Level (0-2 years)'),
        ('MID', 'Mid Level (2-5 years)'),
        ('SENIOR', 'Senior Level (5+ years)'),
        ('LEAD', 'Lead / Principal'),
        ('ANY', 'Any Experience Level'),
    ]

    JOB_TYPE_CHOICES = [
        ('FULL_TIME', 'Full-Time'),
        ('PART_TIME', 'Part-Time'),
        ('CONTRACT', 'Contract'),
        ('INTERNSHIP', 'Internship'),
        ('REMOTE', 'Remote / Freelance'),
    ]

    STATUS_CHOICES = [
        ('DRAFT', 'Draft (AI Extracted, Pending Review)'),
        ('PUBLISHED', 'Published'),
        ('CLOSED', 'Closed'),
    ]

    # Core fields
    title = models.CharField(max_length=250, help_text="Job title")
    company = models.CharField(max_length=200, help_text="Hiring company or organization")
    description = models.TextField(help_text="Full job description")
    location = models.CharField(max_length=200, blank=True, default='')
    salary_range = models.CharField(max_length=100, blank=True, default='', help_text="e.g. $1,000 - $2,000/month")

    # AI-extracted structured fields
    required_skills = models.TextField(
        blank=True,
        default='',
        help_text="Comma-separated skills extracted by AI (e.g. Python, Django, Flutter)"
    )
    experience_level = models.CharField(
        max_length=10,
        choices=EXPERIENCE_LEVEL_CHOICES,
        default='ANY'
    )
    job_type = models.CharField(
        max_length=15,
        choices=JOB_TYPE_CHOICES,
        default='FULL_TIME'
    )
    industry_sector = models.CharField(
        max_length=100,
        blank=True,
        default='Software & IT Services'
    )
    qualifications = models.TextField(
        blank=True,
        default='',
        help_text="Required qualifications extracted by AI"
    )
    responsibilities = models.TextField(
        blank=True,
        default='',
        help_text="Key responsibilities extracted by AI"
    )

    # Original raw text
    raw_advert_text = models.TextField(
        blank=True,
        default='',
        help_text="Original unstructured job advert text pasted by admin"
    )

    # Metadata
    status = models.CharField(
        max_length=15,
        choices=STATUS_CHOICES,
        default='DRAFT'
    )
    application_url = models.URLField(blank=True, null=True)
    application_deadline = models.DateTimeField(blank=True, null=True)
    posted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='posted_jobs'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Job Vacancies'
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['experience_level']),
            models.Index(fields=['industry_sector']),
        ]

    def __str__(self):
        return f"{self.title} at {self.company} [{self.status}]"

    @property
    def required_skills_list(self):
        if not self.required_skills:
            return []
        return [s.strip() for s in self.required_skills.split(',') if s.strip()]


class JobMatch(models.Model):
    """
    Records AI-generated matches between a job vacancy and alumni profiles.
    Stores the match score and which factors contributed to the match.
    """

    job = models.ForeignKey(
        JobVacancy,
        on_delete=models.CASCADE,
        related_name='matches'
    )
    alumnus = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='job_matches'
    )
    match_score = models.FloatField(
        default=0.0,
        help_text="Overall match score (0.0 to 100.0)"
    )
    skills_overlap = models.TextField(
        blank=True,
        default='',
        help_text="Comma-separated overlapping skills"
    )
    match_reasons = models.TextField(
        blank=True,
        default='',
        help_text="Explanation of why this alumnus was matched"
    )
    is_notified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('job', 'alumnus')
        ordering = ['-match_score']
        indexes = [
            models.Index(fields=['match_score']),
        ]

    def __str__(self):
        return f"Match: {self.alumnus.user.get_full_name()} → {self.job.title} ({self.match_score}%)"


class JobApplication(models.Model):
    """
    Tracks when an alumnus expresses interest in or applies to a matched vacancy.
    """
    class Status(models.TextChoices):
        INTERESTED = 'INTERESTED', 'Interested'
        APPLIED = 'APPLIED', 'Applied'
        SHORTLISTED = 'SHORTLISTED', 'Shortlisted'
        REJECTED = 'REJECTED', 'Not Selected'

    job = models.ForeignKey(
        JobVacancy,
        on_delete=models.CASCADE,
        related_name='applications'
    )
    alumnus = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='job_applications'
    )
    status = models.CharField(
        max_length=15,
        choices=Status.choices,
        default=Status.INTERESTED
    )
    cover_note = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('job', 'alumnus')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.alumnus.user.get_full_name()} → {self.job.title} [{self.status}]"
