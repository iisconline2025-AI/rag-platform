"""Pydantic schemas for webhook endpoints (M4)."""
from pydantic import BaseModel, EmailStr, Field


class SlackOnboardRequest(BaseModel):
    email: EmailStr = Field(examples=["alice@example.com"])


class SlackOnboardResponse(BaseModel):
    slack_user_id: str = Field(examples=["U0123456789"])
    email: str = Field(examples=["alice@example.com"])


class TeamsOnboardRequest(BaseModel):
    email: EmailStr = Field(examples=["alice@example.com"])
    # AAD object id captured from the user's first Teams message (from.aadObjectId).
    teams_user_id: str = Field(examples=["29:1AbCdEf..."])


class TeamsOnboardResponse(BaseModel):
    teams_user_id: str = Field(examples=["29:1AbCdEf..."])
    email: str = Field(examples=["alice@example.com"])
