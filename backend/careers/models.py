from django.db import models
from alumni.models import AlumniProfile
from .tracer_models import TracerSurvey

class CareerRecord(models.Model):
    class EmploymentStatus(models.TextChoices):
        EMPLOYED = 'EMPLOYED', 'Employed (Full-time / Part-time)'
        SELF_EMPLOYED = 'SELF_EMPLOYED', 'Self-Employed / Founder'
        FURTHER_STUDIES = 'FURTHER_STUDIES', 'Pursuing Further Studies'
        UNEMPLOYED = 'UNEMPLOYED', 'Seeking Employment'

    INDUSTRY_CHOICES = [
        ('Software & IT Services', 'Software & IT Services'),
        ('FinTech & Banking', 'FinTech & Banking'),
        ('Telecommunications', 'Telecommunications'),
        ('E-Commerce & Retail', 'E-Commerce & Retail'),
        ('Education & Research', 'Education & Research'),
        ('Mining & Energy', 'Mining & Energy'),
        ('Public Sector & Gov', 'Public Sector & Gov'),
        ('HealthTech & Medical', 'HealthTech & Medical'),
        ('Media & Creative', 'Media & Creative'),
        ('Other Industry', 'Other Industry'),
    ]

    alumnus = models.ForeignKey(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='career_records'
    )
    job_title = models.CharField(max_length=150, help_text="e.g. Senior Software Engineer, IT Specialist")
    employer = models.CharField(max_length=150, help_text="Company or organization name")
    employment_status = models.CharField(
        max_length=25,
        choices=EmploymentStatus.choices,
        default=EmploymentStatus.EMPLOYED
    )
    industry_sector = models.CharField(
        max_length=100,
        choices=INDUSTRY_CHOICES,
        default='Software & IT Services'
    )
    start_date = models.DateField(help_text="Position start date")
    end_date = models.DateField(blank=True, null=True, help_text="Leave blank if currently holding this role")
    is_current = models.BooleanField(default=True, help_text="Is this the alumnus' current primary role?")
    
    # Further studies fields
    further_education_institution = models.CharField(
        max_length=150,
        blank=True,
        null=True,
        help_text="e.g. Midlands State University, UZ, etc."
    )
    further_education_programme = models.CharField(
        max_length=150,
        blank=True,
        null=True,
        help_text="e.g. MSc Data Science & Analytics"
    )
    description = models.TextField(blank=True, null=True, help_text="Brief summary of duties and achievements")
    skills_used = models.CharField(
        max_length=500,
        blank=True,
        default='',
        help_text="Key technologies and skills utilized in this role (e.g. Django, Flutter, Docker, AWS)"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_current', '-start_date']
        indexes = [
            models.Index(fields=['employment_status']),
            models.Index(fields=['industry_sector']),
            models.Index(fields=['is_current']),
        ]

    def save(self, *args, **kwargs):
        # If this position is marked as current, ensure previous positions for this alumnus are un-marked
        if self.is_current:
            CareerRecord.objects.filter(alumnus=self.alumnus, is_current=True).exclude(pk=self.pk).update(is_current=False)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.job_title} at {self.employer} ({self.alumnus.user.get_full_name()})"
