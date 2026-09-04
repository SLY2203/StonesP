"""
Django project initialization for MSU DCS Alumni Tracking System.
Integrates PyMySQL as MySQLdb driver.
"""
try:
    import pymysql
    pymysql.install_as_MySQLdb()
except ImportError:
    pass
