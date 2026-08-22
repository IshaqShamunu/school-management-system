from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = (
        "username", "get_full_name", "role", "school",
        "registration_number", "is_active",
    )
    list_filter = ("role", "school", "is_active")
    search_fields = ("username", "first_name", "last_name", "registration_number", "email")

    fieldsets = DjangoUserAdmin.fieldsets + (
        ("School Management System", {
            "fields": ("role", "school", "phone_number", "registration_number", "wards"),
        }),
    )

