"""
ntfy.sh notification utility.

Sends notifications for long-running pipeline operations.
"""

import logging
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

NTFY_TOPIC = settings.ntfy_topic
NTFY_URL = f"https://ntfy.sh/{NTFY_TOPIC}"


async def notify(
    message: str,
    title: str = "Kinetic Forge Studio",
    priority: str = "default",
    tags: list[str] | None = None,
) -> bool:
    """
    Send a notification via ntfy.sh.

    Args:
        message: Notification body.
        title: Notification title.
        priority: "urgent", "high", "default", "low", "min".
        tags: Emoji tags (e.g., ["white_check_mark"], ["x"]).

    Returns:
        True if sent successfully, False otherwise.
    """
    headers = {
        "Title": title,
        "Priority": priority,
    }
    if tags:
        headers["Tags"] = ",".join(tags)

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(NTFY_URL, content=message, headers=headers)
            if response.status_code == 200:
                logger.info("ntfy.sh notification sent: %s", message[:50])
                return True
            else:
                logger.warning(
                    "ntfy.sh returned %d: %s",
                    response.status_code, response.text[:100],
                )
                return False
    except Exception as e:
        logger.warning("ntfy.sh notification failed: %s", e)
        return False
