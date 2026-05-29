"""Application configuration — reads from .env file."""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # App
    APP_ENV: str = "development"
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000"]

    # Mock mode
    MOCK_N8N: bool = True

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://raguser:changeme@localhost:5432/ragplatform"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # n8n
    N8N_BASE_URL: str = "http://localhost:5678"
    N8N_INGEST_WEBHOOK_URL: str = "http://localhost:5678/webhook/ingest"
    N8N_RETRIEVE_WEBHOOK_URL: str = "http://localhost:5678/webhook/retrieve"

    # OpenAI
    OPENAI_API_KEY: str = ""
    OPENAI_EMBEDDING_MODEL: str = "text-embedding-3-small"
    OPENAI_CHAT_MODEL: str = "gpt-4o-mini"

    # Twilio
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_WHATSAPP_NUMBER: str = "whatsapp:+14155238886"

    # Slack
    SLACK_BOT_TOKEN: str = ""
    SLACK_SIGNING_SECRET: str = ""

    # File upload
    UPLOAD_DIR: str = "/uploads"
    MAX_FILE_SIZE_MB: int = 50

    # Seed
    SEED_ADMIN_EMAIL: str = "admin@example.com"
    SEED_ADMIN_PASSWORD: str = "changeme"
    SEED_TENANT_NAME: str = "IISc Demo"
    SEED_TENANT_SLUG: str = "iisc-demo"

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
