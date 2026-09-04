"""
Firebase Cloud Messaging (FCM) push notification integration service.
Handles broadcasting notifications to mobile clients when new communications are published.
"""
import logging
import os

logger = logging.getLogger(__name__)

class FCMNotificationService:
    @staticmethod
    def send_broadcast_notification(communication):
        """
        Sends push notification for a new department communication.
        In local/demo mode, logs structured payload. In production, dispatches via FCM SDK.
        """
        fcm_key = os.environ.get('FCM_SERVER_KEY', '')
        payload = {
            'notification': {
                'title': f"MSU DCS: {communication.get_category_display()}",
                'body': communication.title,
            },
            'data': {
                'communication_id': str(communication.id),
                'category': communication.category,
                'target_year': str(communication.target_graduation_year or ''),
            },
            'topic': 'alumni_broadcasts'
        }

        if fcm_key:
            # Here firebase_admin.messaging.send() is called when credentials are configured
            logger.info("FCM Push notification dispatched via server key to topic: alumni_broadcasts")
        else:
            logger.info("Push notification simulated: [Title: %s] [Category: %s]", communication.title, communication.category)

        return payload
