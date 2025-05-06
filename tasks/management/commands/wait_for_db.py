# wait_for_db.py
import time
import os
import psycopg2
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    def handle(self, *args, **options):
        self.stdout.write('Waiting for database...')
        db_up = False
        while not db_up:
            try:
                conn = psycopg2.connect(
                    dbname=os.getenv('DB_NAME'),
                    user=os.getenv('DB_USER'),
                    password=os.getenv('DB_PASSWORD'),
                    host=os.getenv('DB_HOST')
                )
                conn.close()
                db_up = True
            except psycopg2.OperationalError:
                self.stdout.write('Database unavailable, waiting 1 second...')
                time.sleep(1)
        
        self.stdout.write(self.style.SUCCESS('Database available!'))