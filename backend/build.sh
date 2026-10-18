#!/usr/bin/env bash
# Exit on error
set -o errexit

# Install python dependencies
pip install -r requirements.txt

# Collect static files for WhiteNoise
python manage.py collectstatic --no-input

# Run database migrations
python manage.py migrate

# Seed database with initial accounts, roles and demo records (if empty)
python manage.py shell -c "from accounts.models import User; import subprocess, sys; subprocess.run([sys.executable, 'seed_data.py'], check=True) if not User.objects.filter(email='admin@dcs.msu.ac.zw').exists() else print('Admin user already exists, skipping initial seed.')"

