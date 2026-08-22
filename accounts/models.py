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

