from rest_framework import generics, status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.shortcuts import get_object_or_404
from .models import User
from .serializers import (
    CustomTokenObtainPairSerializer,
    RegisterAlumniSerializer,
    UserSerializer,
    VerifyAlumnusSerializer
)
from .permissions import IsAdminUserRole

class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Login endpoint: validates email & password, returns JWT tokens and user metadata.
    """
    serializer_class = CustomTokenObtainPairSerializer

class RegisterAlumniView(generics.CreateAPIView):
    """
    Alumni self-registration endpoint.
    Creates an unverified alumni user and associated alumni profile.
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

        return Response({
            'message': msg,
            'user': {
                'id': user.id,
                'email': user.email,
                'full_name': user.get_full_name(),
                'role': user.role,
                'is_verified': user.is_verified,
            }
        }, status=status.HTTP_201_CREATED)

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
