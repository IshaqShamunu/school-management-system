from django.contrib import admin
from django.urls import path

urlpatterns = [
    # Django's built-in admin — doubles as a quick internal tool for the
    # Super Admin / school admins until the real dashboards are built.
    path("admin/", admin.site.urls),
]

