from django.db import models
from alumni.models import AlumniProfile


class TracerSurvey(models.Model):
    """
    Objective 2: Formal tracer survey capturing post-graduation employment
    outcomes, time-to-first-job, salary band, degree relevance, and satisfaction.
    Each alumnus completes this once (can be updated).
    """

    SALARY_BAND_CHOICES = [
        ('UNPAID', 'Unpaid / Volunteer'),
        ('BELOW_500', 'Below $500 / month'),
        ('500_1000', '$500 – $1,000 / month'),
        ('1000_2000', '$1,000 – $2,000 / month'),
        ('2000_5000', '$2,000 – $5,000 / month'),
        ('ABOVE_5000', 'Above $5,000 / month'),
        ('PREFER_NOT', 'Prefer not to say'),
    ]

    RELEVANCE_CHOICES = [
        ('HIGHLY_RELEVANT', 'Highly Relevant – directly related to my DCS degree'),
        ('SOMEWHAT_RELEVANT', 'Somewhat Relevant – partially related'),
        ('NOT_RELEVANT', 'Not Relevant – unrelated to my degree'),
        ('NOT_APPLICABLE', 'Not Applicable – not yet employed'),
    ]

    SATISFACTION_CHOICES = [
        (5, 'Very Satisfied'),
        (4, 'Satisfied'),
        (3, 'Neutral'),
        (2, 'Dissatisfied'),
        (1, 'Very Dissatisfied'),
    ]

    JOB_SEARCH_METHOD_CHOICES = [
        ('ONLINE_PORTAL', 'Online Job Portal (e.g. LinkedIn, Indeed)'),
        ('REFERRAL', 'Referral / Networking'),
        ('CAMPUS_RECRUITMENT', 'Campus Recruitment / Career Fair'),
        ('DIRECT_APPLICATION', 'Direct Application to Employer'),
        ('STARTED_OWN', 'Started Own Business / Freelancing'),
        ('FURTHER_STUDIES', 'Went for Further Studies'),
        ('OTHER', 'Other'),
    ]

    alumnus = models.OneToOneField(
        AlumniProfile,
        on_delete=models.CASCADE,
        related_name='tracer_survey'
    )

    # Time to first job
    months_to_first_job = models.PositiveIntegerField(
        blank=True,
        null=True,
        help_text="Number of months between graduation and first employment"
    )
    had_job_before_graduation = models.BooleanField(
        default=False,
        help_text="Was the alumnus already employed before completing their degree?"
    )

    # First job details
    first_job_title = models.CharField(max_length=150, blank=True, default='')
    first_employer = models.CharField(max_length=150, blank=True, default='')
    first_job_sector = models.CharField(
        max_length=100,
        blank=True,
        default='',
        help_text="Industry sector of first job"
    )

    # Salary band (current)
    current_salary_band = models.CharField(
        max_length=30,
        choices=SALARY_BAND_CHOICES,
        default='PREFER_NOT'
    )

    # Degree relevance
    degree_relevance = models.CharField(
        max_length=30,
        choices=RELEVANCE_CHOICES,
        default='NOT_APPLICABLE'
    )

    # Satisfaction metrics
    career_satisfaction = models.PositiveSmallIntegerField(
        choices=SATISFACTION_CHOICES,
        default=3,
        help_text="Satisfaction with current career trajectory (1-5)"
    )
    curriculum_satisfaction = models.PositiveSmallIntegerField(
        choices=SATISFACTION_CHOICES,
        default=3,
        help_text="How well did the DCS curriculum prepare you? (1-5)"
    )

    # Job search method
    job_search_method = models.CharField(
        max_length=30,
        choices=JOB_SEARCH_METHOD_CHOICES,
        default='OTHER'
    )

    # Skills gap
    skills_gap = models.TextField(
        blank=True,
        default='',
        help_text="What skills or courses do you wish the curriculum had included?"
    )

    # Additional comments
    additional_comments = models.TextField(
        blank=True,
        default='',
        help_text="Any additional feedback on your post-graduation experience"
    )

    is_complete = models.BooleanField(
        default=False,
        help_text="Has the alumnus completed the full survey?"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['degree_relevance']),
            models.Index(fields=['current_salary_band']),
            models.Index(fields=['is_complete']),
        ]

    def __str__(self):
        return f"Tracer Survey: {self.alumnus.user.get_full_name()} - {'Complete' if self.is_complete else 'Incomplete'}"

    def auto_calculate_months_to_first_job(self) -> None:
        """
        Recommendation: Auto-calculate months_to_first_job from the alumnus's
        graduation_year and their earliest CareerRecord start_date.
        Only fills in the value if not already manually set.
        """
        if self.months_to_first_job is not None:
            return  # Already set manually — don't override

        grad_year = self.alumnus.graduation_year
        from careers.models import CareerRecord
        earliest_career = (
            CareerRecord.objects.filter(alumnus=self.alumnus, start_date__isnull=False)
            .order_by('start_date')
            .first()
        )
        if earliest_career and earliest_career.start_date:
            import datetime
            # Approximate graduation as July 1st of the graduation year
            grad_date = datetime.date(grad_year, 7, 1)
            delta_months = (
                (earliest_career.start_date.year - grad_date.year) * 12
                + (earliest_career.start_date.month - grad_date.month)
            )
            if delta_months >= 0:
                self.months_to_first_job = delta_months
                self.save(update_fields=['months_to_first_job'])

