from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.shortcuts import get_object_or_404
from django.utils.decorators import method_decorator
try:
    from ratelimit.decorators import ratelimit
    RATELIMIT_AVAILABLE = True
except ImportError:
    RATELIMIT_AVAILABLE = False
    def ratelimit(*args, **kwargs):
        """No-op decorator if django-ratelimit is not installed."""
        def decorator(func):
            return func
        return decorator
from .models import User
from .serializers import (
    CustomTokenObtainPairSerializer,
    RegisterAlumniSerializer,
    UserSerializer,
    VerifyAlumnusSerializer
)
from .permissions import IsAdminUserRole

@method_decorator(
    ratelimit(key='ip', rate='5/m', method='POST', block=True),
    name='post'
)
class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Login endpoint: validates email & password, returns JWT tokens and user metadata.
    Rate limited to 5 attempts/minute per IP to prevent brute-force attacks.
    """
    serializer_class = CustomTokenObtainPairSerializer


@method_decorator(
    ratelimit(key='ip', rate='3/m', method='POST', block=True),
    name='post'
)
class RegisterAlumniView(generics.CreateAPIView):
    """
    Alumni self-registration endpoint.
    Creates an unverified alumni user and associated alumni profile.
    Rate limited to 3 attempts/minute per IP to prevent spam registrations.
    """
    serializer_class = RegisterAlumniSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        if user.is_verified:
            msg = 'Registration successful! Your registration number was verified against the official MSU DCS Graduation Roster, and your account has been automatically activated.'
        else:
            msg = 'Registration successful. Your account is pending verification by DCS Department Staff.'

        # Collect roster cross-validation warnings
        warnings = []
        if getattr(user, 'roster_year_mismatch', False):
            warnings.append('The graduation year you entered does not match the official roster record. This will be flagged for staff review.')
        if getattr(user, 'roster_name_mismatch', False):
            warnings.append('The name you entered does not closely match the official roster record. Staff may request clarification.')

        response_data = {
            'message': msg,
            'user': {
                'id': user.id,
                'email': user.email,
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'full_name': user.get_full_name(),
                'role': user.role,
                'is_verified': user.is_verified,
            }
        }
        if warnings:
            response_data['warnings'] = warnings

        return Response(response_data, status=status.HTTP_201_CREATED)

class CurrentUserView(generics.RetrieveUpdateAPIView):
    """
    Retrieve or update the authenticated user's account information.
    """
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

class VerifyAlumniView(APIView):
    """
    Admin-only endpoint to verify/approve or reject/unverify an alumnus account.
    """
    permission_classes = [IsAdminUserRole]

    def post(self, request, user_id):
        serializer = VerifyAlumnusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = get_object_or_404(User, id=user_id, role=User.UserRole.ALUMNI)
        new_status = serializer.validated_data['is_verified']
        user.is_verified = new_status
        user.save()

        action = "verified & activated" if new_status else "unverified"
        return Response({
            'message': f"Alumnus {user.get_full_name()} has been successfully {action}.",
            'user_id': user.id,
            'is_verified': user.is_verified
        }, status=status.HTTP_200_OK)


class LookupGraduateView(APIView):
    """
    Public lookup endpoint for Alumni Self-Registration:
    Queries the official GraduationRoster using the student registration number.
    Returns verified graduate information (name, graduation year, programme, degree class)
    so the mobile app can auto-fill details and claim verified profiles seamlessly.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        import re
        from alumni.models import GraduationRoster, AlumniProfile

        raw_reg = request.query_params.get('reg_number') or request.query_params.get('registration_number') or ''
        reg = raw_reg.strip().upper()
        if not reg:
            return Response(
                {'error': 'Registration number parameter (reg_number) is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not re.match(r'^R\d{4,6}[A-Z]$', reg):
            return Response(
                {
                    'error': 'Invalid MSU registration number format. Expected pattern: R followed by 4-6 digits and a letter (e.g. R201456B).'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if already registered
        if AlumniProfile.objects.filter(registration_number__iexact=reg).exists():
            return Response(
                {
                    'status': 'ALREADY_REGISTERED',
                    'message': f"An account is already registered with student number {reg}. Please log in or reset your password."
                },
                status=status.HTTP_409_CONFLICT
            )

        roster_entry = GraduationRoster.objects.filter(registration_number__iexact=reg).first()
        if not roster_entry:
            return Response(
                {
                    'status': 'NOT_FOUND',
                    'message': f"Registration number '{reg}' was not found in the official MSU DCS Graduation Database. Only verified graduates of the department can register."
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Split full name into first and last name
        names = roster_entry.full_name.strip().split()
        first_name = names[0] if names else ''
        last_name = ' '.join(names[1:]) if len(names) > 1 else ''

        return Response({
            'status': 'VERIFIED',
            'registration_number': roster_entry.registration_number,
            'full_name': roster_entry.full_name,
            'first_name': first_name,
            'last_name': last_name,
            'graduation_year': roster_entry.graduation_year,
            'programme': roster_entry.programme,
            'degree_class': roster_entry.degree_class,
            'message': f"Official graduate record confirmed for {roster_entry.full_name} ({roster_entry.programme}, Class of {roster_entry.graduation_year})."
        }, status=status.HTTP_200_OK)
