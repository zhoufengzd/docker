#!/usr/bin/env python

import airflow
from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser
import os
import sys

if __name__ == '__main__':
    admin = os.environ.get('AIRFLOW__ADMIN')
    if not admin:
        admin = 'admin'
    admin_pwd = os.environ.get('AIRFLOW__ADMIN_PASSWORD')
    if not admin_pwd:
        sys.exit('Warning: admin password was not set.')

    user = PasswordUser(models.User())
    user.username = admin
    user.email = ''
    user.password = admin_pwd

    session = settings.Session()
    session.add(user)
    session.commit()
    session.close()
    exit()
