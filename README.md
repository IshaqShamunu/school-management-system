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

