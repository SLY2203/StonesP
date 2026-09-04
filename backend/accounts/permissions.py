from rest_framework.permissions import BasePermission
from .models import User

class IsAdminUserRole(BasePermission):
    """
    Allows access only to authenticated users with the ADMIN role or superusers.
    """
    message = "Administrator privileges required to perform this action."

    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role == User.UserRole.ADMIN or request.user.is_staff or request.user.is_superuser)
        )

class IsAlumnusRole(BasePermission):
    """
    Allows access to users with the ALUMNI role.
    """
    message = "Alumni privileges required to perform this action."

    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.role == User.UserRole.ALUMNI
        )

class IsVerifiedAlumnus(BasePermission):
    """
    Allows access to verified alumni or admin staff.
    Unverified alumni are restricted from active participation until approved.
    """
    message = "Your alumni account is currently pending verification by DCS Department Staff."

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        if request.user.role == User.UserRole.ADMIN or request.user.is_superuser:
            return True
        return request.user.is_verified
