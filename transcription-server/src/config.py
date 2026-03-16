from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    openai_api_key: str

    model_config = {"env_file": ".env", "extra": "ignore"}


def get_settings() -> Settings:
    return Settings()
