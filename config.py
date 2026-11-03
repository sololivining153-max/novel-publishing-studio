from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str = "sqlite:///./novel_forge_dev.db"
    openai_api_key: str | None = None
    openai_model: str = "gpt-4.1-mini"
    openai_base_url: str = "https://api.openai.com/v1"
    max_outline_tokens: int = 5000
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
