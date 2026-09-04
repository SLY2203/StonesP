from django.urls import path
from .views import MyProfileView, AlumniDirectoryView, AlumniDetailAdminView

urlpatterns = [
    path('profile/me/', MyProfileView.as_view(), name='my_profile'),
    path('directory/', AlumniDirectoryView.as_view(), name='alumni_directory'),
    path('directory/<int:id>/', AlumniDetailAdminView.as_view(), name='alumni_detail'),
]
