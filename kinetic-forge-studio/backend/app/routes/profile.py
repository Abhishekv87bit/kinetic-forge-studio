"""
User profile route -- single-user app profile management.

Profile stored as JSON file in the data directory.
Loaded into every Claude API call context.
"""

from fastapi import APIRouter
from app.models.profile import UserProfile
from app.config import settings

router = APIRouter(prefix="/api/profile", tags=["profile"])


def _get_profile() -> UserProfile:
    return UserProfile(settings.data_dir)


@router.get("")
async def get_profile():
    """Get the current user profile."""
    profile = _get_profile()
    return profile.load()


@router.put("")
async def update_profile(updates: dict):
    """Update user profile with deep merge."""
    profile = _get_profile()
    profile.update(updates)
    return profile.load()
