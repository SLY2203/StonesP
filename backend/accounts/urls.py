from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    CustomTokenObtainPairView,
    RegisterAlumniView,
    CurrentUserView,
    VerifyAlumniView,
    LookupGraduateView,
)

urlpatterns = [
    path('login/', CustomTokenObtainPairView.as_view(), name='auth_login'),
    path('register/', RegisterAlumniView.as_view(), name='auth_register'),
    path('lookup-graduate/', LookupGraduateView.as_view(), name='lookup_graduate'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('me/', CurrentUserView.as_view(), name='current_user'),
    path('alumni/<int:user_id>/verify/', VerifyAlumniView.as_view(), name='verify_alumni'),
]
