#!/bin/bash
set -e
echo "Building Step 1 project files..."
cat > '.env.example' << 'PYEOF_STEP1'
# Copy this file to .env and fill in real values. Never commit the real .env.

DJANGO_SECRET_KEY=change-me-to-a-long-random-string
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# Leave DB_ENGINE unset (or anything other than "postgres") to use SQLite
# for local development. Set it to "postgres" once you're ready to point
# at a real PostgreSQL database.
DB_ENGINE=
DB_NAME=sms_db
DB_USER=sms_user
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=5432

PYEOF_STEP1
cat > '.gitignore' << 'PYEOF_STEP1'
__pycache__/
*.pyc
db.sqlite3
.env
venv/
*.egg-info/

PYEOF_STEP1
cat > 'README.md' << 'PYEOF_STEP1'
# SMS Backend — Step 1: Project Skeleton + Multi-Tenant Foundation

This is the first piece of the School Management System backend, built
with Django per the project report's confirmed tech stack.

## What's in this step

- **`tenants` app** — the `School` model. Every school on the platform is
  a row here (a "tenant"). It also stores each school's licensing plan
  (purchase vs. subscription) and their own configurable grading /
  tie-break rules, since the report confirmed those are set per school,
  not platform-wide.
- **`accounts` app** — a custom `User` model with a `role` field covering
  every actor in the report (Super Admin, Board, Admin, Exam Officer,
  Teacher, Form Master, Bursar, Student, Parent). Students get a unique
  `registration_number`; Parents link to their children via `wards`.
- **`academics`, `attendance`, `finance` apps** — created as empty
  placeholders, one per remaining phase of the roadmap, so we have a
  clear place to add each feature without restructuring later.
- Multi-tenant approach: **shared database, `school` foreign key** on
  tenant-scoped models (see the comment at the top of `settings.py` for
  why we chose this over a database-per-school approach).

## Running it locally

```bash
python -m venv venv
source venv/bin/activate        # on Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env            # then edit values if needed
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser   # create your first Super Admin login
python manage.py runserver
```

Then visit `http://127.0.0.1:8000/admin/` and log in — you'll be able to
create a School and a first user for it right away, using Django's
built-in admin as a placeholder UI until the real dashboards exist.

## Not built yet (coming in later steps)

- Role-based permission enforcement (who can do what) — currently the
  `role` field exists but nothing yet *restricts* actions by it.
- The academics app: classes, subjects, CA/exam entry, results/positions.
- The attendance app: daily register, manual + biometric marking.
- The finance app: fee invoices, payment gateway integration, receipts.
- A REST API (so the React web app and React Native mobile app can
  actually talk to this backend) — right now this is admin-only.

PYEOF_STEP1
mkdir -p 'academics'
cat > 'academics/__init__.py' << 'PYEOF_STEP1'

PYEOF_STEP1
mkdir -p 'academics'
cat > 'academics/admin.py' << 'PYEOF_STEP1'
from django.contrib import admin

# Registered here once models are added in a later step.

PYEOF_STEP1
mkdir -p 'academics'
cat > 'academics/apps.py' << 'PYEOF_STEP1'
from django.apps import AppConfig


class AcademicsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "academics"

PYEOF_STEP1
mkdir -p 'academics'
cat > 'academics/models.py' << 'PYEOF_STEP1'
from django.db import models

# Models for this app are built in a later step — see the project
# roadmap (Phase 2: Academics, Phase 3: Attendance, Phase 4: Finance).

PYEOF_STEP1
mkdir -p 'accounts'
cat > 'accounts/__init__.py' << 'PYEOF_STEP1'

PYEOF_STEP1
mkdir -p 'accounts'
cat > 'accounts/admin.py' << 'PYEOF_STEP1'
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

PYEOF_STEP1
mkdir -p 'accounts'
cat > 'accounts/apps.py' << 'PYEOF_STEP1'
from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "accounts"

PYEOF_STEP1
mkdir -p 'accounts'
cat > 'accounts/models.py' << 'PYEOF_STEP1'
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Every person who logs into the platform is a User with a `role`.
    This single model backs every dashboard in the project report —
    which dashboard a person sees, and what they're allowed to touch,
    is driven entirely by `role` (checked in permissions, not by having
    separate login systems per role).

    Design notes:
    - `school` is null for SUPER_ADMIN only (they sit above all schools).
      Every other role must belong to exactly one school.
    - `registration_number` is unique platform-wide and only used by
      students (Section 6.6: "unique, never repeated, even after a
      student leaves the school").
    - Parents are linked to their ward(s) via `wards`, a self-referential
      many-to-many, so one parent can be linked to multiple children and
      (in principle) a student could have more than one guardian account.
    """

    class Role(models.TextChoices):
        SUPER_ADMIN = "super_admin", "Super Admin (Platform Owner)"
        BOARD = "board", "School Board"
        ADMIN = "admin", "Headmaster / Principal / Vice Principal"
        EXAM_OFFICER = "exam_officer", "Exam Officer"
        TEACHER = "teacher", "Classroom / Subject Teacher"
        FORM_MASTER = "form_master", "Form Master"
        BURSAR = "bursar", "Bursar"
        STUDENT = "student", "Student"
        PARENT = "parent", "Parent / Guardian"

    role = models.CharField(max_length=20, choices=Role.choices)

    school = models.ForeignKey(
        "tenants.School",
        on_delete=models.CASCADE,
        related_name="users",
        null=True,
        blank=True,
        help_text="Null only for SUPER_ADMIN, who is not scoped to one school.",
    )

    phone_number = models.CharField(max_length=30, blank=True)

    # --- Student-specific ---
    registration_number = models.CharField(
        max_length=30, unique=True, null=True, blank=True,
        help_text="Students only. Unique platform-wide, never reused.",
    )

    # --- Parent-specific ---
    # A parent's `wards` are the Student users they can view. A student's
    # reverse accessor (`guardians`) lists everyone who can see their data.
    wards = models.ManyToManyField(
        "self",
        symmetrical=False,
        blank=True,
        related_name="guardians",
        limit_choices_to={"role": Role.STUDENT},
        help_text="Parent role only: the student(s) this account can view.",
    )

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_role_display()})"

    # --- Small convenience helpers used throughout the app later ---
    @property
    def is_form_master(self):
        return self.role == self.Role.FORM_MASTER

    @property
    def is_teaching_staff(self):
        return self.role in (self.Role.TEACHER, self.Role.FORM_MASTER)

PYEOF_STEP1
mkdir -p 'attendance'
cat > 'attendance/__init__.py' << 'PYEOF_STEP1'

PYEOF_STEP1
mkdir -p 'attendance'
cat > 'attendance/admin.py' << 'PYEOF_STEP1'
from django.contrib import admin

# Registered here once models are added in a later step.

PYEOF_STEP1
mkdir -p 'attendance'
cat > 'attendance/apps.py' << 'PYEOF_STEP1'
from django.apps import AppConfig


class AttendanceConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "attendance"

PYEOF_STEP1
mkdir -p 'attendance'
cat > 'attendance/models.py' << 'PYEOF_STEP1'
from django.db import models

# Models for this app are built in a later step — see the project
# roadmap (Phase 2: Academics, Phase 3: Attendance, Phase 4: Finance).

PYEOF_STEP1
mkdir -p 'finance'
cat > 'finance/__init__.py' << 'PYEOF_STEP1'

PYEOF_STEP1
mkdir -p 'finance'
cat > 'finance/admin.py' << 'PYEOF_STEP1'
from django.contrib import admin

# Registered here once models are added in a later step.

PYEOF_STEP1
mkdir -p 'finance'
cat > 'finance/apps.py' << 'PYEOF_STEP1'
from django.apps import AppConfig


class FinanceConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "finance"

PYEOF_STEP1
mkdir -p 'finance'
cat > 'finance/models.py' << 'PYEOF_STEP1'
from django.db import models

# Models for this app are built in a later step — see the project
# roadmap (Phase 2: Academics, Phase 3: Attendance, Phase 4: Finance).

PYEOF_STEP1
cat > 'manage.py' << 'PYEOF_STEP1'
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def main():
    """Run administrative tasks."""
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sms_backend.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()

PYEOF_STEP1
cat > 'requirements.txt' << 'PYEOF_STEP1'
Django>=5.0,<6.0
psycopg2-binary>=2.9   # PostgreSQL driver, used once DB_ENGINE=postgres
python-dotenv>=1.0     # loads .env file values into environment variables

PYEOF_STEP1
mkdir -p 'sms_backend'
cat > 'sms_backend/__init__.py' << 'PYEOF_STEP1'

PYEOF_STEP1
mkdir -p 'sms_backend'
cat > 'sms_backend/settings.py' << 'PYEOF_STEP1'
"""
Django settings for sms_backend project.

Multi-tenancy approach (see project report, Section 8.1):
We use a SHARED DATABASE with a `school` foreign key on tenant-scoped
models (the "shared schema, tenant column" pattern) rather than one
database/schema per school. This is simpler to build, deploy, and back up
for a solo/small team, and is easy to migrate to schema-per-tenant later
if a school ever needs stronger physical data isolation.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep this secret in production (use an environment
# variable, never commit the real value to source control).
SECRET_KEY = os.environ.get(
    "DJANGO_SECRET_KEY", "dev-only-insecure-key-change-before-deploying"
)

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get("DJANGO_DEBUG", "True") == "True"

ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")


INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Our apps — one per area of the project report.
    "tenants",       # School (tenant) model + Super Admin licensing
    "accounts",      # Custom User model + roles (RBAC)
    "academics",     # Classes, subjects, CA/exam marks, results, curriculum
    "attendance",    # Daily attendance register
    "finance",       # Fee invoices, payments, receipts
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "sms_backend.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "sms_backend.wsgi.application"

# ---------------------------------------------------------------------
# Database
# Defaults to SQLite for easy local development. Set these environment
# variables to point at PostgreSQL for staging/production, per the
# project report's recommended stack.
# ---------------------------------------------------------------------
if os.environ.get("DB_ENGINE") == "postgres":
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.environ.get("DB_NAME", "sms_db"),
            "USER": os.environ.get("DB_USER", "sms_user"),
            "PASSWORD": os.environ.get("DB_PASSWORD", ""),
            "HOST": os.environ.get("DB_HOST", "localhost"),
            "PORT": os.environ.get("DB_PORT", "5432"),
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

# Point Django's auth system at our custom User model (accounts.User)
# instead of the default — required because we add `role` and `school`
# fields that don't exist on the built-in User.
AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Africa/Lagos"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

PYEOF_STEP1
mkdir -p 'sms_backend'
cat > 'sms_backend/urls.py' << 'PYEOF_STEP1'
from django.contrib import admin
from django.urls import path

urlpatterns = [
    # Django's built-in admin — doubles as a quick internal tool for the
    # Super Admin / school admins until the real dashboards are built.
    path("admin/", admin.site.urls),
]

PYEOF_STEP1
mkdir -p 'sms_backend'
cat > 'sms_backend/wsgi.py' << 'PYEOF_STEP1'
import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sms_backend.settings")

application = get_wsgi_application()

PYEOF_STEP1
mkdir -p 'tenants'
cat > 'tenants/__init__.py' << 'PYEOF_STEP1'

PYEOF_STEP1
mkdir -p 'tenants'
cat > 'tenants/admin.py' << 'PYEOF_STEP1'
from django.contrib import admin

from .models import School


@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "license_type", "status", "subscription_renews_on")
    list_filter = ("license_type", "status")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}

PYEOF_STEP1
mkdir -p 'tenants'
cat > 'tenants/apps.py' << 'PYEOF_STEP1'
from django.apps import AppConfig


class TenantsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "tenants"

PYEOF_STEP1
mkdir -p 'tenants'
cat > 'tenants/models.py' << 'PYEOF_STEP1'
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

PYEOF_STEP1
echo "Done. Files created."
