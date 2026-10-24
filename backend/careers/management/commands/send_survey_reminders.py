import datetime
from django.core.management.base import BaseCommand
from django.utils import timezone
from alumni.models import AlumniProfile
from careers.tracer_models import TracerSurvey
from communications.models import InAppNotification

class Command(BaseCommand):
    help = "Dispatches tracer survey reminders to verified alumni who haven't responded or whose survey is over a year old."

    def add_arguments(self, parser):
        parser.add_argument(
            '--days-old',
            type=int,
            default=365,
            help='Re-prompt alumni whose last survey submission is older than this number of days (default: 365).'
        )

    def handle(self, *args, **options):
        days_old = options['days_old']
        cutoff_date = timezone.now() - datetime.timedelta(days=days_old)

        # 1. Verified alumni who have never completed a survey
        unsubmitted_alumni = AlumniProfile.objects.filter(
            user__is_verified=True,
            tracer_survey__isnull=True
        ).select_related('user')

        # 2. Alumni whose survey was submitted before cutoff_date
        stale_alumni = AlumniProfile.objects.filter(
            user__is_verified=True,
            tracer_survey__isnull=False,
            tracer_survey__updated_at__lt=cutoff_date
        ).select_related('user')

        target_alumni = list(unsubmitted_alumni) + list(stale_alumni)
        # Deduplicate
        seen_ids = set()
        unique_alumni = []
        for a in target_alumni:
            if a.id not in seen_ids:
                seen_ids.add(a.id)
                unique_alumni.append(a)

        notifications_to_create = []
        for alumnus in unique_alumni:
            notifications_to_create.append(
                InAppNotification(
                    user=alumnus.user,
                    title="MSU DCS Tracer Survey Reminder",
                    message="Please take 3 minutes to update your employment status and career history to help improve the DCS curriculum and support junior students.",
                    category="SYSTEM",
                    reference_id="tracer_survey",
                    action_url="/tracer-survey",
                )
            )

        if notifications_to_create:
            InAppNotification.objects.bulk_create(notifications_to_create)

        self.stdout.write(
            self.style.SUCCESS(
                f"Successfully dispatched {len(notifications_to_create)} tracer survey reminders ({len(unsubmitted_alumni)} first-time, {len(stale_alumni)} annual renewals)."
            )
        )
