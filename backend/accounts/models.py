from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    class UserRole(models.TextChoices):
        ADMIN = 'ADMIN', 'Administrator (Department Staff)'
        ALUMNI = 'ALUMNI', 'Alumni'

    email = models.EmailField(unique=True, verbose_name='Email Address')
    role = models.CharField(
        max_length=10,
        choices=UserRole.choices,
        default=UserRole.ALUMNI,
        help_text='Role in the system (Staff Admin or Alumni)'
    )
    is_verified = models.BooleanField(
        default=False,
        help_text='Alumni accounts require admin verification before full access.'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name']

    def save(self, *args, **kwargs):
        # Admins and superusers are automatically marked as verified
        if self.role == self.UserRole.ADMIN or self.is_superuser:
            self.is_verified = True
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.role}) - {self.email}"
