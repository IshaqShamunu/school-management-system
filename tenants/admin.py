from django.contrib import admin

from .models import School


@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "license_type", "status", "subscription_renews_on")
    list_filter = ("license_type", "status")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}

