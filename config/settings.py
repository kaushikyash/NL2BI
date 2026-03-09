from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000

    GOOGLE_API_KEY: str = ""

    LLM_MODEL: str = "gemini-2.5-flash"
    LLM_BASE_URL: str = ""

    CHROMA_PATH: str = "data/chroma_schema"
    EMBEDDING_MODEL: str = "text-embedding-3-small"

    DB_HOST: str = Field(default="localhost", validation_alias=AliasChoices("DB_HOST", "CLICKHOUSE_HOST"))
    DB_PORT: int = Field(default=8123, validation_alias=AliasChoices("DB_PORT", "CLICKHOUSE_PORT"))
    DB_NAME: str = Field(default="manufacturing_simple", validation_alias=AliasChoices("DB_NAME", "CLICKHOUSE_DB"))
    DB_USER: str = Field(default="default", validation_alias=AliasChoices("DB_USER", "CLICKHOUSE_USER"))
    DB_PASSWORD: str = Field(default="default", validation_alias=AliasChoices("DB_PASSWORD", "CLICKHOUSE_PASSWORD"))

    TOP_K: int = 5
    SIMILARITY_THRESHOLD: float = 0.7

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def CLICKHOUSE_HOST(self) -> str:
        return self.DB_HOST

    @property
    def CLICKHOUSE_PORT(self) -> int:
        return self.DB_PORT

    @property
    def CLICKHOUSE_DB(self) -> str:
        return self.DB_NAME

    @property
    def CLICKHOUSE_USER(self) -> str:
        return self.DB_USER

    @property
    def CLICKHOUSE_PASSWORD(self) -> str:
        return self.DB_PASSWORD


settings = Settings()
