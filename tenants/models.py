from django.db import models


class School(models.Model):
    """
    A tenant on the platform. Every school-specific record elsewhere in
    the system (users, classes, results, payments, ...) links back to a
    School, so one school's data is never mixed with another's.

    Created and managed by the Super Admin (see LicensePlan below), per
    the confirmed multi-tenant / licensing model in the project report.
    """

    class LicenseType(models.TextChoices):
        PURCHASE = "purchase", "One-time purchase"
        SUBSCRIPTION = "subscription", "Recurring subscription"

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        TRIAL = "trial", "Trial"

    name = models.CharField(max_length=255)
    # Short unique code used in URLs / mobile app tenant selection,
    # e.g. "greenfield-college" -> greenfield-college.oursystem.com
    slug = models.SlugField(max_length=100, unique=True)

    address = models.CharField(max_length=255, blank=True)
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=30, blank=True)

    # --- Licensing (Section 8.1 of the project report) ---
    license_type = models.CharField(
        max_length=20, choices=LicenseType.choices, default=LicenseType.SUBSCRIPTION
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.TRIAL)
    subscription_renews_on = models.DateField(null=True, blank=True)

    # --- Per-school academic configuration ---
    # Each school's Exam Officer sets their own grading weights and
    # tie-break rule (Section 6.5.1 / Section 11 decisions), so we store
    # that configuration here rather than hard-coding it anywhere.
    class TieBreakRule(models.TextChoices):
        SHARED_DENSE = "shared_dense", "Shared / dense ranking"
        SUBJECT = "subject", "Tie-break by a specific subject"
        AVERAGE = "average", "Tie-break by average score"

    tie_break_rule = models.CharField(
        max_length=20, choices=TieBreakRule.choices, default=TieBreakRule.SHARED_DENSE
    )
    tie_break_subject = models.CharField(
        max_length=100,
        blank=True,
        help_text="Only used when tie_break_rule = 'subject', e.g. 'Mathematics'.",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name

